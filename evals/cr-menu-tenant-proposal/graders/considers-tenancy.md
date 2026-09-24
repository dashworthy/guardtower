---
type: llm
weight: 2
focus: trace
arm: with-only
---

The repository is unmistakably multi-tenant: a `TenantContext` is injected, every query filters on `tenant_id`, and the change adds another `tenant_id`-scoped query. guardtower's upper (proposal) gate classifies the repo's tenancy at the repo level and, when multi-tenant, proposes the tenant-isolation lens — independently of whether this particular change leaks.

This grader measures the two-gate proposal, a repo-level judgement plain Claude does not make.

PASS if the review shows it recognised the repo as multi-tenant and considered/proposed the tenant-isolation lens — e.g. it selected or listed a tenant-isolation facet, reasoned about tenant scoping in its facet selection, or explicitly checked the new query for tenant scope. Concluding the new query is correctly tenant-scoped (no leak) still PASSES, because the point is that tenancy was considered.

FAIL if tenant isolation is never considered anywhere in the review — the reviewer treats it as an ordinary query with no awareness that the repo is multi-tenant.
