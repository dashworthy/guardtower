# guardtower

Standalone, in-depth, **opt-in** code review for Claude Code.

Point it at a change — a diff, a branch, or a PR — and it lets you pick which review **facets** to
run (security, concurrency, data-safety, API compatibility, and more), dispatches each as an
independent, self-limiting reviewer, and reconciles everything into **one markdown report**. It is
**report-only**: it tells you what each facet found and never edits your code.

This is the heavier, deliberate review — not an everyday pass and not an automatic gate. Someone
decides a change is worth a deep look and runs it.

## Install

```
/plugin marketplace add dashworthy/guardtower
/plugin install guardtower@guardtower
```

guardtower depends on no other plugin.

## Use

Invoke the skill:

```
/guardtower:guardtower
```

It accepts two optional arguments, in either order:

- **effort** — `low` | `medium` | `high` | `max` (default `medium`). One dial trading breadth for
  signal: `low` returns only the strongest findings per facet; `max` is the widest pass.
- **target** — what to review: a PR/MR link or number, a branch, a diff, or a path. Omitted, it
  reviews the working diff / current branch. A PR target is what makes posting findings back
  possible where a facet supports it.

Example:

```
/guardtower:guardtower high #142
```

## What you get

A single reconciled markdown report: the findings across every selected facet, deduplicated and
ordered, each with its location, what's wrong, and why. Where a facet's cap held findings back, the
report says how many wait behind it so you know to re-run.

## The facets

Fourteen lenses, each defined under `skills/guardtower/references/facets/`: security, technical
(efficiency/correctness + reuse), architectural, readability, error-handling, test-quality,
data-safety, API (compatibility + consumption), concurrency, idempotency, numeric-precision,
tenant-isolation, frontend (a11y/i18n/data-presentation), and framework-best-practices. Eight run on
every change; the rest are proposed when the change (or the repo's stack/tenancy) makes them
relevant.

## License

MIT © Andrew Leach
