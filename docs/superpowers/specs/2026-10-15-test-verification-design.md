# Test verification of findings — design

**Date:** 2026-10-15 · **Target version:** 0.5.0 · **Branch:** `feat/test-verification`

## Goal

Cut false positives. Before the report is written, guardtower tries to prove each behavioural
finding with a test. A finding the test confirms is marked **verified**; a finding the test
disproves is **dropped** (and listed as disproved); a finding that cannot be tested is kept and
marked **unverified** with the reason.

Verification runs on **every** run, at every effort. Effort already bounds the number of findings,
so verification cost scales with effort without a new argument.

## Decisions

| Question | Decision |
|---|---|
| Purpose | Cut false positives (not primarily a dev handoff) |
| Where tests are written and run | A throwaway git worktree outside the repo; copies kept in the run dir |
| Unverifiable findings | Kept, labelled `unverified: <reason>`. Only a clean test result drops a finding |
| Who verifies | A separate step after reconcile; **one** fresh verifier agent that works every behavioural finding as a checklist (amended 2026-10-16 for token cost — see `2026-10-16-single-reviewer-design.md`) |
| When | Every run, every effort |
| Test shape | Asserts the **correct** behaviour: fails today, passes once fixed |

## Workflow change

Steps 1–7 are as in `2026-10-16-single-reviewer-design.md`. A new step 8 is inserted; the report becomes step 9.

```
1 resolve change, open run dir    6 hand the reviewer the brief
2 settle effort                   7 reconcile + dedupe
3 tenancy / stack verdicts        8 VERIFY            <- new
4 select facets                   9 write report.md   (was 8)
5 inline or one reviewer
```

### Step 8 — Verify

1. **Triage.** For each reconciled finding, decide whether it is *behavioural* (a runtime
   outcome a test can observe: wrong value, injection reaching a query, race, duplicate side
   effect, data loss, crash) or *design* (readability, architecture, reuse, test-quality, and any
   other finding whose claim is about the code's shape rather than its behaviour). Design findings
   are marked `unverified: design finding, not testable by a unit test` with no agent dispatched.
2. **Shell check.** If the runtime gives the orchestrator no shell, mark every behavioural finding
   `unverified: no shell available to run tests` and go to step 9. (All existing evals run without
   Bash and exercise this path; their expectations are unchanged.)
3. **Worktree.** Create a detached git worktree in the system temp directory
   (`$TMPDIR/guardtower-<run-name>-<random>`):
   - base: the change's head — for a working diff, `HEAD` plus `git diff HEAD --binary` applied
     and untracked (non-ignored) files copied in; for a branch, that branch; for a PR/MR, its
     fetched head ref; for a bare path or diff with no ref, `HEAD` with the diff applied.
   - dependencies: symlink the repo's installed dependency directories (`vendor/`,
     `node_modules/`, a local virtualenv such as `.venv/`) into the worktree when they exist, so
     nothing is reinstalled.
   If the worktree cannot be created (not a git repo, apply fails), mark every behavioural finding
   `unverified: could not build an isolated worktree — <reason>` and go to step 9.
4. **Suite smoke check.** Detect the test runner from the repo (e.g. `phpunit.xml`,
   `package.json` test script, `pytest.ini`/`pyproject.toml`, `go.mod`, `Cargo.toml`), and the
   directory convention new tests go in. Run one existing test (or, if the repo has no tests, a
   trivial one written into the worktree). If the suite does not boot, mark every behavioural
   finding `unverified: test suite not runnable — <first error line>`, dispatch no verifiers, and
   go to cleanup.
5. **Dispatch the verifier.** **One** fresh verifier agent, handed the request in
   `references/verify-contract.md` listing every behavioural finding. It works them in order, as
   a checklist, in the one worktree: for each finding it writes a uniquely named test file
   (`guardtower_<finding-id>_test.<ext>` or the runner's naming convention) and runs **only that
   file**, so shared database or external state is never contended. The verify step gets one
   todo (`verify <n> findings`), `in_progress` on dispatch and `completed` on return.
6. **Apply verdicts.** `verified` → kept, labelled verified. `disproved` → removed from the
   findings and added to the report's **Disproved** list. `unverified` → kept, labelled with the
   reason.
7. **Cleanup — always, even after a failure above.** Copy every test file a verifier wrote into
   `.guardtower/{run}/tests/` (Write, whole file), then `git worktree remove --force <path>` and
   `git worktree prune`. If removal fails, say so in the report's Review scope with the path, so
   the human can remove it.

## Verifier contract (`references/verify-contract.md`, new)

### Request — orchestrator → verifier

```
{
  findings: [
    { finding: Finding,              // the reconciled finding, schema per reviewer-brief.md
      test_file: <the file name to use> },
    ...
  ],
  worktree:       <absolute path>,   // the isolated copy; the only place the verifier writes
  test_command:   <how to run a single test file, with {file} placeholder>,
  test_dir:       <where new tests go, relative to worktree>
}
```

### Result — verifier → orchestrator

One entry per finding, in request order:

```
{
  results: [
    {
      status:          "verified" | "disproved" | "unverified",
      reason:          <one line>,
      test_file:       <path inside the worktree> | none,
      command:         <the exact command run> | none,
      output_excerpt:  <the failing assertion or the relevant output, at most ~15 lines> | none
    },
    ...
  ]
}
```

### Rules

1. **The test asserts the correct behaviour.** It is written so that it fails today because of
   the defect, and passes once the finding's proposed fix is applied.
2. **Verdicts:**
   - assertion fails **and** the failure message matches the finding's claimed defect →
     `verified`;
   - test passes → `disproved`;
   - assertion fails for an unrelated reason, or the test errors (does not compile, setup fails,
     fixture missing, timeout) → `unverified`. **An error is never a verdict.**
3. **Three attempts per finding.** The verifier may rewrite each finding's test up to three times to get it to compile
   and run. After the third failed attempt the result is `unverified: <last error line>`.
4. **Writes only inside the worktree, only test files, only with Write.** Never Edit — the
   `report-only-no-edits` graders count Edit calls. Never modify the code under test, a fixture,
   or config; a test that needs that is `unverified: needs <what>`.
5. **No network.** A test that would need a live remote service is `unverified: needs <service>`.

## Report changes (`templates/markdown/code-review-handoff.md`)

- **Each finding heading line** gains the verification status:
  `` `<file:line>` · confidence: <…> · **verified** `` or `· unverified: <reason>`.
- **Proof block** becomes **"Proof — this test fails today, passes once fixed"**. It is required
  for verified findings and absent otherwise. It holds the test's path in the run dir
  (`tests/<file>`), the command, and the output excerpt.
- **Review scope** gains:
  - `**Verification:** <n> verified · <n> unverified · <n> disproved` plus the worktree note if
    cleanup failed, or the run-wide reason if verification could not run (no shell, no worktree,
    suite not runnable).
  - a **Disproved** list: one line per dropped finding — title, location, and the test result
    that disproved it. Nothing disappears silently, matching the existing `dropped` counts.
- **"How to read this"** mentions the verified/unverified labels.

## Report-only, restated

guardtower still never edits the code under review, in the user's working tree or anywhere else.
The only writes outside the run directory are the temporary worktree (test files only) and git's
own worktree metadata, both removed in cleanup. Proposed fixes are still described, never applied
— the verifier proves the defect; it does not try the fix.

SKILL.md's report-only paragraphs, the **Run artifacts** section (adds `tests/`), and **What this
does not do** are updated to say exactly this. The report is still the last file the turn writes.

## Files

| File | Change |
|---|---|
| `skills/guardtower/SKILL.md` | New step 8; report becomes step 9; report-only and run-artifacts wording; verifier todos; description mentions verification |
| `skills/guardtower/references/verify-contract.md` | New — request, result, rules above |
| `skills/guardtower/references/reviewer-brief.md` | Note that the reviewer runs no tests; verification is the orchestrator's step 8 |
| `skills/guardtower/references/templates/markdown/code-review-handoff.md` | Verification label, Proof block, Verification line, Disproved list |
| `README.md`, `evals/README.md` | Describe verification; list new evals |
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json` | Mention verification; bump 0.4.0 → 0.5.0 |

## Evals

Existing 20 cases: unchanged. They have no Bash, so they exercise the "no shell" path.

New cases, all Python with the standard library only (`unittest` + `sqlite3`), so the scaffold
needs nothing installed. Each allows `Bash` in `allowed_tools`.

| Case | Change | Graders |
|---|---|---|
| `cr-verify-confirms` | Adds a search function that builds SQL by string concatenation over an sqlite3 connection; repo has a passing `tests/` suite | SQLi finding marked **verified**; a test file exists under `.guardtower/*/tests/`; report has the fails-today Proof block; worktree gone (`git worktree list` shows one entry); `git status` shows only `.guardtower/` as new; no Edit calls |
| `cr-verify-disproves` | A change that reads like an unescaped-input bug, but the value is validated by a caller the diff doesn't show | If guardtower raises the finding, it is **not** in the findings and **is** in the Disproved list; worktree gone; no Edit calls |
| `cr-verify-unrunnable` | A behavioural bug in a repo whose test runner is configured but broken (e.g. a `conftest.py` that raises on import) | Finding kept as `unverified: test suite not runnable`; no verifier agent dispatched; worktree gone; no Edit calls |

## Out of scope

- Trying the proposed fix to confirm it turns the test green.
- Installing dependencies inside the worktree.
- Integration or end-to-end tests needing running services (databases other than sqlite, queues,
  HTTP services). Those findings are `unverified: needs <service>`.
- A flag to turn verification off.
