# Reviewing — Tenant Isolation facet

Reviews the change in a multi-tenant app for **cross-tenant leaks** — one tenant reading, mutating,
or being served another's data. A multi-tenant app isolates tenants one of two ways, and the defect
classes differ by which. This facet carries **both lenses** and **branches on the deployment
topology** the orchestrator's step-1 tenancy verdict determined — the same verdict that proposes the
facet also selects the lens:

- **Shared-database lens** — a **single-database, shared-schema** app, where every tenant's rows share
  the same tables and are told apart by a discriminator column, so isolation is a `WHERE tenant_id`
  predicate. Selected on a `shared` (or `both`) verdict. Work
  [references/tenant-isolation-shared-db-checklist.md](references/tenant-isolation-shared-db-checklist.md):
  a missing tenant scope on a query; a global-scope bypass / raw query (`withoutGlobalScope`/
  `unscoped`); a cross-tenant reference by a caller-supplied ID; mass-assignment of the tenant
  discriminator; a cross-tenant aggregate/report/export; an un-namespaced cache key on tenant-scoped
  data.

- **Isolated-database lens** — a **database-per-tenant / schema-per-tenant** app, where each tenant
  has its own database and isolation is a connection boundary, not a query predicate. Selected on a
  `per-db` (or `both`) verdict. Work
  [references/tenant-isolation-isolated-db-checklist.md](references/tenant-isolation-isolated-db-checklist.md):
  a connection not switched for the operation; tenant context leaking across requests
  (singleton/container bleed); background/queued/scheduled work on the wrong connection; central/
  landlord vs. tenant DB confusion; a migration targeting the wrong DB set; a cross-cutting per-tenant
  store (cache, filesystem, session, queue) left keyed globally.

On a `both` verdict apply both lenses; on `shared`, only the shared-database lens; on `per-db`, only
the isolated-database lens. The two are mutually exclusive per statement, so the branch routes work,
it never doubles it.

**Relevance gate:** fires **only when two things hold at once** — the application is multi-tenant (the
topology the step-1 verdict named), *and* the change touches a tenant-scoped surface for that
topology (shared-database: a query/write/association/aggregate/cache of a table carrying the tenant
discriminator; isolated-database: a tenant-scoped query, a connection switch, a queued/scheduled/
background job over tenant data, or a migration). A single-tenant app, or a change touching only
global/shared-reference or central/landlord data, application logic, config, or docs, is out of scope.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md).

**Facet-specific boundary:** it does not **guess the topology** — the deployment model comes from the
step-1 tenancy verdict; this facet applies the lens that verdict selects. A deliberately global/
central path (a shared-reference table, an enforced global scope the diff relies on, an authorized
cross-tenant admin tool, an operation that resolves and switches the tenant connection first, or work
meant to run on the central/landlord DB) is not a finding.
