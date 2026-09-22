# Reviewing — Concurrency & Race Safety facet

Reviews the change for **state that two executions can corrupt when they interleave**. Its concern is
*unsafe interleaving of concurrent executions* alone, not general correctness of single-threaded
logic. Work [references/concurrency-checklist.md](references/concurrency-checklist.md), across the
diff-visible classes:

- **Check-then-act (TOCTOU)** — a value is read or checked, then acted on as if unchanged, with a
  window in which another execution can invalidate it between the two.
- **Non-atomic read-modify-write** — a read, a modification, and a write-back another execution can
  interleave, so an update is computed from stale state.
- **Lost update on shared state** — an unguarded increment, append, or accumulation into a shared
  counter, balance, or collection, where concurrent writers overwrite each other.
- **Missing lock or transaction on a compound operation** — a multi-step operation that must be
  all-or-nothing relative to other executions but runs with no enclosing lock, transaction, or atomic
  primitive.
- **Shared mutable state without synchronization** — a field, singleton, or container mutated across
  concurrent requests or threads with no guard, so readers observe torn or inconsistent state.

**Relevance gate:** fires **only when the change can be reached by more than one execution at once** —
it touches shared mutable state (a static/global, a cache, a row other requests also write), a
concurrent or async handler, a background job or message consumer, or a locking/transaction
primitive. A purely sequential, single-owner change (a pure computation, request-local state, config,
docs) is out of scope.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md). When it fires, name the two executions and
the state they corrupt, so the interleaving is legible without rerunning the reasoning.

**Facet-specific boundaries:**
- A logic bug that needs no second execution to manifest belongs to another facet; this facet is
  unsafe interleaving only.
- It does not **demand a specific primitive** — which lock, queue, or CAS to use is a direction at
  most; it flags the unsafe interleaving, not a preferred synchronization style.
- The same operation *replayed* producing a second effect is the **Idempotency** facet's; two
  executions racing on shared state is this facet's.
