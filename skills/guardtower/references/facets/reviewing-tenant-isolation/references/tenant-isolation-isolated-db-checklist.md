# Isolated-DB tenant-isolation review checklist — the cross-tenant leaks a diff can show

The isolated-DB lens of the Tenant-isolation facet. Scoped to the **database-per-tenant /
schema-per-tenant** tenancy model: each tenant's data lives in its own database (or its own schema),
and isolation is a **connection boundary**, not a query predicate. In that model a `WHERE tenant_id`
is not the guard — the guard is *which database connection the operation runs on*, so the whole
failure mode is *an operation that ran against the wrong connection*, or *tenant context that never
got established or bled from another request*. Language- and framework-agnostic: these are classes of
wrong-connection / wrong-context defect to reason about in whatever the change is written in — a
connection resolver, a tenancy package, a manual `->on('tenant')`, a raw PDO handle — not a rule
table for one framework. Every class here is scoped to the operation the **diff** actually shows;
this facet reasons about the code in front of it and does not trace the whole request lifecycle or
the container's binding graph to prove which connection is live at runtime. Contents:

- Connection not switched for the operation — the headline class
- Tenant context leaking across requests
- Background / queued / scheduled work on the wrong connection
- Central / landlord vs. tenant DB confusion
- Migration targeting the wrong DB set
- Cross-cutting per-tenant store not switched
- What is not a finding

## Connection not switched for the operation

A tenant-scoped read or write that runs before the tenant connection is resolved and switched:

- A query or model operation on tenant data with **no preceding connection switch** — the tenancy
  package's `initialize`/`makeCurrent`, a `->setConnection($tenant)`, a resolver call — so it runs on
  whatever connection is currently active (often the default/central one) instead of the tenant's.
- A **hardcoded connection** (`->connection('mysql')`, a fixed DSN) on a tenant-scoped operation, so
  it can never reach the right tenant's database. Name the operation and why its connection is not the
  intended tenant's, so the reviewer can confirm from the diff.
- A switch to the **wrong tenant** — tenant resolution driven by a caller-controlled subdomain,
  header, or parameter that is trusted without verifying the authenticated principal may act for that
  tenant, so an attacker selects a victim's database. The isolation leak (operating on the wrong
  tenant's DB) is this facet's; flag it here. The underlying trust-unverified-input smell is the
  security facet's to name — cross-reference, don't re-litigate it.

## Tenant context leaking across requests

Tenant state established for one request that persists into the next tenant's:

- A resolved tenant connection, tenant id, or tenant model cached in a **long-lived singleton**,
  static property, or container binding that is not reset between requests/tenants — so request B,
  for a different tenant, is served on request A's connection (singleton / container bleed).
- A connection registered under a **reused name** (`config(['database.connections.tenant' => …])`)
  that a later tenant inherits because it was never purged. The leak is temporal — say which state
  outlives the request that set it.

## Background / queued / scheduled work on the wrong connection

Deferred work that runs without the originating tenant's connection:

- A **queued job**, listener, scheduled command, or webhook handler that touches tenant data but does
  **not** carry and re-establish the tenant context — dispatched without the tenant identity
  serialized, or handled on the default/central connection because no switch runs in the worker.
- A job that captures a live **connection object** at dispatch time (rather than the tenant's
  identity) and reuses it after it has moved on to another tenant. Background work is the classic
  isolated-DB leak: the ambient tenant that existed at dispatch is gone by execution.

## Central / landlord vs. tenant DB confusion

A model or query bound to the wrong side of the central/tenant split:

- A model that belongs on the **central / landlord** database (tenants registry, plans, global
  users) queried on the **tenant** connection, or a tenant-scoped model queried on the central
  connection — so it reads an empty or wrong dataset, or writes tenant data into the shared DB.
- A relationship or query that **binds across the central/tenant split as if both sides shared one
  database** — a tenant model reaching a landlord table (or the reverse) on a single connection when
  the two live in different databases. The isolation smell is the mistaken binding, not the join's
  correctness. Name which binding is inverted.

## Migration targeting the wrong DB set

A schema change applied to the wrong database population:

- A **migration** placed so it runs against the **central** database when it should run per-tenant
  (a tenant table created only once, in the landlord DB), or against **each tenant** when it belongs
  centrally — so tenant schemas drift from the code that queries them.
- A seeder or data backfill that iterates the wrong connection set, or forgets to loop tenants at
  all. The loss is a schema/data mismatch — say which population is missed.

## Cross-cutting per-tenant store not switched

A non-database store that must be isolated per tenant alongside the connection, but isn't:

- A **cache key**, filesystem path, session store, or queue that a per-tenant deployment isolates
  through its tenancy bootstrappers (cache prefix, disk root, connection name) but which the change
  leaves keyed or rooted globally — so tenant A's cached value, uploaded file, or queued payload is
  served to or overwritten by tenant B. In this model isolation is broader than the DB connection:
  the same bootstrap that switches the connection also switches these stores, and a store that
  doesn't move with the tenant is the same wrong-context leak one layer out.
- Name the store and why its key/path/name lacks the tenant component the switch would supply.

## What is not a finding

Keep the floor honest — these belong elsewhere or to no one:

- An operation that **correctly resolves and switches** the tenant connection first (or runs inside a
  tenancy-package scope the diff relies on and shows) — the connection boundary is honored, so no
  leak.
- Work on the **central / landlord database that is meant to be central** — a query against the
  tenants registry, global config, or a shared reference table run on the central connection on
  purpose is not a finding just because it isn't tenant-scoped.
- A **deliberate, authorized cross-tenant path** (a provisioning routine, a platform-admin console)
  whose reach across tenant databases is the intended, gated feature.
- **Lifecycle concerns the diff doesn't touch** — an existing job elsewhere, a container binding the
  change never mentions. Out of reach by this facet's boundary, and an explicit non-goal.
