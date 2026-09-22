# Data & migration safety review checklist — the data-loss risks a diff can show

The lens for the data-safety facet. Language- and store-agnostic: these are classes of destructive
data operation to reason about in whatever the change is written in — SQL, an ORM migration, a
NoSQL bulk op, a data script — not a rule table for one database. Every class here is scoped to the
data operation the **diff** actually shows; this facet reasons about the statement in front of it and
does not scan the schema or trace which consumers depend on the data. Contents:

- Unbounded UPDATE/DELETE — the headline class
- Drop / rename of live data
- No rollback
- Non-idempotent migration
- Irreversible op with no guard
- What is not a finding

## Unbounded UPDATE/DELETE

A write with no bound on the rows it changes:

- A `DELETE` or `UPDATE` with **no `WHERE`**, so it affects every row in the table.
- A predicate that looks scoped but matches everything (a condition on a nullable column, a
  tautology, a bind variable that defaults to "all"). Say which statement and why its reach is the
  whole table, so the reviewer can confirm from the diff.

## Drop / rename of live data

A schema change that discards data currently in use:

- `DROP TABLE` / `DROP COLUMN` on something holding live data, with no archival or backfill step.
- A **rename** that a running deploy will read as a drop-then-missing (an old app version still
  querying the old name), or a type change that silently truncates. The loss is the point — name what
  data becomes unreachable.

## No rollback

A migration that cannot be undone:

- An `up`/forward step with **no matching `down`/rollback**, or a down step that does not actually
  restore what the up step destroyed (a down that recreates an empty column the up dropped with its
  data).
- Frameworks that auto-reverse only *some* operations: a destructive op the framework can't
  auto-reverse, left without a hand-written down.

## Non-idempotent migration

A migration that is unsafe to run more than once:

- Re-running it errors (a second `ADD COLUMN` of an existing column) and leaves the migration state
  half-applied.
- Re-running it **corrupts** — a backfill that adds a delta each run, a step that doubles or
  re-transforms already-migrated rows. A migration that can be interrupted and retried must converge
  to the same state; this one doesn't.

## Irreversible op with no guard

A destructive operation with nothing standing in front of it:

- A `TRUNCATE`, a bulk purge, or a file/blob deletion with no backup taken, no dry-run, no
  confirmation, no feature-flag or guard — so a mistake is unrecoverable.
- A one-way transform (hashing, re-encoding, dropping precision) applied in place over live data with
  no copy of the original retained.

## What is not a finding

Keep the floor honest — these belong elsewhere or to no one:

- A **reversible, bounded, idempotent migration** — it touches data, but safely; touching data is not
  itself a defect.
- A **destructive op on data the change itself just created** — dropping a scratch table the same
  migration made, clearing a cache the change populated — no live data is at risk.
- **Whole-schema concerns the diff doesn't touch** — an existing unbounded job elsewhere, a table the
  change never mentions. Out of reach by this facet's boundary, and an explicit non-goal.
