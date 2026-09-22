# Shared-DB tenant-isolation review checklist — the cross-tenant leaks a diff can show

The shared-DB lens of the Tenant-isolation facet. Scoped to the **single-database, shared-schema**
tenancy model: one physical database, many tenants in the same tables, told apart by a discriminator
column (`tenant_id`, `account_id`, `org_id`, or the like). In that model isolation is not a
connection boundary — it is a predicate every read and write must carry, so the whole failure mode is
*a query that forgot it*. Language- and ORM-agnostic: these are classes of missing-scope defect to
reason about in whatever the change is written in — raw SQL, a query builder, an ORM scope, a
repository method — not a rule table for one framework. Every class here is scoped to the query or
write the **diff** actually shows; this facet reasons about the statement in front of it and does not
crawl the schema or trace every call site to prove which tenant's rows are reachable. Contents:

- Missing tenant scope on a query — the headline class
- Global-scope bypass / raw query
- Cross-tenant reference by ID
- Mass-assignment of the tenant discriminator
- Cross-tenant aggregate / report
- Un-namespaced cache key
- What is not a finding

## Missing tenant scope on a query

A read or write against a tenant-scoped table with no tenant predicate constraining it:

- A `SELECT` / `UPDATE` / `DELETE` on a table that carries the discriminator, with **no
  `WHERE tenant_id = ?`** (or the equivalent scope the ORM would inject) — so it reads or mutates
  every tenant's rows, not the current tenant's.
- A finder that scopes by a natural key alone (`WHERE slug = ?`, `WHERE email = ?`) on a table where
  that key is unique only *within* a tenant, so it can resolve to another tenant's row. Name the
  statement and why its reach crosses the tenant boundary, so the reviewer can confirm from the diff.

## Global-scope bypass / raw query

A path that steps around the isolation the model normally enforces:

- A **raw query** (`DB::raw`, `EntityManager::createNativeQuery`, a hand-built SQL string) that skips
  the ORM's global tenant scope, so the default `WHERE tenant_id` is never applied.
- An explicit **`withoutGlobalScope`** / `unscoped()` / `allTenants()` escape hatch, or a query run on
  a connection/model configured without the tenant scope — used where the surrounding feature has no
  legitimate cross-tenant need. The bypass is the point; say which guarantee it removes.
- A tenant-scoped query run **outside request-scoped tenant context** — a queued job, console command,
  scheduled task, or webhook handler where the ambient current-tenant the global scope reads is unset,
  so an auto-injecting scope resolves to null or a stale tenant instead of the intended one. The diff
  shows the code, not the runtime context; flag it where the change adds a tenant-scoped query on such
  a path with no explicit tenant set first. This is the *implicit* sibling of the escape-hatch bypass:
  the scope isn't removed, it silently resolves wrong.

## Cross-tenant reference by ID

A write or association that trusts a caller-supplied ID without confirming it belongs to the tenant:

- A foreign key set from request input (`->category_id = $request->category_id`), or a lookup by
  primary key alone (`Model::find($id)`), with no check that the referenced row is in the current
  tenant — so tenant A can attach to, or read, tenant B's record by guessing an ID.
- An authorization check that verifies *a* row exists but not that it is *this tenant's* row.

## Mass-assignment of the tenant discriminator

A write that lets the caller set or move the tenant key:

- **Mass-assignment** of `tenant_id` (or the discriminator) from unfiltered request input — `create($request->all())`, an unguarded `fill()`, a serializer with no allow-list — so a caller can plant a
  record in, or migrate one to, another tenant.
- An update path that permits changing the discriminator on an existing row.

## Cross-tenant aggregate / report

A rollup that spans tenants where it should be scoped to one:

- A `COUNT`/`SUM`/`GROUP BY`, a report query, or an export that aggregates a tenant-scoped table with
  **no tenant predicate**, so one tenant's dashboard or export includes another tenant's data (or
  totals computed from it).
- A cross-tenant join where an intermediate table in the join is left unscoped.

## Un-namespaced cache key

A cache or memoization key that omits the tenant, so one tenant is served another's data:

- A **cache key** built from a resource identifier with no tenant component (`"user_{$id}"`,
  `"settings"`, `"nav_menu"`) on tenant-scoped data — a cache hit primed by tenant A is returned to
  tenant B. The store is not the schema, but the leak is the same shape: a lookup missing its tenant
  scope. Name the key and the shared entry.

## What is not a finding

Keep the floor honest — these belong elsewhere or to no one:

- A query on a **global / shared-reference table** that is deliberately not tenant-scoped (a country
  list, a currency table, a system settings row every tenant reads) — no discriminator, so no missing
  predicate.
- A query already scoped by an **enforced global scope** the diff relies on but does not restate —
  when the model's default scope provably injects the tenant predicate, an individual finder that
  doesn't repeat it is not a leak. Say so rather than flagging the absent literal `WHERE`.
- A **deliberate, authorized cross-tenant path** (a platform-admin console, a support-impersonation
  tool) whose cross-tenant reach is the intended feature and is gated by its own authorization.
- **Whole-schema concerns the diff doesn't touch** — an unscoped query elsewhere, a table the change
  never mentions. Out of reach by this facet's boundary, and an explicit non-goal.
