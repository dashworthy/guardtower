# Data-presentation review checklist — the identity ambiguities a diff can show

The Data-presentation lens of the Frontend facet. One narrow concern: a change that renders records so a
person **cannot tell two distinct records apart**, or cannot tell *which* record they are looking at
or acting on, because the presentation drops the information that distinguishes them. This is an
*identity* problem, not a styling one. **General UX, accessibility, visual design, copy, and layout
are out of scope** — colour contrast, spacing, keyboard order, wording quality, and the like belong to
a UX or accessibility review, not here; this lens fires only when the missing information makes
records genuinely ambiguous to identify. (Responsiveness and truncation are UX concerns too — except
in the one case where the responsive or truncating behaviour is *what* collapses two distinct records
into one appearance, which is the fourth class below.) Language- and framework-agnostic: these are
classes of identity-ambiguous presentation to reason about in whatever the change renders — a Blade
template, a JSON API field list, a React component, a CLI table, a select box — not a rule table for
one view layer. Every class here is scoped to what the **diff** actually renders; this facet reasons
about the presentation in front of it and does not crawl the whole UI or the data model to prove a
collision is possible. Contents:

- Non-unique label without its disambiguating path — the headline class (the breadcrumb case)
- Collision-prone identifier without a distinguishing key
- Indistinguishable records in a list or selection
- Disambiguator removed by rendering (truncation / responsive hiding)
- What is not a finding

## Non-unique label without its disambiguating path

A hierarchical or nested record shown by a **name that is unique only within its parent**, with the
path that would disambiguate it omitted:

- A nested category, folder, org unit, account, or tree node rendered as just its own name
  (`"Hardware"`) when several nodes across the tree share that name and differ only by ancestry
  (`"Products › Hardware"` vs `"Suppliers › Hardware"`). Show the breadcrumb / full path, or another ancestor-derived
  distinguisher. Name the field and the tree it belongs to, so the reviewer can confirm from the diff.

## Collision-prone identifier without a distinguishing key

A record labelled by a value that is **not unique** and is shown without the key that would separate
two records sharing it:

- People by display name alone (`"John Smith"`), files by base name (`"report.pdf"`), products by
  title, transactions by amount — presented with no email, id, timestamp, location, or other
  distinguishing key, in a context where two records can plausibly collide. The label is meaningful
  but not sufficient to identify; name what distinguishing key is missing.

## Indistinguishable records in a list or selection

The same missing-disambiguator defect as the classes above, but in an **action context** — a list,
table, dropdown, autocomplete, or radio group where the user *chooses or acts on* a record — so the
harm escalates from "can't read which record this is" to "acts on the wrong record." Two distinct
options that **render identically** here mean a wrong selection, not merely a misread:

- A `<select>` of tenants, accounts, or contacts whose options are all the same string; a
  bulk-action table whose rows can't be told apart; an autocomplete returning several identical
  entries. Say which control and why its options are ambiguous.

## Disambiguator removed by rendering

The distinguishing information is **present in the data but cut off before the user sees it** — the
inverse of the classes above, where it was omitted; here it exists and the rendering drops it:

- A **truncation** — `Str::limit()`, a `substr`/`truncate` filter, a fixed-width column, or CSS
  `text-overflow: ellipsis` — that collapses records differing only in their tail: `"Acme Corp — North
  Region"` and `"Acme Corp — South Region"` both shown as `"Acme Corp — …"`. The label the code builds
  is unambiguous; the label the user reads is not.
- A **responsive or conditional layout that hides the disambiguating column/field** at some width or
  state, so on that view two distinct records look the same. Name the limit or the hidden field and
  the records it collapses, so the reviewer can confirm from the diff.

## What is not a finding

Keep the floor honest — these belong elsewhere or to no one:

- A **label already unique in its context** — a name that cannot collide with a sibling (a top-level
  entity with a unique-by-constraint name, an id-bearing label) is not ambiguous; touching it is not a
  finding.
- A record whose **disambiguating path or key is already shown** — the breadcrumb, the id, or the
  distinguishing field is present, so identity is clear.
- **General UX / accessibility / visual-design concerns** — contrast, spacing, wording, keyboard
  order, and responsiveness in general. Real, but a different review's job; this facet is identity
  ambiguity only. (The exception is responsive/truncating behaviour that *itself* collapses two
  distinct records into one appearance — that is the fourth class above, and is in scope.)
- **Presentation the diff doesn't touch** — an ambiguous view elsewhere the change never renders. Out
  of reach by this facet's boundary, and an explicit non-goal.
