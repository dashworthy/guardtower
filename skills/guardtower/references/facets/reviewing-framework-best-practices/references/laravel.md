# Laravel — framework idiom checklist

The Laravel lens for the framework best-practices facet. These are classes of defect specific to
how Laravel expects an application to be shaped — not the generic reinvention/inefficiency
classes the Technical facet already owns. The reach is the diff: a pattern visible in
the changed code, not a proactive audit of the whole application. Adapted from this shop's own
Laravel Boost-derived guidance (`laravel-best-practices`, `pest-testing`,
`inertia-react-development`). Contents:

- Validation & authorization placement
- Eloquent & query-shape idioms
- Queue, cache & scheduling safety
- Testing conventions (Pest)
- Inertia/React page conventions
- Config, error handling & mail/event idioms
- What is not a finding

## Validation & authorization placement

Laravel gives validation and authorization dedicated homes; logic that bypasses them is harder to
reuse, test, and audit.

- **Inline validation instead of a Form Request** — `$request->validate([...])` or manual rule
  arrays inside a controller method, where a dedicated Form Request class already exists for the
  route or would obviously belong there.
- **`$request->all()` (or an unvalidated array) reaching a mass-assignment call** — `Model::create()`
  / `fill()` / `update()` fed unvalidated input instead of `$request->validated()`.
- **Authorization checked ad hoc instead of via an existing Policy** — a hand-rolled comparison
  (`if ($user->id !== $post->user_id)`) reimplementing what a Policy already registered for that
  model already expresses. Whether authorization is enforced *at all* is the Security facet's
  question; this is narrower — the mechanism exists and the change bypasses it.
- **Business logic inline in a controller method that already has an Action/service class
  elsewhere in the app** — the project has an established Action/service pattern and this change
  reverts to putting the logic straight in the controller instead.

## Eloquent & query-shape idioms

- **N+1 via unguarded lazy access** — a relationship accessed inside a loop with no `with()` /
  `load()` on the parent query, and no `Model::preventLazyLoading()` guard already covering it.
- **Hardcoded table name in a raw query, join, or `DB::table()` call** where the model (and its
  `getTable()`) already exists. (Not a finding inside a migration — hardcoded names there are the
  accepted, frozen-snapshot convention.)
- **A hand-rolled query duplicating a scope that already exists** on the model, or the same
  multi-line constraint repeated at more than one call site where a local scope would collect it.
- **`whereRaw`/`DB::select` reached for where Eloquent's query builder already expresses the same
  constraint safely** — an idiom question (parameter-bound Eloquent was available and skipped), not
  whether the raw call is itself injectable; unsafe interpolation into a raw query is the
  **Security** facet's A03 Injection finding, not this one.
- **No `ORDER BY`/`latest()` on a query the code (or its tests) depends on returning a stable
  order.**

## Queue, cache & scheduling safety

- **A queued job with no `failed()` method and no other explicit failure handling.**
- **A unique/rate-sensitive job missing `ShouldBeUnique` (or `ShouldBeUniqueUntilProcessing`)**
  where the change's own description or tests imply duplicate dispatch would cause a problem
  (double-charging, double-sending).
- **`retry_after` not set longer than the job's `timeout`** where both are visible in the diff.
- **A scheduled command with variable/unbounded duration and no `withoutOverlapping()`.**
- **Manual cache get/put instead of `Cache::remember()`**, or a check-then-write against a cache
  key with no `Cache::add()`/`Cache::lock()`.
- **A write path that should invalidate a cached value and doesn't** — a cache key populated
  elsewhere in the same flow that the change's write path leaves stale.

## Testing conventions (Pest)

- **PHPUnit-style test structure in a project whose existing tests use Pest** — `extends TestCase`
  with `public function test...()` methods alongside sibling files using `test()`/`it()`.
- **Raw database assertions instead of model assertions** — `assertDatabaseHas()` where
  `assertModelExists()`/`assertModelMissing()` says the same thing more directly.
- **`Event::fake()` called before factory setup** — silences the model events (e.g. UUID
  generation on `creating`) that the factories in the same test depend on.
- **`Mail::assertSent()` / `Notification::assertSent()` used on a class that implements
  `ShouldQueue`** — the queued form needs `assertQueued()`.
- **A real HTTP call reaching a test** with no `Http::fake()`/`Http::preventStrayRequests()`.

## Inertia/React page conventions

- **A plain `<a href>` used for in-app navigation** instead of Inertia's `<Link>`.
- **A raw `<form>` submitted without `e.preventDefault()`**, in a codebase where the `<Form>`
  component or `useForm()` is the established pattern for forms.
- **A manual `fetch`/`axios` call to the app's own backend** where `router.visit()` / the `<Form>`
  component / `useForm()` already does the same job with Inertia's request lifecycle
  (`onSuccess`/`onError`/progress) wired in.
- **A deferred prop rendered with no loading state and no `undefined` check.**

## Config, error handling & mail/event idioms

- **`env()` called outside a `config/*.php` file** — returns `null` once config is cached in
  production; `config()` is the only call site `env()` should feed.
- **A magic string/status literal compared inline** where the model already defines a constant for
  it (`self::TYPE_NORMAL` etc.) and the change reintroduces the bare string.
- **A query executed inside a Blade template** (`@foreach (Model::all() as ...)`) instead of being
  passed in from the controller.
- **A Mailable/Notification with no `ShouldQueue`** where the surrounding code (or the rest of the
  class's siblings) treats mail/notifications as always-queued, or a queued one dispatched inside
  a DB transaction with no `afterCommit()`/`ShouldDispatchAfterCommit`.
- **An outbound `Http::` call with no timeout** — the 30-second default is rarely the intended
  budget for a synchronous request in the middle of a controller action.

## What is not a finding

- A reinvention of an existing Laravel capability with no Laravel-specific placement/shape angle —
  the **Technical** facet's reuse lens owns reuse over reinvention generically; this facet's job is idiom
  placement and shape, not "did we reinvent the wheel."
- A generic inefficiency (an N+1 shape, an unbounded load) with nothing Laravel-specific about
  it — the **Technical** facet already covers inefficient data access in the abstract.
- Whether authorization or output escaping is present *at all*, or whether user input reaches an
  interpreter unparameterized — those are the **Security** facet's OWASP-class findings (A01
  Broken Access Control, A03 Injection). This facet's authorization/query bullets above are
  narrower: is the *established Laravel mechanism* being used, not whether protection exists.
- A style/formatting preference (array vs. string validation-rule notation, `each()` vs. a
  higher-order message) with no correctness or maintainability consequence.
- A pre-existing pattern in the file the change doesn't touch — this facet reviews the diff, not
  the whole application.
- A departure from a rule here that matches an established, consistent convention already used
  elsewhere in the project — consistency with the existing codebase outranks a rule in this file.
