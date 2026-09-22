# Tailwind — framework idiom checklist

The Tailwind lens for the framework best-practices facet, applicable regardless of which
frontend framework (if any) is also detected — Tailwind travels with Blade, JSX, or Vue
templates alike. Lighter than the Laravel lens: it draws on a single-file source
(`tailwindcss-development`), not a rule index. Contents:

- Reinvented utility patterns
- Deprecated v3 utilities in a v4 project
- Responsive/dark-mode consistency
- What is not a finding

## Reinvented utility patterns

- **Custom CSS (a `<style>` block, an inline `style=`, or a new class in a stylesheet) reaching
  for spacing, color, or layout that an existing Tailwind utility already expresses** — especially
  when the same visual result already exists elsewhere in the project via utility classes.
- **Margin utilities used for spacing between sibling elements** where a `gap` utility on the
  parent flex/grid container would do.

## Deprecated v3 utilities in a v4 project

A project on Tailwind v4 that still reaches for v3-only idioms:

- **A removed opacity-suffix utility** (`bg-opacity-*`, `text-opacity-*`, `border-opacity-*`,
  `divide-opacity-*`, `ring-opacity-*`, `placeholder-opacity-*`) instead of the v4 slash syntax
  (`bg-black/50`).
- **`flex-shrink-*` / `flex-grow-*`** instead of `shrink-*` / `grow-*`.
- **`@tailwind base;` / `@tailwind components;` / `@tailwind utilities;`** instead of
  `@import "tailwindcss";`.
- **A `tailwind.config.js` reached for on a v4 project** that already configures its theme via the
  CSS-first `@theme` directive — a new config entry added to the old file instead of the
  project's actual configuration surface.

## Responsive/dark-mode consistency

- **A new page or component with no `dark:` variants** in a project where sibling
  pages/components already support dark mode.
- **A one-off breakpoint or arbitrary value** (`[832px]`, a bespoke `md:` override) where the
  project's existing breakpoint/theme tokens already cover the same case.

## What is not a finding

- A visual/design preference with no established project convention to depart from — this facet
  flags inconsistency and deprecated-API usage, not taste.
- A reinvention with no Tailwind-specific angle — the **Technical** facet's reuse lens already owns reuse over
  reinvention generically; this facet's job is Tailwind idiom and version currency, not "did we
  reinvent CSS."
- A pre-existing pattern in a file the change doesn't touch — this facet reviews the diff, not
  the whole application's stylesheet history.
- A project still deliberately on Tailwind v3 — the deprecated-utility class above applies only
  when the project itself has moved to v4.
