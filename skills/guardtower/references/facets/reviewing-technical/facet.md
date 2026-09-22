# Reviewing — Technical facet

Reviews the change for technical defects across two lenses that share one reach and one relevance
gate and run as a single dispatched reviewer. The cap spans both lenses.

- **Efficiency & correctness lens.** Work
  [references/technical-checklist.md](references/technical-checklist.md): inefficient data access —
  N+1 patterns, queries inside loops, unbounded or unpaginated loads, repeated identical queries; and
  correctness-scoped best practices — only defects with a correctness or maintainability consequence,
  never style.

- **Reuse over reinvention lens.** Work
  [references/novelty-checklist.md](references/novelty-checklist.md): new code that rebuilds a
  capability the stack already provides. For each capability the change *newly introduces*, ask
  whether something already provides it — a **framework idiom**, a **standard-library** built-in, a
  documented API of a **well-known/depended-on library**, or the public surface of an
  **already-imported module** the change duplicates with a private helper. Name what was reinvented
  and what already provides it. The finding is *duplication of an existing capability*, never newness
  for its own sake.

**Relevance gate:** fires when the change contains logic worth a technical review — new or changed
functions, data-access code, loops over collections, comparison/date/string handling, non-trivial
computation, hand-rolled utilities, or framework wiring that could duplicate an existing capability. A
pure config, docs, or formatting change, or a trivial constant edit, is out of scope.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md). Its reach is the diff plus already-imported
modules and the reviewer's knowledge of the framework and well-known libraries — no function index.

**Facet-specific boundary:** stack-specific idiom placement/shape — a reinvention whose real angle is
where or how it sits within a detected framework's conventions — is the **Framework Best Practices**
facet's; this facet owns generic reuse and generic efficiency/correctness, not stack-specific idiom.
