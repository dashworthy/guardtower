# Idempotency review checklist — the duplicate effects a diff can show

The lens for the idempotency facet. Language- and stack-agnostic: these are classes of retry-safety
defect to reason about in whatever the change is written in, not a rule table for one queue or framework.
Every class here is scoped to what the **diff** actually shows — a side effect the change adds or alters —
not every non-idempotent path in the system, which the diff does not show and this facet does not audit.
Contents:

- Side effect with no idempotency key — the headline class
- Non-idempotent retry
- At-least-once treated as exactly-once
- Duplicate on replay
- Partial-completion re-run
- What is not a finding

## Side effect with no idempotency key

A handler that produces an external effect — creates a record, charges a card, sends a message, calls a
downstream API — with **no key that would let a repeat be recognized and skipped**:

- A webhook or callback handler that acts on every delivery, when the provider retries deliveries and a
  second delivery of the same event repeats the effect.
- A consumer that processes each message for its effect with no dedupe on a message id or business key,
  so a redelivered message charges, ships, or emails twice.
- The tell is an irreversible or externally-visible effect with nothing that says "I have already done
  this one." Name the effect and what a second run does.

## Non-idempotent retry

A retry — in code, in a job runner, or in infrastructure — around an operation **whose effect compounds
per attempt**:

- A retry wrapper on an operation that emits a side effect *before* it can fail, so a transient failure
  that triggers a retry has already produced the first effect.
- A job marked for automatic retry that appends, increments, or sends each time it runs, so a retried
  transient error doubles the effect rather than completing the intended single one.

## At-least-once treated as exactly-once

Consuming a transport that guarantees **at-least-once** delivery as though each message arrives exactly
once:

- A queue, stream, or event consumer whose logic is correct only if every message is delivered once,
  when the broker's contract is at-least-once (the common default) and redelivery is expected on
  ack-timeout, rebalance, or crash-recovery.
- Treating "we received it" as "we received it once," with no idempotent handling of the redelivery the
  transport is allowed to make.

## Duplicate on replay

A create-style operation with **no natural or enforced uniqueness**, so replaying the same request
produces a duplicate:

- A POST/create endpoint that inserts a new row on every call with no unique constraint, idempotency
  token, or upsert, so a client's retry after a timed-out-but-succeeded request creates a second record.
- An "add" operation keyed only by an auto-generated id, so the same logical action taken twice is
  indistinguishable from two distinct actions.

## Partial-completion re-run

A multi-effect operation with **no checkpoint or per-step guard**, so a re-run after a mid-way failure
redoes the steps that already succeeded:

- Step A (charge) succeeds, step B (fulfil) fails; the whole operation is retried and step A charges
  again because nothing records that A was already done.
- A batch that processes items with side effects and, on re-run after a partial failure, reprocesses the
  items it already completed.

## What is not a finding

Keep the floor honest — these belong to other facets, to the whole-repo audit this facet refuses, or to
no one:

- **A naturally idempotent operation** — a PUT to a fixed key, a set-to-value, a delete-if-exists, or an
  upsert whose repeat lands the system in the same state. Running it twice changes nothing; not a
  finding.
- **An effect already keyed or deduped** — a unique constraint, an idempotency token the handler
  checks, or a processed-message ledger that already makes the repeat a no-op. Already safe.
- **A pure read or in-memory computation** — no external or persistent side effect, so repetition is
  free of consequence.
- **A concurrency race** — two executions interleaving on shared state is the concurrency facet's
  finding, not this one's; this facet is about the *same* operation running again, not two racing at
  once.
- **A pre-existing non-idempotent path the change doesn't touch** — this facet flags what the diff
  *introduces or alters*, not retry-unsafety it inherits unchanged. Out of reach by this facet's
  boundary.
