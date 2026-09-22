# Reuse-over-reinvention checklist — reinventing what already exists

The Reuse-over-reinvention lens of the Technical facet. One question runs through all of it: *did the change reinvent a
capability the stack already provides?* Language- and framework-agnostic — these are classes of
defect to reason about in whatever stack the change is written in, described as shapes rather than as
targets for any one framework or library. The reach is the diff, model knowledge of the framework /
standard library / well-known libraries, and a glance at the public surface of the modules the change
already imports — **no proactive repo-wide scan**. Contents:

- Reinvented framework capability
- Reinvented standard-library primitive
- Reinvented library API
- Reinvented already-imported capability
- What is not a finding

## Reinvented framework capability

The framework in use already exposes, as a first-class feature, the thing the change hand-built:

- **A test that reimplements a framework helper** — hand-writing a test that shells out to, or
  reconstructs, a capability the framework already exposes a helper to invoke. The bespoke harness
  adds clutter and ends up testing the framework, not the change.
- **A reinvented framework idiom** — re-rolling a data-loading strategy the data layer already offers,
  a hand-written equivalent of a query/scope/validation/routing/event primitive the framework
  supplies first-class, or manual wiring the framework does for you.

## Reinvented standard-library primitive

Hand-rolling what the language's own built-ins already do correctly — dates, collections, strings,
math, I/O. Re-implementing a standard-library primitive (a manual collection de-dup, a hand-written
date diff, a bespoke string operation the language already provides) is a finding.

## Reinvented library API

Re-implementing the documented API of a library the project already depends on — a hand-written
version of a primitive the library exposes and the change could have called instead. Re-implementing
what a depended-on library already provides is a finding.

## Reinvented already-imported capability

The public surface of the modules *this change already imports or uses*. If the change writes a
private helper that duplicates a function it already imports, that is a finding — the capability is
one call away, already in scope.

## What is not a finding

Keep the floor honest — these belong to other facets, to a linter, or to no one:

- **Warranted novelty** — new code for a problem the stack does *not* already solve. Newness is not
  the defect; *duplication of an existing capability* is. When nothing already provides it, there is
  no finding.
- **A bespoke helper elsewhere in the repo the change does not import** — out of reach; chasing it
  would mean the repo-wide scan the boundary rules out. **No proactive repo-wide scan.**
- **Inefficient data access or a correctness lapse** — an N+1, an unbounded query, an off-by-one.
  The Technical facet's **Efficiency & correctness** lens owns those; this lens owns reuse over
  reinvention only.
- **A style / formatting / naming preference** with no correctness consequence — a linter owns it, or
  nobody does.
- **A trivially different reimplementation with a reasoned cause** — a genuine reason the existing
  capability does not fit (a documented edge case it mishandles, a needed behaviour it lacks) is a
  judgment call below the confidence floor, not a finding.
- **A pre-existing reinvention the change neither introduces nor touches** — out of scope; review the
  diff, not the whole codebase.
