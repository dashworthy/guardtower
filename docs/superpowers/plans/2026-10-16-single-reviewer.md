# Single Checklist Reviewer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace guardtower's one-subagent-per-facet fan-out with one reviewer agent that reads the change once and works every selected facet as a checklist.

**Architecture:** guardtower is a markdown skill, not code. `skills/guardtower/SKILL.md` is the orchestrator; facets are reference files under `skills/guardtower/references/facets/`. This plan adds `references/reviewer-brief.md` (merging `facet-contract.md` + `hard-stops.md`), rewrites SKILL.md steps 5–7 to dispatch one reviewer, repoints each `facet.md`, and measures recall and token cost with the existing `claude plugin eval` suite before and after.

**Tech Stack:** Markdown skill files, `claude plugin eval`, `jq`, `python3`, git.

**Spec:** `docs/superpowers/specs/2026-10-16-single-reviewer-design.md`

## Global Constraints

- Report-only: nothing in this change may let guardtower edit reviewed code.
- Exactly **one** reviewer agent per run above the inline threshold (~1 file, ≤20 changed lines, one hunk); inline below it.
- Caps (`top_n`, `floor`, `dropped`) apply **per facet**, unchanged in meaning.
- Fixed facet order: `security, tenant-isolation, data-safety, concurrency, idempotency, numeric-precision, technical, api, error-handling, framework-best-practices, frontend, test-quality, architectural, readability`.
- Per-facet Result and Finding schemas are unchanged; the report template is not touched.
- `facet.md` files and checklists change only in their pointer lines.
- Version 0.4.0 → 0.5.0, shared with test verification (do not bump again in that plan).
- All 20 existing eval cases must not regress against the 0.x baseline.

`$SCRATCH` below means the session scratchpad directory, `/private/tmp/claude-628210132/-Users-aleach-PhpstormProjects-guardtower/212fb980-f1c6-43ac-b8ad-bde7d53e7a98/scratchpad`. Set it in each shell: `SCRATCH=<that path>`.

## File map

| File | Responsibility | Task |
|---|---|---|
| `skills/guardtower/references/reviewer-brief.md` | Create: what the one reviewer is handed — request, per-facet procedure, hard stops, result + Finding schema | 2 |
| `skills/guardtower/references/facet-contract.md` | Delete (merged into brief) | 2 |
| `skills/guardtower/references/hard-stops.md` | Delete (merged into brief) | 2 |
| `skills/guardtower/references/facets/*/facet.md` (14) | Pointer line → `../../reviewer-brief.md` | 2 |
| `skills/guardtower/SKILL.md` | Description, intro, steps 4–7, todos, governing principle | 3 |
| `README.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json` | Wording + version | 4 |
| `evals/README.md` | Before/after table | 5 |

Link checker used by several tasks (run from repo root; prints `broken: 0` when clean):

```bash
python3 -I - <<'EOF'
import re,os,glob
bad=0
for f in glob.glob('skills/**/*.md',recursive=True):
    for m in re.finditer(r'\]\(([^)#\s]+\.md)\)',open(f).read()):
        t=os.path.normpath(os.path.join(os.path.dirname(f),m.group(1)))
        if not os.path.exists(t): print('BROKEN',f,m.group(1)); bad+=1
print('broken:',bad)
EOF
```

---

### Task 1: Baseline eval on 0.x

The "failing test" for this change is the measurement: record what 0.x scores and costs so Task 5 can compare.

**Files:**
- Create (scratch, not committed): `$SCRATCH/baseline-0x.json`

**Interfaces:**
- Produces: `$SCRATCH/baseline-0x.json` (full `claude plugin eval --json` output for 0.x), used in Task 5.

- [ ] **Step 1: Check out 0.x in a separate worktree**

```bash
git fetch origin 0.x
git worktree add "$SCRATCH/gt-0x" origin/0.x
```

Expected: `HEAD is now at <sha> ...`

- [ ] **Step 2: Run the suite on 0.x**

```bash
claude plugin eval "$SCRATCH/gt-0x" --scaffold --trust-plugin --ablation none -j 4 \
  --no-publish --json "$SCRATCH/baseline-0x.json"
```

Expected: 20 cases run, 3 runs each; exits 0 or 1 (1 = some case below threshold, still a valid baseline). Takes roughly 30–60 minutes.

- [ ] **Step 3: Find where tokens/cost live in the JSON**

```bash
jq '[paths(scalars) | map(tostring) | join(".") | select(test("token|cost|usage";"i"))] | unique | .[:40]' "$SCRATCH/baseline-0x.json"
```

Expected: a list of paths such as `cases.0.runs.0.usage.input_tokens` or `...cost_usd`. Write down the exact paths for per-run tokens (or cost) and per-case score; Task 5 uses them. If no token or cost field exists, note "tokens not reported" and Task 5 compares scores only.

- [ ] **Step 4: Remove the worktree**

```bash
git worktree remove --force "$SCRATCH/gt-0x" && git worktree prune
```

No commit — nothing in the repo changed.

---

### Task 2: Reviewer brief replaces facet contract and hard stops

**Files:**
- Create: `skills/guardtower/references/reviewer-brief.md`
- Delete: `skills/guardtower/references/facet-contract.md`, `skills/guardtower/references/hard-stops.md`
- Modify: all 14 `skills/guardtower/references/facets/*/facet.md` (pointer lines; `reviewing-security/facet.md:12` also)

**Interfaces:**
- Produces: `references/reviewer-brief.md` with sections `## Request`, `## Procedure`, `## The hard stops`, `## Result`, `## Finding`. Request fields: `change_ref`, `spec_ref`, `caps {top_n, floor}`, `facets [absolute paths]`. Result: `{ results: [ {facet, relevance, findings, dropped}, ... ] }`. Task 3 links to this file and these names.

- [ ] **Step 1: Write the failing check**

```bash
test -f skills/guardtower/references/reviewer-brief.md && echo OK || echo MISSING
grep -rln 'facet-contract\|hard-stops' skills/ | wc -l
```

Expected now: `MISSING` and `17` (SKILL.md, 14 facet.md, and the two files themselves).

- [ ] **Step 2: Create `skills/guardtower/references/reviewer-brief.md`**

````markdown
# The reviewer brief

What the one guardtower reviewer is handed. The orchestrator (SKILL.md) selects the facets; the
reviewer reads the change **once** and works each selected facet as one item of a checklist, in
the order given. Each facet's own file states only what is unique to it — its lens(es), the
surface that makes it relevant, its checklist(s), and which sibling facet owns an adjacent
concern. Everything below holds for every facet and is not repeated in them.

## Request — orchestrator → reviewer

```
{
  change_ref: <git ref / diff / path the review targets>,
  spec_ref:   <path to a governing spec> | none,     // an anchor for intent, if one exists
  caps: {
    top_n: <int>,                  // per facet: report at most this many, most severe first
    floor: "low" | "med" | "high"  // per facet: drop findings weaker than this bar
  },
  facets: [ <absolute path to facet.md>, ... ]      // the checklist, in order
}
```

## Procedure

1. **Read the change once.** The diff, plus — where a lens needs it — the public surface of the
   modules the change already touches. No repo-wide scan, graph, or index: a defect the change
   introduces is in reach; what the diff does not show is an accepted blind spot.
2. **Work the facets in order.** For each one:
   1. Read its `facet.md`.
   2. **Relevance gate, first.** Does the change touch this facet's surface? If not, record
      `relevance: { skipped: <one-line reason> }` and move to the next facet **without opening
      its checklist**.
   3. **Apply the lens(es).** Open the facet's checklist(s) now, not before, and work them against
      the change you already read. A facet with several lenses applies each whose surface the
      change raises; the cap spans them all.
   4. **Floor, then cap, then tally `dropped`** — for this facet alone (hard stops below).
   5. Record this facet's result, then move on. Do not carry an earlier facet's conclusions into
      a later one: judge each lens on the code.
3. **One owner per finding.** A defect goes under the facet whose lens owns it (each `facet.md`
   names its boundaries) and is not filed again under a second facet.
4. **Return** the result below. You are report-only: you never edit code and write no file.

What no facet does: fix what it finds; enumerate style nits; flag pre-existing code the change
neither introduces nor worsens.

## The hard stops

All three run inside the reviewer, per facet, before it moves on — never as trimming afterward. A
cap applied after unbounded work saves output, not tokens; a gate run first saves the work. There
is no numeric token ceiling.

1. **Relevance gate** (procedure 2.2) — the largest saver; it skips whole facets.
2. **Top-N cap.** At most `caps.top_n` findings per facet, most severe first. When more genuine
   above-floor findings exist, report how many as **`dropped`** (`0` when the cap was not hit).
   A capped list that looks complete is the cap lying; `dropped` tells the reader to re-run.
3. **Floor.** Drop any finding whose **weaker** of severity and confidence is below
   `caps.floor`. This is a drop, not a hedge: "possibly", "might be worth a look", "low
   confidence, but…" does not keep a sub-floor finding. `dropped` does not count floor drops.
   - **Speculation guard.** A finding whose realization depends on code *outside the change* — a
     hypothetical caller, an unproven path, a value some absent code might pass — is capped at
     **low confidence**, so a `med` or higher floor drops it.

**A clean result is valid.** `findings: []` is a complete answer, not a facet that gave up.
Reaching for a hedged, sub-floor finding so the list is not empty is the over-reporting the floor
exists to stop.

## Result — reviewer → orchestrator

```
{
  results: [
    {
      facet:     <facet name, e.g. reviewing-security>,
      relevance: "ran" | { skipped: <one-line reason> },
      findings:  [ Finding, ... ],   // floored and capped to <= top_n; [] is valid
      dropped:   <int>               // above-floor findings the cap held back; 0 if not hit
    },
    ...                              // one entry per requested facet, in request order
  ]
}
```

## Finding

```
{
  severity:   "high" | "med" | "low",
  confidence: "high" | "med" | "low",   // the floor tests the weaker of the two
  location:   <file:line, or a symbol name>,
  claim:      <one sentence: what is wrong>,
  why:        <one sentence: the consequence, or the rule broken>,
  evidence:   [ { at: <file:line>, code: <the cited lines, verbatim>, shows: <what they prove> }, ... ],
              // REQUIRED, at least one
  suggestion: <the direction of a fix — never applied>
}
```

`evidence` is the specific lines in this codebase that make the claim true — where untrusted
input enters and the line it reaches, the caller that retries, the column's type, the helper that
already exists. A restatement of the claim is not evidence. **No evidence, no finding.** `claim`
and `why` must read on their own for someone with no shared context. The orchestrator builds the
report's Evidence, Current code, Proposed fix and Why parts from these fields (SKILL.md step 8).
````

- [ ] **Step 3: Delete the merged files**

```bash
git rm -q skills/guardtower/references/facet-contract.md skills/guardtower/references/hard-stops.md
```

- [ ] **Step 4: Repoint every facet.md**

```bash
perl -0pi -e 's/lives in \[\.\.\/\.\.\/facet-contract\.md\]\(\.\.\/\.\.\/facet-contract\.md\); the\s+hard stops in\s+\[\.\.\/\.\.\/hard-stops\.md\]\(\.\.\/\.\.\/hard-stops\.md\)/lives in [..\/..\/reviewer-brief.md](..\/..\/reviewer-brief.md), with the hard stops/g; s/\[\.\.\/\.\.\/hard-stops\.md\]\(\.\.\/\.\.\/hard-stops\.md\)/[..\/..\/reviewer-brief.md](..\/..\/reviewer-brief.md)/g' skills/guardtower/references/facets/*/facet.md
sed -i '' 's/the four-step workflow/the per-facet procedure/' skills/guardtower/references/facets/*/facet.md
```

The second command fixes the 13 facet files that say "the four-step workflow"; the brief now calls it the per-facet procedure.

- [ ] **Step 5: Run the checks**

```bash
test -f skills/guardtower/references/reviewer-brief.md && echo OK || echo MISSING
grep -rln 'facet-contract\|hard-stops' skills/guardtower/references/
grep -c 'reviewer-brief.md' skills/guardtower/references/facets/*/facet.md
```

Expected: `OK`; the grep prints nothing; every facet.md shows `1` (the pointer, now one line) except `reviewing-security/facet.md`, which shows `2` (line 12 plus the pointer). Then run the link checker from the File map. It prints `BROKEN skills/guardtower/SKILL.md references/facet-contract.md` (and hard-stops), which is expected until Task 3, and no `BROKEN` line for any facet file.

- [ ] **Step 6: Read one result**

```bash
sed -n 24,28p skills/guardtower/references/facets/reviewing-security/facet.md
```

Expected: `... — lives in [../../reviewer-brief.md](../../reviewer-brief.md), with the hard stops.`

- [ ] **Step 7: Commit**

```bash
git add skills/guardtower/references
git commit -m "feat: reviewer brief replaces facet contract and hard stops"
```

---

### Task 3: SKILL.md dispatches one reviewer

**Files:**
- Modify: `skills/guardtower/SKILL.md` (line 3 description; lines 10–14 intro; line 34; lines 63–65; step 4 last sentence ~line 152; steps 5–7 lines 154–182; todo section lines 227–244; governing principle lines 246–250)

**Interfaces:**
- Consumes: `references/reviewer-brief.md` and its Request/Result names from Task 2.

- [ ] **Step 1: Write the failing check**

```bash
grep -c 'reviewer-brief.md' skills/guardtower/SKILL.md
grep -n -i 'fan out\|fan-out\|fanned out\|independent agent\|independent reviewer' skills/guardtower/SKILL.md
```

Expected now: `0`, and several matching lines.

- [ ] **Step 2: Description (line 3)**

Replace `fanned out as self-limiting reviewers, then reconcile their findings` with `worked as a checklist by one self-limiting reviewer, then reconcile its findings`.

- [ ] **Step 3: Intro (lines 10–12)**

Replace:

```
decides which review facets the change warrants, dispatches each selected facet as an independent
reviewer, and reconciles what they return into a single self-contained markdown report, written into
```

with:

```
decides which review facets the change warrants, has one reviewer work every selected facet as a
checklist over a single read of the change, and reconciles what it returns into a single
self-contained markdown report, written into
```

- [ ] **Step 4: Arguments link (line 34)**

Replace `[references/facet-contract.md](references/facet-contract.md)), trading breadth for signal in one` with `[references/reviewer-brief.md](references/reviewer-brief.md)), trading breadth for signal in one`.

- [ ] **Step 5: The facets intro (lines 63–65)**

Replace:

```
[references/facets/](references/facets/) (`references/facets/<facet>/facet.md`), and dispatched as
an independent reviewer — not a standalone skill. Eight **core** facets are marked **Always** in
```

with:

```
[references/facets/](references/facets/) (`references/facets/<facet>/facet.md`), and worked as one
item of the reviewer's checklist — not a standalone skill. Eight **core** facets are marked **Always** in
```

- [ ] **Step 6: Step 4's last sentence**

Replace:

```
hollow review. The orchestrator opens no facet's own doc to select; a facet's file is read only
   when it is dispatched (step 6).
```

with:

```
hollow review. The orchestrator opens no facet's own doc to select; a facet's file is read only
   when the reviewer reaches it (step 6).
```

- [ ] **Step 7: Replace steps 5, 6 and the first half of 7**

Replace everything from `5. **Decide fan-out vs. inline.**` through the line ``   every result at once. Carry each facet's `dropped` count through into the report: where any facet`` (inclusive; the rest of step 7 after that line stays) with:

```
5. **Inline or one reviewer.** On a small change — roughly one file, ~20 changed lines or fewer,
   one hunk — work the reviewer brief's procedure yourself, inline. Above that floor, dispatch
   **exactly one** reviewer agent for every selected facet — never one agent per facet. One read
   of the change, worked facet by facet, is what keeps a run's cost flat as the facet count grows.
   Mark every facet's todo `in_progress` as the reviewer goes out, or one at a time as you reach
   each facet inline.
6. **Hand the reviewer the brief.** The reviewer follows
   [references/reviewer-brief.md](references/reviewer-brief.md): the request, the per-facet
   procedure, the hard stops, and the result shape. Resolve the brief and each selected facet's
   `references/facets/<facet>/facet.md` (relative to **this skill's own directory**) to
   **absolute** paths — prefix them with the plugin root your runtime exposes
   (`${CLAUDE_PLUGIN_ROOT}` under Claude Code) or, failing that, this skill's own directory — so a
   cold subagent, which boots in a directory it was never told, can open them; each facet's own
   `references/*.md` and `../../*` citations resolve relative to that file. List the facets in
   this fixed order, keeping only those selected — recall-critical lenses first, while attention
   is freshest:

   `security`, `tenant-isolation`, `data-safety`, `concurrency`, `idempotency`,
   `numeric-precision`, `technical`, `api`, `error-handling`, `framework-best-practices`,
   `frontend`, `test-quality`, `architectural`, `readability`

   Set `caps` (`top_n`, `floor`) from the **effort** settled in step 2 per the table in
   **Arguments**; they apply to each facet separately. The reviewer enforces the hard stops
   itself, per facet, at the source; the orchestrator does not trim findings afterward. The
   reviewer returns its result to the orchestrator and writes no file.
7. **Reconcile.** Take the reviewer's `results` — one entry per facet, skipped ones included — and
   mark every facet's todo `completed`. The reviewer files each finding under one owning facet;
   still merge any two findings that cite the same location, then order the findings and hold
   them for the single report. Carry each facet's `dropped` count through into the report: where any facet
```

- [ ] **Step 8: Todo section**

Replace the body of `## Track each facet as a todo` (from `The fan-out is legible` through `completed item at once.`) with:

```
The human sees what ran only if each facet is visible. The moment the facet set is fixed (after
step 4), seed a todo list from it — **one todo per selected facet** — in whatever todo list your
harness provides. A facet the selection lists but that is not yet available never runs and never
becomes a todo (the report lists it as skipped, not failed); a facet that will self-skip on its
own relevance gate still gets one, and closes when its result says skipped.

- **`in_progress` when the reviewer is dispatched** — every facet at once, since one reviewer
  carries them all (step 5); inline, one at a time as you reach each.
- **`completed` when the reviewer's result is in hand** (step 7), self-skips included — so a
  facet that finished with nothing reads as done, never as still running.

Reconciliation is not a facet and takes no todo of its own.
```

- [ ] **Step 9: Governing principle**

Replace the section body with:

```
Keep the self-enforcement shape (workflow step 6) when changing a facet boundary or adding a facet:
the reviewer runs each facet's gate before opening its checklist and applies its cap before moving
on. A cap applied after unbounded work saves output, not the work. And keep one reviewer: a new
facet is a new checklist item and a new place in the step-6 order, not a new agent.
```

- [ ] **Step 10: Run the checks**

```bash
grep -c 'reviewer-brief.md' skills/guardtower/SKILL.md
grep -n -i 'fan out\|fan-out\|fanned out\|independent agent\|independent reviewer\|facet-contract\|hard-stops' skills/guardtower/SKILL.md
grep -n '^[0-9]\. \*\*' skills/guardtower/SKILL.md
```

Expected: `2` (the Arguments link and the step-6 link); the second grep prints nothing; the third lists steps 1–8 in order with step 5 `**Inline or one reviewer.**`. Then the link checker prints `broken: 0`.

- [ ] **Step 11: Commit**

```bash
git add skills/guardtower/SKILL.md
git commit -m "feat: guardtower dispatches one checklist reviewer instead of one agent per facet"
```

---

### Task 4: README, manifests, version 0.5.0

**Files:**
- Modify: `README.md:8-9`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`

- [ ] **Step 1: Write the failing check**

```bash
grep -rn 'fans them out\|fan out\|independent, self-limiting\|"0.4.0"\|"version": "0.4.0"' README.md .claude-plugin .codex-plugin
```

Expected now: matches in README.md and all three manifests.

- [ ] **Step 2: README (lines 7–9)**

Replace:

```
change warrants (security, concurrency, data-safety, API compatibility, and more), dispatches each
as an independent, self-limiting reviewer, and reconciles everything into **one markdown report**. It is
```

with:

```
change warrants (security, concurrency, data-safety, API compatibility, and more), has one
self-limiting reviewer work them as a checklist over a single read of the change, and reconciles
everything into **one markdown report**. It is
```

- [ ] **Step 3: Manifests**

```bash
sed -i '' 's/fans them out as self-limiting reviewers, and reconciles their findings/works them as a checklist through one self-limiting reviewer, and reconciles its findings/' .claude-plugin/plugin.json .codex-plugin/plugin.json
sed -i '' 's/each runs as an independent, self-limiting reviewer, and their findings are reconciled/one self-limiting reviewer works them as a checklist, and its findings are reconciled/' .codex-plugin/plugin.json
sed -i '' 's/"version": "0.4.0"/"version": "0.5.0"/' .claude-plugin/plugin.json .claude-plugin/marketplace.json .codex-plugin/plugin.json
```

- [ ] **Step 4: Run the checks**

```bash
grep -rn 'fans them out\|fan out\|independent, self-limiting\|0.4.0' README.md .claude-plugin .codex-plugin
grep -rn '"version"' .claude-plugin .codex-plugin
for f in .claude-plugin/*.json .codex-plugin/plugin.json; do jq empty "$f" && echo "$f ok"; done
```

Expected: first grep prints nothing; three `"version": "0.5.0"` lines; three `ok` lines.

- [ ] **Step 5: Commit**

```bash
git add README.md .claude-plugin .codex-plugin
git commit -m "docs: describe single checklist reviewer; bump to 0.5.0"
```

---

### Task 5: After eval, compare, record

**Files:**
- Modify: `evals/README.md` (new `## Single-reviewer baseline` section before `## Running`)
- Create (scratch): `$SCRATCH/after.json`

**Interfaces:**
- Consumes: `$SCRATCH/baseline-0x.json` and the JSON paths noted in Task 1 Step 3.

- [ ] **Step 1: Run the suite on this branch**

```bash
claude plugin eval . --scaffold --trust-plugin --ablation none -j 4 \
  --no-publish --json "$SCRATCH/after.json"
```

Expected: 20 cases run. Same 30–60 minutes.

- [ ] **Step 2: Build the comparison table**

Using the score and token/cost paths from Task 1 Step 3, print one row per case: `case | 0.x score | 0.5.0 score | 0.x tokens | 0.5.0 tokens`. Example, if the paths are `.cases[].name`, `.cases[].score` and `.cases[].runs[].usage.total_tokens` (substitute the real ones):

```bash
for f in baseline-0x after; do
  jq -r '.cases[] | [.name, .score, ([.runs[].usage.total_tokens] | add / length | floor)] | @tsv' "$SCRATCH/$f.json" | sort > "$SCRATCH/$f.tsv"
done
join -t $'\t' "$SCRATCH/baseline-0x.tsv" "$SCRATCH/after.tsv" \
  | awk -F'\t' 'BEGIN{print "| Case | 0.x score | 0.5.0 score | 0.x tokens | 0.5.0 tokens |\n|---|---|---|---|---|"} {print "| `"$1"` | "$2" | "$4" | "$3" | "$5" |"}'
```

- [ ] **Step 3: Gate on recall**

A case regresses when its 0.5.0 score is lower than 0.x by 0.34 or more (one run in three). If any case regresses: stop, report the case and its failing grader to the human, and fix `reviewer-brief.md` or the step-6 order — never the grader. Re-run that case with `--case <name>` until it holds.

- [ ] **Step 4: Record in `evals/README.md`**

Insert before `## Running`:

```markdown
## Single-reviewer baseline

0.5.0 replaced the per-facet subagent fan-out with one checklist reviewer. Measured on
2026-10-16 with `--ablation none`, 3 runs per case (score = mean of runs; tokens = mean per run):

<the table from Step 2>

Total: <sum 0.x> → <sum 0.5.0> tokens (<ratio>× fewer).
```

If tokens were not reported (Task 1 Step 3), drop the token columns and the Total line, and say "token usage not reported by `claude plugin eval`".

- [ ] **Step 5: Commit, push, mark PR ready**

```bash
git add evals/README.md
git commit -m "docs: record single-reviewer eval baseline"
git push
gh pr ready 7
```

Expected: `✓ Pull request dashworthy/guardtower#7 is marked as "ready for review"`.
