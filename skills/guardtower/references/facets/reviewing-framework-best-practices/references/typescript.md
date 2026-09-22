# TypeScript — framework idiom checklist

The TypeScript lens for the framework best-practices facet. These are classes of defect specific
to how TypeScript's type system expects a change to be shaped — not the generic
reinvention/inefficiency classes the Technical facet already owns. The reach is the
diff: a pattern visible in the changed code, not a proactive audit of the whole codebase. Contents:

- Type-safety idioms
- Type-duplication idioms
- Generics idioms
- Enum vs. union-of-literals idioms
- What is not a finding

## Type-safety idioms

- **`any` reached for to silence a type error** rather than narrowing the actual type or fixing
  the real mismatch.
- **A non-null assertion (`!`) used where a real null check (or a type guard) is what the
  surrounding code actually needs.**
- **A type assertion (`as Foo`) used in place of narrowing** where the value's actual shape isn't
  guaranteed to match `Foo`.

## Type-duplication idioms

- **A new inline object type or interface hand-written that duplicates the shape of an existing
  exported type**, instead of reusing or extending it (`Pick`, `Omit`, `extends`).

## Generics idioms

- **A function accepting `any`/`unknown` and casting internally** where a generic parameter would
  preserve the caller's actual type all the way through the call.

## Enum vs. union-of-literals idioms

- **A new `enum` introduced in a codebase that has otherwise standardized on string-literal
  unions** (`type Status = 'open' | 'closed'`), or the reverse.

## What is not a finding

- A reinvention of an existing TypeScript/JavaScript capability with no type-system-specific
  placement/shape angle — the **Technical** facet's reuse lens owns reuse over reinvention generically.
- A generic inefficiency (an N+1 shape, an unbounded load) with nothing TypeScript-specific about
  it — the **Technical** facet already covers inefficient data access in the abstract.
- A pure stylistic preference between `interface` and `type` alias with no structural
  consequence — both express the same shape; picking one over the other is not a finding.
- A style/formatting preference with no correctness or maintainability consequence.
- A pre-existing pattern in a file the change doesn't touch — this facet reviews the diff, not
  the whole application.
- A departure from a rule here that matches an established, consistent convention already used
  elsewhere in the project — consistency with the existing codebase outranks a rule in this file.
