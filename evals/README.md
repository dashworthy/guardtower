# guardtower evals

Behavioral eval suite for the `guardtower` plugin, run with the native `claude plugin eval`
harness. Each case is a realistic prompt plus graders, scored against a no-plugin baseline (two-arm
ablation) so every number says what guardtower *adds* over plain Claude.

## The cases

Six cases: five planted-defect recall checks plus one clean-diff control that guards against
manufactured findings.

| Case | Measures |
|---|---|
| `cr-security-sqli` | Catches a SQL injection introduced by the change (PHP). |
| `cr-correctness-subtle` | Catches a subtle off-by-one in a date loop (TypeScript). |
| `cr-efficiency-nplus1` | Catches an N+1 query pattern (Python). |
| `cr-concurrency-race` | Catches a check-then-act (TOCTOU) race (PHP). |
| `cr-reuse-reinvent` | Notices a hand-rolled backoff that should reuse a shared helper (needs codebase awareness, PHP). |
| `cr-clean-control` | On a genuinely clean change, reports no material defect and manufactures no false positive. |

## How scoring is wired

- **`fired-guardtower`** — a `with-only` indicator (`tool_used: Skill`,
  `input_match: '(?:[\w-]+:)?guardtower'`, `min:1`): confirms guardtower engaged. The baseline (no
  plugin, cannot fire a skill) scores 0; the plugin scores 1 — a clean delta. Not scored on its own;
  it just confirms the plugin engaged.
- **recall graders** (`catches-*` / `flags-*`) — an `llm` check that the report names the planted
  defect.
- **report-only guard** (`report-only-no-edits`) — `tool_used: Edit, min:0, max:0`: guardtower must
  not modify the code it reviews.
- **`cr-clean-control`** uses `no-false-positive` to assert no material defect is manufactured on a
  clean diff.

Each case's `scaffold.sh` builds a tiny git repo unsandboxed (as the author) and captures the change
as `CHANGE.diff`; the agent reviews by reading `CHANGE.diff` + `src/`, needing no Bash/git of its
own.

## Running

```bash
claude plugin eval evals/cr-security-sqli      # one case
claude plugin eval evals/                       # the whole suite
```
