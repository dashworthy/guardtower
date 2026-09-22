# Reviewing — Architectural facet

Reviews the change for the **structural defects a diff can actually show**. Work
[references/architectural-checklist.md](references/architectural-checklist.md), across the five
diff-visible classes:

- **Dependency-direction / coupling violation** — a new import that points the wrong way (a lower
  layer reaching up to a higher one) or crosses a boundary it should not.
- **Responsibility / cohesion creep** — an unrelated responsibility piled onto a module that already
  owns something else.
- **Duplicated abstraction** — a second way to do something the codebase already models.
- **Leaky abstraction** — a new interface that exposes its internals, forcing callers to know
  implementation detail.
- **Needless abstraction / single-use indirection** — a new method, class, or layer that only one
  call site reaches and that forwards a single call without a decision.

**Relevance gate:** fires **only when the change moves a boundary** — adds a new module, package, or
layer; introduces a new cross-module or cross-layer dependency; moves responsibility between modules;
or introduces a new abstraction or interface. A change entirely within one module's existing
responsibility (editing a function body, adding a field, fixing a bug in place) moves no boundary and
is out of scope.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md).

**Facet-specific boundary:** its reach is the boundaries the diff moves; it does not build a
dependency graph or grade the system the change never touches, and architecture the change neither
introduces nor worsens is not a finding.
