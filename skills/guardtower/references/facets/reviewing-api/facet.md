# Reviewing — API facet

Reviews a change that touches an API surface across two orthogonal lenses — providing a contract vs.
consuming one — so a given change usually engages just one; the relevance gate fires for either.
Each lens has its own checklist.

- **Compatibility lens** — breaking changes to a public contract the code *provides*. Work
  [references/api-compat-checklist.md](references/api-compat-checklist.md): a removed or renamed
  public member; a changed signature (parameters added/removed/reordered, types narrowed); a changed
  response shape or status code; a widened requirement (a narrowed accepted input, or a
  newly-required field callers could omit before); a changed wire/serialization format. It flags what
  **breaks** an existing contract — a new optional field or new endpoint is additive, not a finding.

- **Consumption lens** — defects in how the code *consumes* a remote/HTTP API it does not own. Work
  [references/api-consumption-checklist.md](references/api-consumption-checklist.md): over-fetching
  (requesting more than the caller reads; an unbounded/unpaginated collection); client-side work the
  API offers server-side (pulling everything then filtering/sorting/aggregating locally); excessive
  call volume (redundant calls, no caching/dedup, request waterfalls, a call per item — N+1 over
  HTTP, over-aggressive polling/refetch); rate-limit (429) safety, both the *cause* (request storms,
  per-item calls, no throttle/debounce) and the *response* (no retry with backoff, ignoring
  `Retry-After`, retry storms).

**Relevance gate:** fires when the change touches an API surface either way — a **public surface it
provides** (an exported/public symbol, a network endpoint, or a published schema/serialization
format), **or** it **consumes a remote/HTTP API it does not own** (a `fetch`/`axios`/SDK client call,
a request hook, a polling loop, or a request builder). Internal/private code only, pure local
computation, a data-layer/DB query, config, or docs is out of scope.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md).

**Facet-specific boundaries:**
- Data-layer / database access — N+1 on an ORM, unbounded SQL, a query in a loop — belongs to the
  **Technical** facet. The boundary is transport: Technical owns the data layer, the consumption lens
  owns calls over the network.
- General error handling — a swallowed exception or a masking fallback — belongs to the **Error
  Handling** facet; the consumption lens owns only the *rate-limit-specific* resilience of a 429.
