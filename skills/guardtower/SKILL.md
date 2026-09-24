---
name: guardtower
description: "Run an in-depth, opt-in code review of a change through specialized facets (security, and more) that guardtower selects from what the change does, fanned out as self-limiting reviewers, then reconcile their findings into one markdown report. Use when asked for a deep code review of a diff, branch, or PR, or a security review, before merging a higher-risk change. Accepts an optional effort level (low/medium/high/max) and an optional target (a PR/MR link or number, branch, diff, or path)."
---

# guardtower (review orchestrator)

## What this guarantees

Given a change — a diff, a branch, a PR, whatever the caller points at — this skill
decides which review facets the change warrants, dispatches each selected facet as an independent
reviewer, and reconciles what they return into a single self-contained markdown report, written into
the run's own directory (see **Run artifacts**). It is
**report-only**: it states what each facet found and never edits the code.

**Report-only holds for the whole turn, even when the request asks for a fix.** A prompt that says
"review this and fix what you find" invoked guardtower, so it gets a guardtower run: the turn ends at
the written report. Do not edit, rewrite, or create any file outside the run directory — not before
the report, not after it, not as a "separate step" the caller asked for, and not through a
subagent. Instead, describe each fix in the report and close by telling the human the fix is
theirs to apply (or to ask for in a new request, outside guardtower). A reviewer that also patches
what it reviews is no longer an independent review.

This is the heavier, opt-in escalation — not an everyday pass, and not an automatic gate. Someone
decides a change is worth a deep look and runs it; nothing here watches for changes on its own.

## Arguments

The skill accepts two optional arguments, in either order; both have sensible defaults, so it also
runs with none.

- **effort** — `low` | `medium` | `high` | `max`. One dial that sets the `caps`
  the orchestrator hands every facet (`top_n`, `floor` — see
  [references/facet-contract.md](references/facet-contract.md)), trading breadth for signal in one
  place rather than per facet. Lower effort returns fewer, higher-confidence findings; higher effort
  widens coverage and admits less-certain ones:

  | effort | `top_n` | `floor` | character |
  |---|---|---|---|
  | `low` | 2 | `high` | only the few strongest findings per facet |
  | `medium` | 3 | `med` | the balanced pass |
  | `high` | 5 | `low` | broad coverage, admits lower-confidence findings |
  | `max` | 8 | `low` | the widest pass; report may run long |

  effort tunes only the caps — it never changes which facets are selected (workflow step 4). The
  floor still applies to the *weaker* of a finding's severity and confidence. effort has **no
  silent default**: when the caller did not pass one, the orchestrator asks for it (workflow
  step 2).

- **target** — an optional pointer to what to review, resolved into `change_ref`: a PR/MR link or
  number, a branch name, a diff, or a path. When omitted, `change_ref` falls back to the working
  diff / current branch as before.

Parse whatever the caller passed: a `low`/`medium`/`high`/`max` token — bare, or in a phrase like
"a LOW-effort review" — is the effort; anything that looks like a URL, `#`-number, branch, path, or
ref is the target. Adjectives such as "thorough", "deep", or "quick" are **not** an effort: they
describe the request, not a level, so an absent token still triggers the effort question. An absent
target falls back to its default; an absent effort is asked for. If a token is genuinely ambiguous,
ask once rather than guess.

## The facets

Fourteen facets exist; each is one lens, defined in a reference file under
[references/facets/](references/facets/) (`references/facets/<facet>/facet.md`), and dispatched as
an independent reviewer — not a standalone skill. Eight **core** facets are marked **Always** in
the facet list below; the rest are opt-in or **core-when-present**, per the **Select when the
change…** column of that list.

Which facets run on a given run is decided by the orchestrator itself (workflow step 4), from the
facet list's **Select when the change…** column — the human is not asked to pick.

| Facet (file) | Lens | Select when the change… |
|---|---|---|
| [`reviewing-security`](references/facets/reviewing-security/facet.md) | OWASP best practices; authorization enforced, not assumed; plus Electron process-model security (renderer isolation, preload/IPC, navigation, shell/protocol) when the change touches an Electron surface | **Always** (core) |
| [`reviewing-technical`](references/facets/reviewing-technical/facet.md) | Two lenses — Efficiency & correctness (N+1, unbounded queries, correctness-scoped best practice) and Reuse over reinvention (rebuilding what a framework/stdlib/library/imported module already provides) | **Always** (core) |
| [`reviewing-architectural`](references/facets/reviewing-architectural/facet.md) | Sustainable architecture: coupling, dependency direction, cohesion, leaky abstractions | **Always** (core) |
| [`reviewing-readability`](references/facets/reviewing-readability/facet.md) | Human readability across two lenses — Unearned abstraction (single-use indirection, premature generalization, speculative flexibility) and Over-defensive programming (guards for conditions the code's own invariants rule out) | **Always** (core) |
| [`reviewing-error-handling`](references/facets/reviewing-error-handling/facet.md) | Silent failures, swallowed exceptions, bad fallbacks | **Always** (core) |
| [`reviewing-test-quality`](references/facets/reviewing-test-quality/facet.md) | Do tests exercise the change and fail if it breaks? | **Always** (core) |
| [`reviewing-data-safety`](references/facets/reviewing-data-safety/facet.md) | Destructive/irreversible ops, migrations, data loss | alters stored-data structure or performs a destructive or irreversible data operation — a migration, a bulk update/delete, a drop |
| [`reviewing-api`](references/facets/reviewing-api/facet.md) | API surface across two lenses — Compatibility (breaking changes to a public contract it provides) and Consumption (over-fetch, client-side filtering, call volume, 429 safety of a remote API it consumes) | alters a public contract others consume, or consumes a remote/HTTP API it does not own |
| [`reviewing-concurrency`](references/facets/reviewing-concurrency/facet.md) | Race conditions and unsafe interleaving: check-then-act, non-atomic read-modify-write, missing lock/transaction | **Always** (core) |
| [`reviewing-idempotency`](references/facets/reviewing-idempotency/facet.md) | Side effects unsafe to run twice: no idempotency key, non-idempotent retry, duplicate on replay | performs a side effect that may run more than once — a retry, a queued/at-least-once handler, or a replayable operation — with no guard against duplication |
| [`reviewing-numeric-precision`](references/facets/reviewing-numeric-precision/facet.md) | Precision and unit defects: float for money, silent rounding, unit mismatch, overflow, lossy cast | **Always** (core) |
| [`reviewing-tenant-isolation`](references/facets/reviewing-tenant-isolation/facet.md) | Cross-tenant leaks, branched on DB topology — a shared-schema query that lost its tenant scope, or an isolated-DB operation on the wrong connection | When **step 3 proposed it** (a `shared`/`per-db`/`both` tenancy verdict selects the lens) — on the proposal, not further gated on the change |
| [`reviewing-frontend`](references/facets/reviewing-frontend/facet.md) | Frontend surface across three lenses — Accessibility (perceivability & operability), Data presentation (identity ambiguity), Internationalization (translatability) | alters a user-facing surface — rendered output/markup/interaction, how records are labeled or identified, or localized user-facing text |
| [`reviewing-framework-best-practices`](references/facets/reviewing-framework-best-practices/facet.md) | Stack-specific idiom violations for the detected stack(s) — ten covered, including Electron's non-security idiom (Electron security is the Security facet's) | When **step 3 proposed it** (at least one covered stack detected) — on the proposal |

## The workflow

1. **Resolve the change and open the run directory.** Resolve `change_ref` (the diff/branch/PR under
   review) — from the **target** argument when one was passed (a PR/MR link or number, branch, diff,
   or path), otherwise the working diff / current branch — and read what the change actually does.
   Then create the run directory every artifact of this run is written into (see **Run artifacts**).
2. **Settle the effort — ask when it wasn't given.** If the caller passed an effort, use it and do
   not ask. Otherwise put the question to the human **through the runtime's question tool**
   (`AskUserQuestion` under Claude Code; the equivalent structured-question tool elsewhere) — never
   as a plain-text question in the reply, and never by silently assuming a level. Ask it as one
   single-select question with the four levels as options, **the recommended level first with
   ` (Recommended)` appended to its label**, the rest in `low` → `max` order, each option's
   description stating its caps and character from the **Arguments** table. Recommend from the change
   you read in step 1:
   - **`low`** — a small change (roughly one file, ~20 changed lines or fewer) touching none of the
     risk surfaces below;
   - **`high`** — the change touches authentication/authorization, untrusted input reaching a query,
     command, or rendered output, money or other precise numerics, stored-data structure or
     destructive data operations, concurrency, tenant scoping, or a public contract; or it spans
     more than ~300 changed lines;
   - **`medium`** — everything else;
   - **`max`** is never recommended — it is the human's to choose.

   State the one-line reason for the recommendation in the question itself. If no question tool is
   available, or it returns without an answer (a non-interactive run), proceed at the recommended
   level and record in the report that the effort was defaulted to the recommendation, not chosen.
3. **Classify the tenancy model and the stack — the proposal gate.** Decide once, at the **repo
   level**: whether this application is multi-tenant and how it isolates tenants, reasoning against
   [references/multi-tenancy-signals.md](references/multi-tenancy-signals.md); and which
   framework(s) it runs, reasoning against
   [references/stack-signals.md](references/stack-signals.md). Both are **agent-driven** (weigh
   the signals in the codebase), never a shell script. Emit the tenancy verdict — `shared`,
   `per-db`, `both`, `none`, or `ambiguous` — and on `ambiguous` ask the human once (through the
   question tool, as in step 2); separately emit the stack verdict as a **set** of matched
   frameworks (zero or more), never a single mutually-exclusive value, since a repo can run more
   than one at once. The tenancy verdict governs whether the single `reviewing-tenant-isolation`
   facet is proposed and which lens it applies: `shared` → proposed, shared-DB lens; `per-db` →
   proposed, isolated-DB lens; `both` → proposed, both lenses; `none` → not proposed. The stack
   verdict governs only whether `reviewing-framework-best-practices` is proposed: any non-empty set →
   proposed; an empty set → not proposed. This is the upper of guardtower's **two-gate** model: a
   repo-level proposal gate that sits *above* each facet's own per-change relevance gate — a
   proposed facet still self-skips on a change that touches no tenant-scoped or stack-relevant
   surface, so proposing is not running.
4. **Select the facets — guardtower decides.** Read the **Select when the change…** column of the
   facet list above and reason over the change's character (*what it does*, never its file paths or
   types) together with the step-3 verdicts:
   - the **core** facets (those marked **Always** in the list) are selected on every run, whatever
     the change;
   - each **opt-in** facet whose list entry matches the change's character is selected, erring
     toward inclusion — a false skip (a lens left off) is the harmful direction, while a
     false-positive self-skips cheaply at dispatch;
   - each **core-when-present** facet (`reviewing-tenant-isolation` and
     `reviewing-framework-best-practices`) is selected when the step-3 proposal gate proposed it —
     the proposal is its list entry, so it is *not* further gated on the change's character.

   When no opt-in entry clearly matches, or the change cannot be read, select the core facets plus
   any core-when-present facet step 3 proposed — that set is the floor, and matching only ever adds
   to it. **Do not ask the human to pick, confirm, or edit the set** — no multi-select, no "run
   these?" prompt. Announce the selection in one line (each selected facet, and for each opt-in or
   core-when-present facet the phrase from the change that selected it) and proceed straight to
   dispatch; the same selection, with its reasons and the facets left out, goes into the report. The
   list only selects — each facet's own per-change relevance gate **stays authoritative** at
   dispatch, so a selected facet the change never touches self-skips there rather than producing a
   hollow review. The orchestrator opens no facet's own doc to select; a facet's file is read only
   when it is dispatched (step 6).
5. **Decide fan-out vs. inline.** On a small change — roughly one file, ~20 changed lines or fewer,
   one hunk — reviewing every selected facet inline costs less than spinning up subagents; do it
   inline. Above that floor, **fan out** the selected facets in parallel: dispatch each as an
   independent agent that shares only a *read* of `change_ref` — no facet reads what another
   produces, so the reviewers stay fully independent. Mark each facet's todo `in_progress` as it
   goes out, or as you begin it inline.
6. **Hand each facet the contract.** Each selected facet is defined by its file
   `references/facets/<facet>/facet.md`, relative to **this skill's own directory**. Before
   dispatching a reviewer, resolve that to an **absolute** path — prefix it with the plugin root your
   runtime exposes (`${CLAUDE_PLUGIN_ROOT}` under Claude Code) or, failing that, this skill's own
   directory — and hand the reviewer that absolute path to read and apply, so a cold subagent, which
   boots in a directory it was never told, can resolve it; the facet's own
   `references/*.md` and `../../*` citations then resolve relative to that file's own directory. Pass
   every facet the same request and expect the same result shape — see
   [references/facet-contract.md](references/facet-contract.md). Set the request's `caps` (`top_n`,
   `floor`) from the **effort** settled in step 2 per the table in **Arguments** — the same caps to
   every facet, so the discipline is tuned in one place. Each facet enforces the hard stops
   itself, at the source — see [references/hard-stops.md](references/hard-stops.md); the
   orchestrator does not trim findings afterward. A reviewer returns its result to the orchestrator;
   it writes no file of its own outside the run directory.
7. **Reconcile.** Gather all results — nothing dropped because it returned last, nothing picked
   because it returned first; mark each facet's todo `completed` as its result lands. Deduplicate
   where two facets flag the same location, order the findings, and hold them for the single report.
   Reconciliation is the one thing a facet does not own; it needs
   every result at once. Carry each facet's `dropped` count through into the report: where any facet
   hit its cap, the report states how many genuine findings wait behind it (e.g. "Security: 3 more
   above the floor — re-run to see them"). The cap keeps the report short; it does not get to make
   the report *look* complete when it isn't. A reader deciding whether to re-run needs to know work
   was held back, not discover it by accident.
8. **Write the report — always from the handoff template.** The reconciled findings are the whole
   deliverable, and there is **one** report format: read and fill
   [references/templates/markdown/code-review-handoff.md](references/templates/markdown/code-review-handoff.md)
   on **every** run — whatever the caller asked for, whatever the effort, whether or not anyone
   mentioned a handoff, a PR, or sharing. Never substitute a findings table, a bullet summary, or a
   format of your own. Each finding gets the template's four required parts, in order — **Evidence** (cited
   `file:line`, quoted verbatim, showing the defect is real), **Current code**, **Proposed fix**,
   **Why this fixes it** — with fenced code; a finding without evidence is dropped, not reported; a clean run fills the template's
   **No findings** section; every run fills **Review scope** (target, effort and whether it was
   chosen or defaulted, the facets run with why each was selected, the facets not run, each facet's
   relevance verdict, and any `dropped` count stated in words). Write it as `report.md` in the run
   directory. The reply to the human may summarise the findings, but the file is the template. End the
   run by telling the human the report's path — and, if they asked for fixes, that the fixes are
   described in the report for them to apply, not applied. The report is the last file this turn
   writes. Write it whole, in one file-write call; to revise it, rewrite the whole file the same
   way rather than patching it with an edit tool, so any edit-tool call in a guardtower run is
   unambiguously a code edit — which report-only forbids. The report never leaves the machine on
   its own: posting it onward, or acting on it, is the human's to do; guardtower is report-only and
   stops at the written report (a "proposed fix" is described, never applied).

## Run artifacts

Every file a run writes lands in one directory per run:

```
.guardtower/{date}-{run-name}/{artifact}.md
```

- **Root** — `.guardtower/` at the root of the repository under review (the working directory when
  it is not a repository).
- **`{date}`** — the run's local date, `YYYY-MM-DD`.
- **`{run-name}`** — a lowercase kebab-case slug of the target: `pr-142` for a PR/MR number or
  link, the branch name for a branch (`feat/login-rate-limit` → `feat-login-rate-limit`), the
  path's final segment for a path, and the current branch's name for the working diff (`working`
  when detached or unborn). Keep it to 60 characters.
- **Collisions** — if the directory already exists, append `-2`, `-3`, … rather than write into a
  previous run's directory.
- **`{artifact}`** — `report.md`, filled from the handoff template (step 8). A caller-named file name is honoured,
  but always inside the run directory; a caller-named directory elsewhere is not — the run
  directory is the one place a run writes.

The orchestrator creates the directory; guardtower writes nowhere else in the repository and never
edits `.gitignore` — whether `.guardtower/` is committed is the human's call.

## Track each facet as a todo

The fan-out is legible to the human only if they can see what was dispatched and what has come
back. The moment the facet set is fixed (after step 4), seed a todo list from it — **one todo per
selected facet, each seam its own item** — in whatever todo list your harness provides. A facet the
selection lists but that is not yet available never runs and never becomes a todo (the report
lists it as skipped, not failed); a facet that will self-skip on its
own relevance gate still gets one, and closes when it returns "nothing to review."

Keep the list in lockstep with the dispatch:

- **`in_progress` as the facet is dispatched** — in fan-out that is several at once, one per
  reviewer in flight (step 5); inline it is one at a time as you work down the set.
- **`completed` the instant its result is in hand** (step 7), a
  self-skip included — so a facet that finished with nothing reads as done, never as still running.

Reconciliation is not a facet and takes no todo of its own; it is the step that consumes every
completed item at once.

## Governing principle

Keep the self-enforcement shape (workflow step 6) when changing a facet boundary or adding a facet:
a cap the orchestrator applies after a facet has already done unbounded work saves output, not the
work.

## What this does not do

- It does not **fix what it finds** — not even when the same request asks it to. guardtower never
  edits code, in the run or after it within the same turn; the reconciled report is information a
  human (or a downstream tool they choose) acts on — applying a finding is someone else's job, in a
  separate request.
- It does not **decide when a review happens**, and it does not **stand in for sign-off.** A clean
  report is information a human uses to decide whether to merge, not a switch this skill throws; and
  what the findings do next is the human's call, not this skill's.
