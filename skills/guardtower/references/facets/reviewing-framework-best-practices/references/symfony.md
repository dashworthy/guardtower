# Symfony — framework idiom checklist

The generic-Symfony lens for the framework best-practices facet. These are classes of defect
specific to how Symfony expects an application to be shaped — not the generic
reinvention/inefficiency classes the Technical facet already owns, and not the
Oro-platform-specific idioms `orocommerce.md` owns for an OroCommerce app built on top of Symfony.
The reach is the diff: a pattern visible in the changed code, not a proactive audit of the whole
application. Contents:

- Dependency injection & service configuration
- Controller, routing & authorization idioms
- Doctrine ORM & query-shape idioms
- Validation & Form idioms
- Event system idioms
- Console commands & Messenger idioms
- Config & environment idioms
- What is not a finding

## Dependency injection & service configuration

Symfony's container exists so a class declares what it needs and the framework wires it in;
reaching around that is harder to test and swap.

- **A service manually `new`'d where it would already be autowired** — a controller or another
  service constructing a collaborator directly instead of declaring it as a constructor argument
  and letting the container inject it.
- **A service locator (`ContainerInterface::get()`) reached for where a typed constructor argument
  already resolves the same collaborator.**
- **A tagged-service consumer built by hand** (manually collecting a set of implementations)
  where the change's own class already sits in a `services.yaml` tag group a compiler pass or
  `#[AutowireIterator]` could inject directly.

## Controller, routing & authorization idioms

- **Authorization checked ad hoc instead of via an existing Voter** — a hand-rolled comparison
  (`if ($user !== $post->getOwner())`) reimplementing what a Voter already registered for that
  resource already expresses via `#[IsGranted]` / `AuthorizationCheckerInterface::isGranted()`.
  Whether authorization is enforced *at all* is the Security facet's question; this is narrower —
  the mechanism exists and the change bypasses it.
- **Business logic inline in a controller action** where the project has an established
  service/handler pattern elsewhere for the same kind of operation.
- **Routing declared inconsistently** — a new route added as a YAML/PHP config entry in a
  codebase whose other routes use `#[Route]` attributes, or the reverse.
- **A controller returning a `Response` built by hand** for JSON where the project already uses
  `JsonResponse`/a serializer consistently elsewhere for the same kind of endpoint.

## Doctrine ORM & query-shape idioms

- **N+1 via unguarded lazy association access** — an association traversed inside a loop with no
  `JOIN`/`fetch: EAGER` on the originating query and no batch-fetch already covering it.
- **A hand-rolled DQL or native query duplicating what the entity's own repository method already
  expresses** — a repeated multi-line `createQueryBuilder()` constraint at more than one call
  site where a named repository method would collect it.
- **`EntityManager::getRepository()` called ad hoc through business code** instead of an injected,
  typed repository.
- **No explicit ordering on a query the code (or its tests) depends on returning a stable
  order.**

## Validation & Form idioms

- **Manual validation logic (hand-rolled `if` checks on request data) where a Symfony Validator
  constraint already expresses the same rule** — `#[Assert\NotBlank]`/`#[Assert\Email]` and the
  rest exist precisely so this isn't re-derived per endpoint.
- **A Form type reimplemented as raw request-array handling** where the project already has an
  established `FormType` pattern for the same kind of input, losing the framework's CSRF, data
  transformation, and validation wiring in the process.

## Event system idioms

- **An `EventSubscriber` and a bare `EventListener` service registered for the same kind of
  concern inconsistently within one codebase.**
- **A place the framework already dispatches an event, re-derived instead of listened for** — a
  change that duplicates logic Symfony's own kernel/security/Doctrine events already expose a
  hook for, rather than subscribing to the existing event.

## Console commands & Messenger idioms

- **A long-running console command with no progress/batching** where the framework's own
  `ProgressBar` or a chunked/batched query already fits the same job.
- **A Messenger handler with no retry/failure configuration** where the surrounding code (or its
  tests) treats the message as always eventually delivered — a transport's default retry strategy
  silently applies when the handler's own failure semantics need something different.

## Config & environment idioms

- **`getenv()` / `$_ENV` reached for directly** instead of the parameter bag or `%env()%`
  resolution Symfony's config system already provides.

## What is not a finding

- A reinvention of an existing Symfony capability with no Symfony-specific placement/shape
  angle — the **Technical** facet's reuse lens owns reuse over reinvention generically; this facet's job is
  idiom placement and shape, not "did we reinvent the wheel."
- A generic inefficiency (an N+1 shape, an unbounded load) with nothing Symfony-specific about
  it — the **Technical** facet already covers inefficient data access in the abstract.
- Whether authorization or output escaping is present *at all*, or whether user input reaches an
  interpreter unparameterized — those are the **Security** facet's OWASP-class findings. This
  facet's authorization/query bullets above are narrower: is the *established Symfony/Doctrine
  mechanism* being used, not whether protection exists.
- Oro-platform-specific idioms (entity extension, workflows, the layout system, DataGrids) — an
  OroCommerce application is Symfony underneath, but its own platform conventions belong to
  `orocommerce.md`, not this file.
- A style/formatting preference with no correctness or maintainability consequence.
- A pre-existing pattern in a file the change doesn't touch — this facet reviews the diff, not
  the whole application.
- A departure from a rule here that matches an established, consistent convention already used
  elsewhere in the project — consistency with the existing codebase outranks a rule in this file.
