# Single checklist reviewer — design

**Date:** 2026-10-16 · **Target version:** 0.5.0 (with test verification) · **Branch:** `feat/test-verification`

## Goal

Cut the token cost of a guardtower run. Today each selected facet is its own subagent, so a run
with ~10 facets boots ~10 agents and reads the diff and touched code ~10 times. Replace the
fan-out with **one reviewer agent** that reads the diff once and works the selected facets as a
checklist, one facet after another.

Rough cost per run (estimates, not measured; `D` = diff plus touched code):

| Shape | Cost |
|---|---|
| Today — fan-out, ~10 facets | ~10 × (~15K agent boot + ~3K contract/hard stops + ~2K facet files + D) |
| This design — one reviewer | ~15K boot + ~2K brief + selected facet files + D |

With D ≈ 10K that is ~300K → ~50–60K tokens, roughly 5× cheaper.

## Decisions

| Question | Decision |
|---|---|
| Execution shape | One reviewer agent works every selected facet as a checklist item; orchestrator stays lean |
| Tiny changes | Still reviewed inline by the orchestrator (~1 file, ≤20 changed lines, one hunk) |
| Reference files | Light touch: one new `reviewer-brief.md` replaces `facet-contract.md` + `hard-stops.md`; `facet.md` files and checklists are unchanged apart from their pointer line |
| Caps | Applied **per facet**, as today — `top_n`, `floor`, `dropped` unchanged |
| Verify step | Also one agent — see the amended `2026-10-15-test-verification-design.md` |
| Trade-off accepted | Facets lose full independence (one context, later lenses can be anchored by earlier ones). The fixed facet order and the per-facet gate limit this; the recall evals measure it |

## Workflow change (`SKILL.md`)

Steps 1–4 are unchanged. Steps 5–7 change:

```
1 resolve change, open run dir      (unchanged)
2 settle effort                     (unchanged)
3 tenancy / stack verdicts          (unchanged)
4 select facets                     (unchanged)
5 inline or ONE reviewer            <- was "inline or fan out N"
6 hand the reviewer the brief       <- one request listing all selected facets
7 reconcile                         (lighter: the reviewer already deduped across facets)
8 verify                            (per the test-verification spec)
9 write report.md
```

### Step 5 — inline or one reviewer

- **Tiny change** (~1 file, ≤20 changed lines, one hunk): the orchestrator works the brief's
  procedure itself, inline.
- **Otherwise:** dispatch exactly **one** reviewer agent. No other review agents are dispatched.

### Step 6 — the request

The orchestrator resolves each selected facet's `facet.md` to an absolute path (plugin root or
this skill's directory, as today) and hands the reviewer one request (schema below), with the
facets in this fixed order — recall-critical lenses first, design lenses last:

```
security, tenant-isolation, data-safety, concurrency, idempotency, numeric-precision,
technical, api, error-handling, framework-best-practices, frontend, test-quality,
architectural, readability
```

Only selected facets appear; the order is the relative order of those that do.

### Step 7 — reconcile

Takes the reviewer's `results` array. Dedupe is mostly done (see the cross-facet rule), so
reconciliation orders findings, carries each facet's `dropped` count into the report, and
records each facet's relevance verdict — as today.

## `references/reviewer-brief.md` (new)

Merges and tightens `facet-contract.md` and `hard-stops.md` (~10KB → target ~5KB), written for
one agent working many facets. Both old files are deleted.

### Request — orchestrator → reviewer

```
{
  change_ref: <git ref / diff / path the review targets>,
  spec_ref:   <path to a governing spec> | none,
  caps:       { top_n: <int>, floor: "low" | "med" | "high" },   // applied per facet
  facets:     [ <absolute path to facet.md>, ... ]              // in the fixed order
}
```

### Procedure

1. **Read the change once** — the diff, plus the public surface of modules it touches where a lens
   needs it. Diff-bounded reach is unchanged: no repo-wide scan, graph, or index.
2. **For each facet, in order:**
   1. Read its `facet.md`.
   2. **Relevance gate first.** If the change does not touch this facet's surface, record
      `relevance: { skipped: <reason> }` and move to the next facet **without opening its
      checklist**.
   3. Open the facet's checklist(s) just-in-time and work them against the change already read.
   4. **Floor, then cap, then tally `dropped`**, for this facet alone.
   5. Record this facet's Result, then move on.
3. **Cross-facet rule:** a finding is recorded under the one facet that owns it (each `facet.md`
   names its boundaries) and is not filed again under a second facet.
4. **Return** the Result below. Report-only: the reviewer writes no file.

The hard stops (relevance gate, top-N cap with `dropped`, floor on the weaker of severity and
confidence, speculation guard), the clean-result rule (`[]` is valid; no hedged sub-floor
padding), and the Finding schema carry over unchanged in meaning.

### Result — reviewer → orchestrator

```
{
  results: [
    { facet, relevance, findings: [Finding, ...], dropped },   // today's per-facet Result
    ...
  ]
}
```

One entry per facet in the request, in request order, skipped ones included. The Finding schema
is unchanged, so the report template needs no change for this design.

## Todos

Still one todo per selected facet, so the human sees which facets ran. All go `in_progress` when
the reviewer is dispatched (or one at a time when inline) and `completed` when its result
returns.

## Files

| File | Change |
|---|---|
| `skills/guardtower/SKILL.md` | Steps 5–7 rewritten; todo section; links to `reviewer-brief.md`; description ("fanned out as self-limiting reviewers" → one checklist reviewer); "Governing principle" points at the per-facet stops in the brief |
| `skills/guardtower/references/reviewer-brief.md` | New — request, procedure, result, hard stops, Finding schema |
| `skills/guardtower/references/facet-contract.md` | Deleted (merged into the brief) |
| `skills/guardtower/references/hard-stops.md` | Deleted (merged into the brief) |
| `skills/guardtower/references/facets/*/facet.md` | Pointer line `../../facet-contract.md` / `../../hard-stops.md` → `../../reviewer-brief.md`; no other change |
| `README.md` | Describe the single reviewer |
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json` | Description wording; version bump shared with test verification (0.4.0 → 0.5.0) |

## Evals

- **Existing 20 cases: unchanged and must still pass.** The recall cases (`cr-security-sqli`,
  `cr-correctness-subtle`, `cr-efficiency-nplus1`, `cr-concurrency-race`, …) are the quality
  check on losing per-facet independence; the controls check the single reviewer does not
  over-report.
- **Before/after baseline.** Run the suite on `0.x` and on this branch. Record per-case pass rate
  and, if `claude plugin eval` reports it, total tokens, in a short table in `evals/README.md`.
- A recall regression on any case blocks the merge; the fix is to the brief or the facet order,
  not to the grader.

## Out of scope

- Slimming `facet.md` files or merging checklists into one file.
- Splitting into several reviewer agents for large changes or high effort.
- A flag to restore the per-facet fan-out.
