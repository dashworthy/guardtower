# Multi-tenancy signals — classifying a repo's tenancy model for the menu-proposal gate

This reference is how the orchestrator decides, **once per run at the repo level**, whether to
*propose* the single `reviewing-tenant-isolation` facet on the menu — and which of its two lenses it
applies. It is read and reasoned against by the agent; it is **not** a script, a grep list, or a
checklist to mechanically match. The goal is a single verdict about how the application isolates
tenants, so the facet applies the lens whose failure modes actually apply (or the facet isn't
proposed at all, when the app isn't multi-tenant).

This is the **repo-level** gate — the upper of code-review's two gates. It selects which facets appear
(and pre-checked); each facet then runs its own **per-change relevance gate** on the actual diff. A
facet proposed here can still skip itself on a change that touches no tenant-scoped surface.

## What to read

Judge from the codebase as it stands, not from the diff under review — tenancy is a property of the
application, not of one change. Look at persistence config, the ORM/model layer, middleware, and any
tenancy package in the dependency manifest. Weigh the signals; a single keyword is not a verdict.

## Shared-schema signals (→ shared)

The **single-database, shared-schema** model: every tenant's rows live in the same tables, told apart
by a discriminator column. Signals:

- A **discriminator column** recurring across tenant-owned tables — `tenant_id`, `account_id`,
  `org_id`, `company_id`, `workspace_id` — especially as a foreign key present on many tables and in
  many indexes.
- A **tenant global scope**, base model/repository, or default query constraint that injects the
  discriminator automatically, and/or middleware that sets a "current tenant" for the request.
- A tenancy package configured in **single-database mode** (e.g. a `tenant`/`company` scope trait, a
  single-connection multi-tenant library), with no per-tenant connection switching.
- **Row-level security** enforcing tenancy in the database itself — Postgres `RLS` policies (a
  `CREATE POLICY` / `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`) keyed on a per-session tenant
  setting. Still the shared-schema model: one database, rows separated by tenant, isolation enforced
  by a predicate — here pushed down into the engine rather than the application's queries.

## Per-tenant-DB signals (→ per-db)

The **database-per-tenant / schema-per-tenant** model: each tenant has its own database or schema, and
isolation is a **connection** boundary rather than a query predicate. Signals:

- **Per-tenant connection routing** — code that resolves and switches the database connection per
  tenant (a resolver/middleware, `->setConnection($tenant)`, a dynamically-configured `tenant`
  connection), rather than filtering by a column.
- A **multi-database tenancy package** (e.g. a package whose bootstrappers swap the connection,
  cache, and filesystem per tenant), or config describing a central/landlord database plus separate
  tenant databases.
- **Tenant-DB provisioning** — migrations run per-tenant, a tenants registry on a central connection,
  code that creates or migrates a database when a tenant is created.

## Classification — the verdict

Reason over the signals and emit exactly one verdict, consumed only by menu construction:

- **`shared`** — shared-schema signals dominate and no per-tenant connection switching is present.
  Propose the **tenant-isolation** facet, pre-checked, applying its **shared-DB lens**.
- **`per-db`** — per-tenant connection/database signals dominate. Propose the **tenant-isolation**
  facet, pre-checked, applying its **isolated-DB lens**.
- **`both`** — the app genuinely runs both models (e.g. shared-schema within each tenant database, or
  distinct subsystems using each). Propose the **tenant-isolation** facet, pre-checked, applying
  **both lenses**; it still self-skips per change.
- **`none`** — no credible multi-tenancy signal; the app is single-tenant. Do **not** propose the
  tenant-isolation facet — it doesn't appear on the menu.
- **`ambiguous`** — signals are mixed, weak, or conflicting and no model clearly dominates. The
  resolution is to **ask once**: put a single structured question to the human naming what was found
  (shared-schema vs per-tenant-DB vs single-tenant), using a tool to ask it where one is available,
  take the answer as the verdict, and do not
  re-ask within the run.

The verdict governs only *whether the tenant-isolation facet is proposed and pre-checked, and which
lens it applies*. It never runs the facet by itself, never suppresses a facet the human then
selects, and never overrides a facet's own per-change relevance gate. The frontend facet is
unrelated to this classification — it is opt-in and not tenancy-gated.
