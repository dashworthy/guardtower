# Reviewing — Frontend facet

Reviews a change that renders a user-facing surface across three lenses that share one relevance gate
and run as one dispatched reviewer. A change touches one, two, or all three; apply each whose concern
the diff-visible surface raises. Each lens has its own checklist, and the cap spans all three.

- **Accessibility lens** — perceivability & operability. Work
  [references/accessibility-checklist.md](references/accessibility-checklist.md): a missing text
  alternative; a form control with no associated label; non-semantic markup or ARIA misuse; a custom
  widget missing its name/role/state; a keyboard operability gap or focus trap; an image of text; a
  missing/wrong `lang`; insufficient contrast or meaning conveyed by color alone (when the diff shows
  the values); auto-playing/looping motion with no reduced-motion respect; a time limit with no
  extension; a status/live-region update not exposed to assistive tech, or focus not managed after a
  route change, modal open, or content swap.

- **Data-presentation lens** — identity ambiguity, *only*. Work
  [references/data-presentation-checklist.md](references/data-presentation-checklist.md): a
  nested/hierarchical record shown by a name its siblings share with no path; a collision-prone
  identifier (a person's name, a file's base name) shown with no distinguishing key; a list, table,
  dropdown, or autocomplete where two distinct options render identically; a truncation or responsive
  layout that cuts off the disambiguating information the data carries.

- **Internationalization lens** — whether user-facing text is *translatable*. Work
  [references/i18n-checklist.md](references/i18n-checklist.md): a hard-coded user-facing string
  written inline instead of routed through the translation mechanism; an untranslatable message shape
  (a sentence concatenated from fragments, a count with no plural handling, an interpolation that
  assumes English word order); locale-blind date/number/currency formatting; a new translation key
  left defined only in the source locale where the project's convention is to add it across catalogs.

**Relevance gate:** fires **only when the change renders a user-facing surface to a person** — a
view, template, component, page, interactive control, API field list, CLI table, or selection
control — **or** introduces/alters user-facing text in a project that localizes such text (or plainly
should). Pure business logic, config, a migration, a server-only API with no rendered output,
internal logs, developer-only CLI diagnostics, test fixtures, or docs is out of scope.

It reasons **statically** about the markup and strings in front of it — it runs no axe-core, browser,
i18n-lint, extractor, or catalog-diff tool, and does not crawl the UI, the data model, or the message
catalogs.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md).

**Facet-specific boundaries:**
- It does not **review wording quality** — clarity, tone, grammar, and typos in the source copy are a
  copy/editorial review's job; the i18n lens asks only whether text is *translatable*.
- It does not **flag developer-facing strings** — log lines, exception messages seen only by
  developers, internal CLI diagnostics, config keys, and test text are not user-facing.
