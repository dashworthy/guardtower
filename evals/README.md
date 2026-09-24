# guardtower evals

Behavioral eval suite for the `guardtower` plugin, run with the native `claude plugin eval`
harness. Each case is a realistic prompt plus graders, scored against a no-plugin baseline (two-arm
ablation) so every number says what guardtower *adds* over plain Claude.

## The cases

Twenty cases in three groups.

**Recall** — a planted defect the review must name:

| Case | Measures |
|---|---|
| `cr-security-sqli` | Catches a SQL injection introduced by the change (PHP). |
| `cr-correctness-subtle` | Catches a subtle off-by-one in a date loop (TypeScript). |
| `cr-efficiency-nplus1` | Catches an N+1 query pattern (Python). |
| `cr-concurrency-race` | Catches a check-then-act (TOCTOU) race (PHP). |
| `cr-reuse-reinvent` | Notices a hand-rolled backoff that should reuse a shared helper (needs codebase awareness, PHP). |
| `cr-data-safety-destructive` | Catches an unguarded bulk `DELETE` that can wipe every row (Python). |
| `cr-idempotency-retry` | Catches a payment charge retried with no idempotency key (Python). |
| `cr-numeric-precision-money` | Catches money handled as floating point (Python). |
| `cr-tenant-isolation-leak` | Catches a query in a multi-tenant repo that dropped its `tenant_id` scope. |

**Controls** — no false positives:

| Case | Measures |
|---|---|
| `cr-clean-control` | On a clean change, reports no material defect and manufactures no false positive; the report still follows the handoff template (No findings + Review scope). |
| `cr-clean-control-ts` | The same, in a second stack (TypeScript). |
| `cr-relevance-skip` | On a comments/docs-only change, facets self-skip rather than inventing findings from prose. |

**Mechanics** — how guardtower runs:

| Case | Measures |
|---|---|
| `cr-effort-ask` | With no effort given, asks via `AskUserQuestion` (four levels, recommended `high` first). When the harness exposes no question tool, it proceeds at `high` and the report says the effort was defaulted. |
| `cr-effort-cap` | At low effort, caps findings per facet and states how many were held back; with the effort given, does not ask for one. |
| `cr-auto-facet-selection` | Selects data-safety, API, and idempotency on its own from what the change does, and never asks the human to pick facets. |
| `cr-menu-tenant-proposal` | In a multi-tenant repo, the repo-level proposal gate selects the tenant-isolation facet. |
| `cr-run-artifacts-dir` | Writes the report to `.guardtower/{date}-{run-name}/report.md` and nothing outside that run directory. |
| `cr-handoff-default` | With no mention of a handoff, the report still uses the handoff template: per-finding evidence / current code / fix / why, plus a Review scope section. |
| `cr-handoff-format` | When asked for a shareable handoff, the report takes the per-finding evidence / current code / fix / why layout. |
| `cr-adversarial-report-only` | Stays report-only even when the prompt asks it to fix the defect. |

Every prompt except `cr-effort-ask` names an effort level, so the effort question does not stall a
non-interactive run.

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
- **question graders** — `tool_used: AskUserQuestion, max:0` (`cr-effort-cap`,
  `cr-auto-facet-selection`: nothing to ask, and never a facet pick). Those cases add
  `AskUserQuestion` to `allowed_tools`, but `claude plugin eval` runs sessions in `dontAsk` mode and
  currently strips the tool, so these hold trivially and `cr-effort-ask` grades the documented
  fallback instead. Check the interactive question by hand: run `/guardtower:guardtower` with no
  effort in a normal session.
- **artifact-path graders** — `tool_used: Write` with an `input_match` on
  `.guardtower/YYYY-MM-DD-<run-name>/report.md`.
- **report-structure graders** (`report-has-four-parts`) — `tool_used: Write` whose `input_match`
  requires the report file to carry **Evidence** (with a `file:line` citation), **Current code**,
  **Proposed fix**, **Why this fixes it**, and `## Review scope`, in that order. This check is
  deterministic on purpose: the LLM judge's trace elides long runs and often hides the report's
  `Write` call entirely.

Each case's `scaffold.sh` builds a tiny git repo unsandboxed (as the author) and captures the change
as `CHANGE.diff`; the agent reviews by reading `CHANGE.diff` + `src/`, needing no Bash/git of its
own.

## Running

```bash
claude plugin eval evals/cr-security-sqli      # one case
claude plugin eval evals/                       # the whole suite
```
