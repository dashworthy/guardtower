# Stack signals — classifying a repo's frameworks for the proposal gate

This reference is how the orchestrator decides, **once per run at the repo level**, whether to
*propose* the `reviewing-framework-best-practices` facet — and which stack(s) it covers for this
run. It is read and reasoned against by the agent; it is **not** a script, a grep list, or a
checklist to mechanically match. The goal is the set of frameworks the application actually runs,
so the run selects the facet whose idiom-specific findings actually apply.

This is the **repo-level** gate — the upper of code-review's two gates, the same one
`multi-tenancy-signals.md` runs for the tenant-isolation facets. It decides which facets are selected; the facet then runs its own **per-change relevance gate** on the actual diff,
narrowed further to the file(s) a change actually touches (see the *What this facet covers* table in
[`reviewing-framework-best-practices`'s facet](facets/reviewing-framework-best-practices/facet.md)).
A facet proposed here can still skip itself on a change that touches no stack-relevant surface.

**One structural difference from `multi-tenancy-signals.md`:** that gate emits a single verdict
from a mutually-exclusive set (`shared`/`per-db`/`both`/`none`/`ambiguous`), because a repo runs
one tenancy model. This gate emits a **set** of matched stacks instead, because stacks are not
mutually exclusive the way tenancy models are — a repo commonly runs more than one at once (a
Laravel backend with a Tailwind-styled Blade or Inertia/React frontend, for instance).

Contents: [What to read](#what-to-read) · per-stack signals (Laravel, Tailwind, Symfony, OroCommerce,
React, Vue, TypeScript, JavaScript, Backbone, Electron) · [Classification — the verdict](#classification--the-verdict).

## What to read

Judge from the codebase as it stands, not from the diff under review — which frameworks a repo
runs is a property of the application, not of one change. Look at the dependency manifest
(`composer.json`, `package.json`), the presence of framework-specific config/entry files, and the
directory layout each framework conventionally expects.

## Laravel signals

- `laravel/framework` present in `composer.json`'s `require`.
- An `artisan` file at the repo root.
- The conventional Laravel directory layout — `app/Http/Controllers`, `routes/web.php` or
  `routes/api.php`, `database/migrations/`.

## Tailwind signals

- `tailwindcss` present in `package.json`'s `dependencies` or `devDependencies`.
- A `tailwind.config.js` or `tailwind.config.ts` at the repo root, **or** a CSS entry file using
  the v4 CSS-first `@theme` directive / `@import "tailwindcss"`.

## Symfony signals

- `symfony/symfony` or `symfony/framework-bundle` present in `composer.json`'s `require`.
- A `bin/console` file at the repo root.
- The conventional Symfony directory layout — `src/Controller`, `config/services.yaml`.

## OroCommerce signals

- `oro/platform` or `oro/commerce` present in `composer.json`'s `require`.
- The Oro-conventional bundle layout — one or more `src/*/Bundle` directories following Oro's own
  bundle-per-concern structure.

## React signals

- `react` present in `package.json`'s `dependencies` or `devDependencies`.
- `.jsx`/`.tsx` files containing JSX, outside a directory that's purely Inertia page components
  (Inertia's own React-page conventions are `laravel.md`'s section; this signal is for React
  itself).

## Vue signals

- `vue` present in `package.json`'s `dependencies` or `devDependencies`.
- `.vue` single-file component files.

## TypeScript signals

- `typescript` present in `package.json`'s `dependencies` or `devDependencies`.
- A `tsconfig.json` at the repo root.
- `.ts`/`.tsx` files.

## JavaScript signals

- A `package.json` present, with **no** `typescript` dependency, and `.js` files outside any
  directory a more specific framework's own signals above already claim — the residual/default
  case for a repo with no TypeScript and no detected framework directory structure of its own.
  This signal governs only which stacks join the set for *this* run; it never fires standalone
  inside a repo that's purely React/Vue/TypeScript with no separate untyped-JS surface.

## Backbone signals

- `backbone` present in `package.json`'s `dependencies` or `devDependencies`.

## Electron signals

- `electron` present in `package.json`'s `dependencies` or `devDependencies`.
- A main-process entry (`app.whenReady()`, `BrowserWindow`, a preload wired via
  `webPreferences.preload`) or Electron packaging config (electron-builder/forge, an asar).

This stack covers Electron's **non-security idiom** only (main/renderer split, main-thread work,
lifecycle, packaging). Electron-specific *security* is reviewed by the **Security** facet's
Electron lens, not proposed through this gate.

## Classification — the verdict

Emit the **set** of matched stacks — zero or more of: `laravel`, `tailwind`, `symfony`,
`orocommerce`, `react`, `vue`, `typescript`, `javascript`, `backbone`, `electron`.

- **Non-empty set** — propose the `reviewing-framework-best-practices` facet, selected.
- **Empty set** — propose neither; the facet is not selected at all, mirroring how
  the tenant-isolation facets don't appear under a `none` verdict.

There is no `ambiguous` case here the way there is for tenancy: a stack is either present in the
dependency manifest/layout or it is not, and an absent or weak signal simply does not join the
set — no human question is needed to resolve it. The verdict governs only *which stacks the
proposed facet covers this run*; it never runs the facet by itself, never suppresses a facet the
human selects manually, and never overrides the facet's own per-change relevance gate.
