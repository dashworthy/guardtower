# React — framework idiom checklist

The standalone-React lens for the framework best-practices facet. This covers React itself —
component and hook idioms — not Inertia's page-navigation conventions, which already live in
`laravel.md`'s own Inertia-specific section and stay there untouched. The reach is the diff: a
pattern visible in the changed code, not a proactive audit of the whole application. Contents:

- Hook idioms
- State management idioms
- List/key idioms
- Side-effect idioms
- Memoization idioms
- What is not a finding

## Hook idioms

- **A `useEffect` dependency array missing a value the effect body actually reads.**
- **Derived state computed via `useEffect` + `useState`** where a plain expression evaluated
  during render already produces the same value.

## State management idioms

- **State prop-drilled through several layers with no layer actually using it**, where the
  codebase already has an established Context (or store) pattern for the same kind of
  cross-cutting value.
- **A state object mutated directly** (`state.items.push(x)`, `state.field = y`) instead of
  replaced with a new reference.

## List/key idioms

- **An array index used as a list `key`** on a list that can reorder, filter, or have items
  inserted/removed from the middle.

## Side-effect idioms

- **A `fetch` or subscription started in `useEffect` with no cleanup/abort returned.**

## Memoization idioms

- **`React.memo`, `useMemo`, or `useCallback` reached for with no actual expensive computation or
  referential-equality problem it's solving.**

## What is not a finding

- A reinvention of an existing React capability with no React-specific placement/shape angle —
  the **Technical** facet's reuse lens owns reuse over reinvention generically.
- A generic inefficiency (an N+1 shape, an unbounded load) with nothing React-specific about it —
  the **Technical** facet already covers inefficient data access in the abstract.
- Inertia's own page-navigation and page-prop conventions (`router.visit`, shared data, page
  component resolution) — those are `laravel.md`'s Inertia-specific section's job, not this file's;
  a React-in-Inertia app still gets this file's component/hook idioms reviewed, but the
  navigation layer belongs to the other file.
- A style/formatting preference with no correctness or maintainability consequence.
- A pre-existing pattern in a file the change doesn't touch — this facet reviews the diff, not
  the whole application.
- A departure from a rule here that matches an established, consistent convention already used
  elsewhere in the project — consistency with the existing codebase outranks a rule in this file.
