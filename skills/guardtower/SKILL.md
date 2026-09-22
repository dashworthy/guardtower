---
name: guardtower
description: "Run an in-depth, opt-in code review of a change through a menu of specialized facets (security, and more) fanned out as self-limiting reviewers, then reconcile their findings into one markdown report. Use when asked for a deep code review of a diff, branch, or PR, or a security review, before merging a higher-risk change. Accepts an optional effort level (low/medium/high/max) and an optional target (a PR/MR link or number, branch, diff, or path)."
---

# guardtower (review orchestrator)

## What this guarantees

Given a change — a diff, a branch, a PR, whatever the caller points at — this skill
lets the human pick which review facets to run, dispatches each selected facet as an independent
reviewer, and reconciles what they return into a single self-contained markdown report. It is
**report-only**: it states what each facet found and never edits the code.

This is the heavier, opt-in escalation — not an everyday pass, and not an automatic gate. Someone
decides a change is worth a deep look and runs it; nothing here watches for changes on its own.

## Arguments

The skill accepts two optional arguments, in either order; both have sensible defaults, so it also
runs with none.

- **effort** — `low` | `medium` | `high` | `max` (default `medium`). One dial that sets the `caps`
  the orchestrator hands every facet (`top_n`, `floor` — see
  [references/facet-contract.md](references/facet-contract.md)), trading breadth for signal in one
  place rather than per facet. Lower effort returns fewer, higher-confidence findings; higher effort
  widens coverage and admits less-certain ones:

  | effort | `top_n` | `floor` | character |
  |---|---|---|---|
  | `low` | 2 | `high` | only the few strongest findings per facet |
  | `medium` | 3 | `med` | the default balance |
  | `high` | 5 | `low` | broad coverage, admits lower-confidence findings |
  | `max` | 8 | `low` | the widest pass; report may run long |

  effort tunes only the caps — it never changes which facets are selected (that is the menu, workflow
  steps 1–2). The floor still applies to the *weaker* of a finding's severity and confidence.

- **target** — an optional pointer to what to review, resolved into `change_ref`: a PR/MR link or
  number, a branch name, a diff, or a path. When omitted, `change_ref` falls back to the working
  diff / current branch as before.

Parse whatever the caller passed: a bare `low`/`medium`/`high`/`max` token is the effort; anything
that looks like a URL, `#`-number, branch, path, or ref is the target. When either is absent, use
its default. If a token is genuinely ambiguous, ask once rather than guess.

## The facets

Fourteen facets exist; each is one lens, defined in a reference file under
[references/facets/](references/facets/) (`references/facets/<facet>/facet.md`), and dispatched as
an independent reviewer — not a standalone skill. Eight **core** facets are marked **Always** in
the facet list below; the rest are opt-in or **core-when-present**, per the **Pre-check when the
change…** column of that list.

Which facets arrive **pre-checked** on a given run is decided at menu-fill time (workflow step 2),
from the facet list's **Pre-check when the change…** column.

| Facet (file) | Lens | Pre-check when the change… |
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
| [`reviewing-tenant-isolation`](references/facets/reviewing-tenant-isolation/facet.md) | Cross-tenant leaks, branched on DB topology — a shared-schema query that lost its tenant scope, or an isolated-DB operation on the wrong connection | When **step 1 proposed it** (a `shared`/`per-db`/`both` tenancy verdict selects the lens) — on the proposal, not further gated on the change |
| [`reviewing-frontend`](references/facets/reviewing-frontend/facet.md) | Frontend surface across three lenses — Accessibility (perceivability & operability), Data presentation (identity ambiguity), Internationalization (translatability) | alters a user-facing surface — rendered output/markup/interaction, how records are labeled or identified, or localized user-facing text |
| [`reviewing-framework-best-practices`](references/facets/reviewing-framework-best-practices/facet.md) | Stack-specific idiom violations for the detected stack(s) — ten covered, including Electron's non-security idiom (Electron security is the Security facet's) | When **step 1 proposed it** (at least one covered stack detected) — on the proposal |

## The workflow

1. **Classify the tenancy model and the stack — the menu-proposal gate.** Before building the
   menu, decide once, at the **repo level**: whether this application is multi-tenant and how it
   isolates tenants, reasoning against
   [references/multi-tenancy-signals.md](references/multi-tenancy-signals.md); and which
   framework(s) it runs, reasoning against
   [references/stack-signals.md](references/stack-signals.md). Both are **agent-driven** (weigh
   the signals in the codebase), never a shell script. Emit the tenancy verdict — `shared`,
   `per-db`, `both`, `none`, or `ambiguous` — and on `ambiguous` ask the human once; separately
   emit the stack verdict as a **set** of matched frameworks (zero or more of `laravel`,
   `tailwind`), never a single mutually-exclusive value, since a repo can run more than one at
   once. The tenancy verdict governs whether the single `reviewing-tenant-isolation` facet is
   proposed and which lens it applies: `shared` → proposed, shared-DB lens; `per-db` → proposed,
   isolated-DB lens; `both` → proposed, both lenses; `none` → not proposed. The stack verdict
   governs only whether `reviewing-framework-best-practices` is
   proposed and pre-checked: any non-empty set → proposed; an empty set → not on the menu at all.
   This is the upper of guardtower's **two-gate** model: a repo-level menu-proposal gate that sits
   *above* each facet's own per-change relevance gate — a proposed facet still self-skips on a
   change that touches no tenant-scoped or stack-relevant surface, so proposing is not running.
2. **Resolve the change, then pre-fill the facet menu.** First resolve `change_ref` (the
   diff/branch/PR under review) — from the **target** argument when one was passed (a PR/MR link or
   number, branch, diff, or path), otherwise the working diff / current branch — so the pre-fill can
   read what the change actually does. Then
   **pre-fill** the menu instead of asking the human to pick from scratch: read the **Pre-check when
   the change…** column of the facet list above and reason over the change's character (*what it
   does*, never its file paths or types) together with the step-1 tenancy/stack verdicts, to decide
   which facets arrive pre-checked:
   - the **core** facets (those marked **Always** in the list) are **pre-checked** on every run,
     whatever the change;
   - each **opt-in** facet whose list entry matches the change's character is pre-checked,
     erring toward inclusion — a false skip (a lens left off) is the harmful direction, while a
     false-positive self-skips cheaply at dispatch or is unchecked by the human here;
   - each **core-when-present** facet (the `reviewing-tenant-isolation` facet and
     `reviewing-framework-best-practices`) is pre-checked when the step-1 menu-proposal gate
     proposed it — the proposal is its list entry, so it is *not* further gated on the change's
     character; a proposed facet pre-checks exactly as it did before auto-assignment.

   When no opt-in entry clearly matches, or the change cannot be read, **fall back** to the
   original defaults — the core facets plus any core-when-present facet step 1 proposed. This
   floor is a genuine guarantee, not just the fallback's: because core and step-1-proposed
   core-when-present facets are always pre-checked and auto-assignment only ever *adds* matched
   opt-in facets on top, a run is **never pre-filled with fewer** facets than it would have been
   before auto-assignment.
   Present the pre-filled set as a structured **multi-select choice**, using a tool to ask it where
   one is available; the human unchecks or adds, and only available facets run (a not-yet-available
   pick is reported as skipped, not failed). The facet list only pre-fills the menu — each facet's
   own per-change relevance gate **stays authoritative** at dispatch, so a pre-checked facet the
   change never touches self-skips there rather than producing a hollow review. The orchestrator
   opens no facet's own doc to pre-fill; a facet's file is read only when it is dispatched (step 4).
3. **Decide fan-out vs. inline.** On a small change — roughly one file, ~20 changed lines or fewer,
   one hunk — reviewing every selected facet inline costs less than spinning up subagents; do it
   inline. Above that floor, **fan out** the selected facets in parallel: dispatch each as an
   independent agent that shares only a *read* of `change_ref` — no facet reads what another
   produces, so the reviewers stay fully independent. Mark each facet's todo `in_progress` as it
   goes out, or as you begin it inline.
4. **Hand each facet the contract.** Each selected facet is defined by its file
   `references/facets/<facet>/facet.md`, relative to **this skill's own directory**. Before
   dispatching a reviewer, resolve that to an **absolute** path — prefix it with the plugin root your
   runtime exposes (`${CLAUDE_PLUGIN_ROOT}` under Claude Code) or, failing that, this skill's own
   directory — and hand the reviewer that absolute path to read and apply, so a cold subagent, which
   boots in a directory it was never told, can resolve it; the facet's own
   `references/*.md` and `../../*` citations then resolve relative to that file's own directory. Pass
   every facet the same request and expect the same result shape — see
   [references/facet-contract.md](references/facet-contract.md). Set the request's `caps` (`top_n`,
   `floor`) from the **effort** argument per the table in **Arguments** — the same caps to every
   facet, so the discipline is tuned in one place. Each facet enforces the hard stops
   itself, at the source — see [references/hard-stops.md](references/hard-stops.md); the
   orchestrator does not trim findings afterward.
5. **Reconcile.** Gather all results — nothing dropped because it returned last, nothing picked
   because it returned first; mark each facet's todo `completed` as its result lands. Deduplicate
   where two facets flag the same location, order the findings, and hold them for the single report.
   Reconciliation is the one thing a facet does not own; it needs
   every result at once. Carry each facet's `dropped` count through into the report: where any facet
   hit its cap, the report states how many genuine findings wait behind it (e.g. "Security: 3 more
   above the floor — re-run to see them"). The cap keeps the report short; it does not get to make
   the report *look* complete when it isn't. A reader deciding whether to re-run needs to know work
   was held back, not discover it by accident.
6. **Write the report.** The reconciled findings are the whole deliverable: write them as **one
   self-contained markdown report file** — a findings table (facet, location, severity/confidence,
   claim) followed by a short per-finding detail (the `why` and any suggested direction), plus each
   facet's relevance verdict and any `dropped` count stated in words. Write it to the path the
   caller named, or a sensible default (e.g. `guardtower-report.md` in the working directory) when
   none was given. When the report is going to a person or a PR/wiki rather than a quick local read,
   fill the richer, shareable handoff scaffold —
   [references/templates/markdown/code-review-handoff.md](references/templates/markdown/code-review-handoff.md)
   (per-finding current code, proposed fix, and why it works) — instead of the terse table. Either
   way the report never leaves the machine on its own: posting it onward, or acting on it, is the
   human's to do; guardtower is report-only and stops at the written report (a "proposed fix" is
   described, never applied).

## Track each facet as a todo

The fan-out is legible to the human only if they can see what was dispatched and what has come
back. The moment the facet set is fixed (after step 2), seed a todo list from it — **one todo per
selected facet, each seam its own item** — in whatever todo list your harness provides. A pick the
menu reported as unavailable never ran and never becomes a todo; a facet that will self-skip on its
own relevance gate still gets one, and closes when it returns "nothing to review."

Keep the list in lockstep with the dispatch:

- **`in_progress` as the facet is dispatched** — in fan-out that is several at once, one per
  reviewer in flight (step 3); inline it is one at a time as you work down the set.
- **`completed` the instant its result is in hand** (step 5), a
  self-skip included — so a facet that finished with nothing reads as done, never as still running.

Reconciliation is not a facet and takes no todo of its own; it is the step that consumes every
completed item at once.

## Governing principle

Keep the self-enforcement shape (workflow step 4) when changing a facet boundary or adding a facet:
a cap the orchestrator applies after a facet has already done unbounded work saves output, not the
work.

## What this does not do

- It does not **fix what it finds.** guardtower itself never edits code; the reconciled report is
  information a human (or a downstream tool they choose) acts on — applying a finding is someone
  else's job.
- It does not **decide when a review happens**, and it does not **stand in for sign-off.** A clean
  report is information a human uses to decide whether to merge, not a switch this skill throws; and
  what the findings do next is the human's call, not this skill's.
