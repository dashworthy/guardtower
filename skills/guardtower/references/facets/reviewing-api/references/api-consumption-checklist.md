# API-consumption review checklist — over-fetch, over-call, filtering, rate limits

The Consumption lens of the API facet. Language- and framework-agnostic: these are classes of
defect to reason about in whatever stack the change is written in — a browser `fetch`, an
`axios` client, a react-query/SWR hook, a generated SDK, a backend service calling a
third-party HTTP API — not a rule table for one library. The examples are *illustrations* of a
shape, not targets for one framework. The reach is the diff plus the API client the change
already uses — **no proactive repo-wide scan**. Contents:

- Over-fetching payload
- Client-side work the API offers server-side
- Excessive call volume
- Rate-limit (429) safety
- What is not a finding

## Over-fetching payload

Requesting more than the caller actually reads:

- **Every field when a few are used** — fetching a full resource representation when the code
  reads two or three fields, where the API supports field selection (sparse fieldsets, a
  `fields=`/`select=` parameter, a narrower GraphQL selection set). Asking for all and using
  little is the finding.
- **Over-selecting in GraphQL** — a query that pulls nested objects or collections the render
  never touches.
- **Unbounded / unpaginated collection** — fetching an entire list into the client when only a
  page is shown, or when a count or an existence check is all the code needs. A missing
  `limit`/`per_page`/pagination cursor on a call that feeds a bounded view is the finding.

## Client-side work the API offers server-side

Pulling everything and then doing in the client what the API could do at the source:

- **Filtering** — fetching the whole collection and `.filter()`-ing it in memory when the API
  accepts a query/filter parameter.
- **Sorting** — ordering client-side after fetching all rows when the API accepts a `sort`/
  `order` parameter.
- **Searching** — scanning a fetched list for matches when the API exposes a search parameter.
- **Aggregating** — summing, counting, or grouping in the client over a full fetched set when
  the API can return the aggregate directly.

The shape is the same in each case: the network moved data the API could have withheld, and the
client redid work the server was ready to do.

## Excessive call volume

More requests than the work needs — the behaviour that both wastes bandwidth and drives toward
rate limits:

- **Redundant / duplicate calls** — the same request issued more than once for one logical
  need, where a single response could be reused.
- **No caching or dedup** — refetching data that has not changed, or firing concurrent
  identical requests with no in-flight dedup, when a cache or a shared promise would collapse
  them.
- **Request waterfalls** — dependent requests run strictly in series where they could be
  batched into one call or issued in parallel.
- **A call per item (N+1 over HTTP)** — a request inside a loop over a collection, where one
  batch/bulk endpoint or an `?ids=` parameter would replace N round-trips with one.
- **Over-aggressive polling or refetch** — a polling interval far tighter than the data
  changes, refetch-on-every-render, or a refetch with no backoff when the tab/view is idle or
  hidden.

## Rate-limit (429) safety

Both the behaviour that *causes* rate limiting and the handling that is missing *when* it
happens:

- **Cause — request storms** — the excessive-volume patterns above (per-item calls, tight
  polling, un-debounced user-driven bursts such as keystroke-per-request search) run enough
  volume at an endpoint to trip its limit.
- **Cause — no throttle / debounce** — a user-driven action that fires a request on every event
  (keystroke, scroll, resize) with no debounce or throttle guard.
- **Response — no retry with backoff** — a call that can be rate-limited with no retry, or a
  retry with a fixed/immediate delay rather than exponential backoff with jitter.
- **Response — ignoring `Retry-After`** — retrying a 429 without honouring the `Retry-After`
  header the server sent.
- **Response — retry storms** — every client retrying in lockstep with no jitter, or an
  unbounded retry loop that amplifies the overload it is reacting to.

## What is not a finding

Keep the floor honest — these belong to other facets, to another tool, or to no one:

- **Data-layer / database access** — an N+1 on an ORM, an unbounded SQL query, a query inside a
  loop against a database or cache. The **Technical** facet owns inefficient data access; the
  boundary here is **transport** — this facet is calls over the network only.
- **General error handling** — a swallowed exception, an empty catch, or a masking fallback
  that is not specifically about rate limiting. The **Error Handling** facet owns that; this
  lens owns only the 429-specific resilience (retry/backoff, `Retry-After`).
- **The API's own contract** — a breaking change, a removed field, a changed response shape.
  The API facet's **Compatibility** lens owns the contract; this lens judges only how the
  change consumes it.
- **A micro-optimization with no reasoned cost** on the change's actual path — below the
  confidence floor.
- **A pre-existing inefficiency the change neither introduces nor touches** — out of scope;
  review the diff, not the whole codebase.
