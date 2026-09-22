# API & backward-compatibility review checklist — the breaking changes a diff can show

The Compatibility lens of the API facet. Language- and protocol-agnostic: these are classes of
contract-breaking change to reason about in whatever the change is written in — a library's exported
functions, an HTTP/RPC endpoint, a message or file schema — not a rule table for one framework. Every
class here is scoped to the contract change the **diff** actually shows; this lens reasons about the
surface the change alters and does not scan the repo for every consumer. Contents:

- Removed or renamed public member — the headline class
- Changed signature
- Changed response
- Widened requirement
- Changed serialization
- What is not a finding

## Removed or renamed public member

A public name a caller depends on that disappears or moves:

- A public function, method, type, field, constant, or endpoint **deleted** — every caller breaks at
  once.
- A **rename** with no alias/deprecation kept behind the old name — the old name is gone, so the
  rename is a removal plus an addition from the caller's side. Name the old identifier, so the
  reviewer sees exactly what callers referenced.

## Changed signature

A public callable whose shape changes under existing callers:

- A parameter **added as required**, **removed**, or **reordered**, so an existing call site no longer
  compiles or now passes the wrong argument positionally.
- A parameter or return **type narrowed** (accepts less than before, or returns a subtype callers
  can't use where the old type worked). Widening is usually safe; narrowing breaks.

## Changed response

A response contract that shifts under existing clients:

- A **field removed or renamed** in a returned object, or its **type changed**, so a client parsing
  the old shape fails or silently misreads.
- A **status code / result code** changed for the same condition (a `200` that becomes a `204`, a
  success sentinel that changes value), so clients branching on it take the wrong path.

## Widened requirement

The change demands more of the caller than before:

- An input constraint **tightened** — a field that accepted null/empty now rejects it, a range or
  format narrowed — so inputs that used to be valid now fail.
- A **newly-required field** (a request parameter, a config key, a constructor argument) that callers
  could previously omit, so existing callers that don't supply it break.

## Changed serialization

The wire or on-disk format changes incompatibly:

- A field's **encoding, units, or format** changed (seconds→millis, a string date format, an enum's
  string values) without a version bump, so an old peer misreads the new bytes.
- A **structural change** to a persisted or transmitted format (a moved key, a flattened/nested
  object, a changed delimiter) that a consumer reading the old layout cannot parse.

## What is not a finding

Keep the floor honest — these belong elsewhere or to no one:

- An **additive, backward-compatible change** — a new optional field, a new endpoint, a new overload
  that leaves the old one intact. Callers keep working; nothing breaks.
- A **change to clearly-internal / private code** — a private helper, an underscore-prefixed or
  package-private name, an implementation detail no documented contract exposes. Out of scope by the
  relevance gate.
- A **documented, versioned breaking change the change itself declares** — a major-version bump with
  a migration note, a deprecation the change is completing on schedule. The break is intentional and
  on the record.
- **Consumers outside the diff** — chasing every caller across the repo is out of reach by this
  lens's boundary; reason about the contract change itself.
