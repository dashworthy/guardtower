# Concurrency review checklist — the races a diff can show

The lens for the concurrency facet. Language- and stack-agnostic: these are classes of
interleaving defect to reason about in whatever the change is written in, not a rule table for one
runtime's threading model. Every class here is scoped to what the **diff** actually shows — concurrency
the change adds or alters — not every pre-existing race in the system, which the diff does not show and
this facet does not audit. Contents:

- Check-then-act (TOCTOU) — the headline class
- Non-atomic read-modify-write
- Lost update on shared state
- Missing lock or transaction on a compound operation
- Shared mutable state without synchronization
- What is not a finding

## Check-then-act (TOCTOU)

A value is **read or checked**, then **acted on** as though it had not changed, with a window between
the two that another execution can slip through:

- "Does this record exist? No — create it." Two requests both read *absent* and both create, so the
  guard the check was supposed to provide never held.
- "Is there capacity / stock / balance? Yes — consume it." Two requests both see *available* and both
  consume, overrunning the limit.
- The tell is a **gap** between the observation and the action on it, over state something else can
  write. Name the check, the action, and what another execution does in the gap.

## Non-atomic read-modify-write

A **read**, a **modification**, and a **write-back** that are three separate steps another execution can
interleave, so the write is computed from state that is already stale:

- `x = read(); x = f(x); write(x)` on shared state, where a concurrent writer's update between the read
  and the write is silently overwritten.
- The compound is not a single atomic operation, and nothing serializes the three steps against other
  writers.

## Lost update on shared state

A write into shared state that concurrent writers **overwrite each other on**, because the accumulation
is not atomic:

- An unguarded `count += 1`, `total += amount`, or list append into a shared counter, balance, or
  collection — two increments land as one.
- Aggregation into a shared map or accumulator with no per-key atomicity, so entries clobber one another.
- Distinct from the read-modify-write case by intent: here the operation *looks* like a single update in
  the source but is not atomic underneath.

## Missing lock or transaction on a compound operation

A multi-step operation that must be **all-or-nothing relative to other executions** but runs with no
enclosing guard:

- Two or more state changes that must commit together (debit one account, credit another) with no
  transaction, so another execution can observe or act on the half-done state.
- A critical section entered with no lock, semaphore, or atomic primitive where the invariant depends on
  mutual exclusion.
- Name the invariant that a concurrent execution can catch broken.

## Shared mutable state without synchronization

State reachable by more than one execution, **mutated with no guard**:

- A mutable field on a singleton, a shared container, or a module-level variable written across
  concurrent requests or threads, so a reader observes a torn or partially-updated value.
- Request or tenant context stored somewhere shared and mutated per request, so concurrent requests read
  each other's context. (A cross-*tenant* leak from this is a tenant-isolation finding; the race itself
  is this facet's.)

## What is not a finding

Keep the floor honest — these belong to other facets, to the whole-repo audit this facet refuses, or to
no one:

- **State reached by one execution at a time** — request-local or stack-local values, immutable data,
  or state a single owner serializes. No second execution can interleave; there is no race.
- **An operation already atomic or guarded** — a database transaction, an existing lock or mutex, a
  compare-and-swap, or an atomic type that already serializes the steps. Already safe is not a finding.
- **A single-threaded logic bug** — a defect that manifests with no concurrent execution at all belongs
  to a correctness/technical review, not here.
- **A preferred-primitive nit** — that a different lock, queue, or lock-free structure would be tidier,
  when the code is already correct under concurrency. No interleaving corrupts state; that is style.
- **A pre-existing race the change doesn't touch** — this facet flags what the diff *introduces or
  alters*, not a race it inherits unchanged. Out of reach by this facet's boundary.
