# Technical review checklist — efficiency, correctness

The Efficiency & correctness lens of the Technical facet. Language-agnostic: these are classes of defect to reason about in
whatever stack the change is written in, not a rule table for one framework. The reach is the diff
and a glance at the public surface of already-imported modules — **no proactive repo-wide scan**.
Reinvention of an existing capability is this facet's **other** lens (Reuse over reinvention,
`novelty-checklist.md`); flag it there, not in this checklist. Contents:

- Inefficient data access
- Correctness-scoped best practices
- What is not a finding

## Inefficient data access

Data access is where a small change quietly turns into a large cost. Look for:

- **N+1 queries** — a query issued once per element of a collection, where one batched query (a join,
  an `IN`, a preload/eager-load) would do.
- **Queries inside loops** — any round-trip to a database, cache, or service repeated per iteration.
- **Unbounded / unpaginated loads** — fetching an entire table or collection into memory when the
  change only needs a page, a count, or an existence check.
- **Repeated identical work** — the same query or computation run several times where one result could
  be reused within the request.

These are language- and store-agnostic: the shape (a round-trip per element, a full load where a
bounded one suffices) is the defect, whatever the query API.

## Correctness-scoped best practices

Only best-practice lapses with a **correctness or maintainability consequence** — never style:

- A resource opened and not reliably closed (file, connection, lock) on every path, including errors.
- Mutable shared state a concurrent caller could observe mid-update.
- An error-prone construct: an off-by-one boundary, an equality/identity confusion, a truthiness trap
  the language is known for, a silent numeric coercion.
- Reinvented control flow that a clearer, already-available construct expresses without the footgun.

## What is not a finding

Keep the floor honest — these belong to other facets, to a linter, or to no one:

- A style / formatting / naming preference with no correctness consequence — a linter owns it, or
  nobody does.
- A reinvention of an existing capability — this facet's Reuse-over-reinvention lens
  (`novelty-checklist.md`) owns it, not this efficiency/correctness checklist.
- A micro-optimization with no measured or reasoned cost on the change's actual path (below the
  confidence floor).
- A security or architectural concern — the Security or Architectural facet owns it, not this one.
- A pre-existing inefficiency the change neither introduces nor touches (out of scope — review the
  diff).
