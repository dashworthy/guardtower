# Reviewing — Framework Best Practices facet

Reviews the change for **stack-specific idiom violations** — conventions particular to a detected
framework, not the general principles every other facet already reasons about.

This is a **deliberate exception** to the one-checklist shape: this facet's lens is split across the
per-stack table below plus **one file per stack**, not a single checklist. Read only the file(s) the
matched stack(s) name. Ten stacks are covered: Laravel, Tailwind, Symfony, OroCommerce, React, Vue,
TypeScript, JavaScript, Backbone, and Electron — the last covering Electron's **non-security idiom**
only (main/renderer split, main-thread work, lifecycle, packaging); Electron *security* is the
**Security** facet's Electron lens. A stack with no matching row is out of scope, not approximated by
whichever file happens to be closest.

## What this facet covers

Depth varies enormously by stack, so a single flat checklist would force reading every stack's
content on every run. This table plus one file per stack keeps that read scoped to the stack(s) a
change actually touches.

| Stack      | Detected by (files the diff touches)                                                                          | Read |
|------------|------------------------------------------------------------------------------------------------------------------|------|
| Laravel    | `*.php` under an Eloquent/Illuminate-namespaced app, `routes/*.php`, `app/Http/**`, `database/migrations/**`, `tests/**/*.php` (Pest/PHPUnit)      | [`references/laravel.md`](references/laravel.md) |
| Tailwind   | Tailwind utility classes in Blade/JSX/Vue templates, `tailwind.config.{js,ts}`, an `@theme`/`@import "tailwindcss"` CSS file | [`references/tailwind.md`](references/tailwind.md) |
| Symfony    | `*.php` under a Symfony-conventional `src/Controller`/`src/Entity`/`config/services.yaml` app — including an OroCommerce app, which is Symfony underneath | [`references/symfony.md`](references/symfony.md) |
| OroCommerce | `*.php` under an Oro-conventional `src/*/Bundle` layout, an Oro entity-extend/workflow/layout/DataGrid config | [`references/orocommerce.md`](references/orocommerce.md) |
| React      | `.jsx`/`.tsx` component files, `useEffect`/`useState`/hook usage, outside Inertia-only page conventions | [`references/react.md`](references/react.md) |
| Vue        | `.vue` single-file components, Composition/Options API usage | [`references/vue.md`](references/vue.md) |
| TypeScript | `.ts`/`.tsx` files, a `tsconfig.json` in the touched project | [`references/typescript.md`](references/typescript.md) |
| JavaScript | `.js` files outside a more specific detected framework's own directory | [`references/javascript.md`](references/javascript.md) |
| Backbone   | `Backbone.View`/`Backbone.Model` usage, `.extend({...})` view/model definitions | [`references/backbone.md`](references/backbone.md) |
| Electron   | an `electron` dependency in `package.json`; a main-process entry (`app.whenReady`, `BrowserWindow`), preload scripts, or Electron packaging/asar config — the **idiom** surface only (Electron *security* is the Security facet's) | [`references/electron.md`](references/electron.md) |

A change can match more than one row — read every matched stack's file, not just the first. A Blade
template touching both Laravel and Tailwind conventions reads both; an OroCommerce PHP change matching
both the Symfony row and the OroCommerce row reads both `symfony.md` and `orocommerce.md`; a `.tsx`
React component reads both `react.md` and `typescript.md`.

**Relevance gate:** the gate *is* the table — read it first. Does the diff touch a file matching a
listed stack's detection signal? No match on any row: short-circuit and return
`relevance: { skipped: <reason> }`, having read only the table. For each matched stack, read its
reference file and work its classes of defect against the diff.

The rest of the shared procedure — report-only shape, diff-bounded reach, floor/cap/tally, and the
artifact write — lives in [../../facet-contract.md](../../facet-contract.md); the hard stops in
[../../hard-stops.md](../../hard-stops.md).

**Facet-specific boundaries:**
- A reinvention of an existing framework capability with no stack-specific placement/shape angle
  belongs to the **Technical** facet's reuse lens; a generic inefficiency with nothing stack-specific
  about it belongs to Technical's efficiency lens — this facet does not duplicate either.
- It does not **cover a stack with no reference file** — a stack outside the ten covered is out of
  scope, not approximated by the closest file. Where a stack's own reference file draws a further
  boundary against a sibling facet (Laravel's against Security, for instance), that boundary is stated
  there.
