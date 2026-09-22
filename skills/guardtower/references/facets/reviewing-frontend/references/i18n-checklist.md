# i18n review checklist — the translatability defects a diff can show

The Internationalization lens of the Frontend facet. One narrow concern: a change that puts text in front of a
person in a way that **cannot be localized** — either because the text bypasses the translation
mechanism entirely, or because it reaches that mechanism in a shape no translator can correctly
localize. This is a *translatability* problem, not a *copy* one: **wording quality, tone, grammar,
and typos are out of scope** — they belong to an editorial review. Language- and framework-agnostic:
these are classes of untranslatable text to reason about in whatever the change renders and whatever
translation mechanism the surrounding code already uses — a `t()`/`__()`/`trans()` helper, a resource
bundle, a `.po`/`.json`/`.arb`/`.resx` catalog, an ICU MessageFormat string — not a rule table for
one framework. Every class here is scoped to what the **diff** actually shows; this facet reasons
about the code in front of it and does not crawl the whole codebase or the catalogs to prove an
untranslated string exists elsewhere. Contents:

- Hard-coded user-facing string — the headline class
- Untranslatable message shape (concatenation, plurals, word order)
- Locale-blind formatting (dates, numbers, currency, units)
- Untranslated new-key gap
- What is not a finding

## Hard-coded user-facing string

A literal shown to a person written **inline in the source language** instead of routed through the
translation mechanism the surrounding code uses:

- A returned or rendered string — `return "Order saved"`, `<button>Submit</button>`, a toast/alert
  message, an email or notification body, a validation message — sitting next to code that elsewhere
  localizes the same kind of text through a helper or catalog. Name the string and the translation mechanism the surrounding code
  already uses, so the reviewer can confirm from the diff that this one bypassed it.

## Untranslatable message shape

The text **does** reach the translation layer, but in a shape a translator cannot correctly localize:

- **Concatenation / sentence-building from fragments** — `t("You have") + " " + count + " " + t("items")`
  or `t("Welcome") + name`. Use a single parameterized message
  (`t("You have {count} items", { count })`).
- **Missing plural handling** — a count rendered through one fixed string (`count + " item(s)"`, or a
  hand-rolled `count === 1 ? "item" : "items"`) instead of the mechanism's plural form
  (`_n()`, ICU `{count, plural, …}`, `trans_choice()`).
- **Word-order / interpolation assumptions** — an interpolation whose surrounding literal assumes
  English order in a way a translated string could not rearrange. Name the message and why its shape
  resists localization.

## Locale-blind formatting

A date, time, number, currency, or unit rendered with a **fixed format or hard-coded symbol** instead
of a locale-aware formatter:

- A currency built by string (`"$" + amount`, `"€" . $price`) rather than a locale/currency-aware
  formatter.
- A date/time with a fixed pattern (`date("m/d/Y")`, `strftime("%m/%d/%Y")`) — use the platform's
  locale-aware date formatter.
- A number with hard-coded grouping/decimal separators, or a unit assumed (miles, °F, kg) without
  regard to locale. Name the value and the locale-aware formatter it should use.

## Untranslated new-key gap

The change **adds a translation key** but defines it in only the source locale, when the project's
convention is to add a key across its catalogs:

- A new `t("checkout.success")` with an entry added to `en.json` only, while the repo carries
  `fr.json`, `de.json`, etc. Flag the missing-locale gap **the diff itself introduces** — the new key
  present in one catalog and absent from the sibling catalogs the diff also touches or plainly
  parallels. Do not crawl every catalog to audit pre-existing completeness; that is out of boundary.

## What is not a finding

Keep the floor honest — these belong elsewhere or to no one:

- **Developer-facing text** — log lines, exception messages seen only by developers, internal CLI
  diagnostics, debug output, config keys, feature-flag names, and test fixture text. Not shown to end
  users; routing them through translation is not a finding.
- **Text already localized** — a string already wrapped in the translation helper, a value already
  passed through a locale-aware formatter. Correct use is not a finding.
- **Copy / wording quality** — clarity, tone, grammar, capitalization, and typos in the source text.
  Real, but an editorial review's job; this facet asks only whether the text is *translatable*.
- **A single-language project with no localization convention** — a codebase that legitimately ships
  in one language and has no translation layer or intent to add one. A plain string there is not a
  defect; the facet's relevance gate should have skipped, and if it ran, do not manufacture a
  requirement the project never adopted.
- **Strings the diff doesn't touch** — an untranslated string elsewhere the change never renders. Out
  of reach by this facet's boundary, and an explicit non-goal.
