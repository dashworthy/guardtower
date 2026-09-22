# Reviewing — Data & Migration Safety facet

Reviews the change for **destructive or irreversible data operations** — an unbounded write, a drop
of live data, a migration that cannot be rolled back or safely re-run. Work
[references/data-safety-checklist.md](references/data-safety-checklist.md), across the diff-visible
classes:

- **Unbounded UPDATE/DELETE** — no `WHERE`, or a predicate that affects all rows.
- **Drop / rename of live data** — a column or table holding live data dropped or renamed with no
  preservation path.
- **No rollback** — a migration with no down / rollback path.
- **Non-idempotent migration** — one that fails or corrupts if re-run (not reentrant).
- **Irreversible op with no guard** — a destructive operation with no backup, guard, or confirmation.

**Relevance gate:** fires **only when the change touches data at rest** — a migration, a schema
change, or a bulk data operation (a mass `UPDATE`/`DELETE`, a backfill, a drop). Application logic,
config, docs, a read-only query, or a single-row write in normal code is out of scope.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md).

**Facet-specific boundary:** it reasons about the data operation visible in the diff and does **no**
data-flow graph or table-usage scan to prove which rows a statement touches or who else reads the
data; what the diff does not show is an accepted blind spot. A bounded, reversible, idempotent
migration is not a finding just because it touches data.
