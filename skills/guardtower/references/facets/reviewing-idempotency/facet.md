# Reviewing — Idempotency & Retry Safety facet

Reviews the change for **a side-effecting operation that does the wrong thing when it runs more than
once**. Its concern is *safety under re-execution* alone, not the correctness of a single successful
run. Work [references/idempotency-checklist.md](references/idempotency-checklist.md), across the
diff-visible classes:

- **Side effect with no idempotency key** — a handler that creates, charges, or emits with no dedupe
  key, so a redelivery produces a second effect.
- **Non-idempotent retry** — a retry wrapper around an operation whose effect compounds on each
  attempt.
- **At-least-once treated as exactly-once** — a consumer of a queue, stream, or webhook that assumes
  each message arrives once, when the transport guarantees only at-least-once.
- **Duplicate on replay** — a create or POST-style operation with no natural or enforced uniqueness,
  so replaying the same request yields a duplicate record.
- **Partial-completion re-run** — a multi-effect operation with no checkpoint or guard, so a re-run
  after a mid-way failure redoes the effects that already succeeded.

**Relevance gate:** fires **only when the change performs a side effect that something can trigger
again** — a message or queue consumer, a webhook or callback handler, a retried job or task, an
outbound call or write that a client or infrastructure can replay (a payment, an email, a record
creation). A change with no repeatable side effect (a pure read, an in-memory computation, a
naturally idempotent write, config, docs) is out of scope.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md). When it fires, name what triggers the
repeat (a redelivery, a retry, a client replay) and the duplicated effect.

**Facet-specific boundaries:**
- Whether the operation is right when it runs exactly once belongs to another facet; this facet is
  safety under re-execution only.
- It does not **overlap the Concurrency facet** — two executions racing on shared state is a
  concurrency finding; the same operation *replayed* producing a second effect is this facet's. Name
  which one the finding is.
