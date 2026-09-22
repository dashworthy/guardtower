# Accessibility review checklist — the barriers a diff can show

The Accessibility lens of the Frontend facet. One concern: a change that renders a surface a person using
assistive technology — a screen reader, a keyboard, a magnifier, a switch — **cannot perceive or
operate**, because the markup omits a name, drops a text alternative, hides meaning in color,
moves without consent, or changes without announcing. This is a *perceivability and operability*
problem, not an *identity* one. **Identity ambiguity — two distinct records a person can't tell
apart — is the Frontend facet's Data-presentation lens, not this one**; a label that is perfectly
accessible but points at the wrong record belongs there, and a barrier that has nothing to do
with telling records apart belongs here. Language- and framework-agnostic: these are classes of
accessibility barrier to reason about in whatever the change renders — an HTML or Blade template,
a JSX/React or Vue component, a native view, a stylesheet — not a rule table for one view layer.
Reason **statically** about the diff-visible markup; do not run axe-core, a browser, or any
scanner. Every class here is scoped to what the **diff** actually renders; this facet reasons
about the presentation in front of it and does not crawl the whole UI or the design system to
prove a barrier is reachable. Contents:

- Structural & naming — the headline class
- Color & contrast
- Motion & timing
- Dynamic announcements
- What is not a finding

## Structural & naming

The rendered element carries no accessible name, role, or state — or the wrong one — so
assistive technology cannot say what it is or let the user work it:

- A **missing text alternative** — an `<img>`, icon, SVG, or image button with no `alt`, no
  `aria-label`, no accessible name.
  A decorative image that should be hidden (`alt=""`) but is announced is the same class inverted.
- A **form control with no label** — an input, select, or textarea with no associated `<label>`,
  `aria-label`, or `aria-labelledby`.
- **Non-semantic markup or ARIA misuse** — a `<div onclick>` acting as a button with no `role`
  and no keyboard handler; a heading level skipped or faked with bold text; an ARIA role that
  contradicts the element or names a state it never updates. Name the element and what it should be.
- A **custom widget missing name/role/state** — a bespoke dropdown, tab set, modal, or toggle
  built from generic elements without the `role`, `aria-expanded`/`aria-selected`/`aria-checked`,
  or focus management the pattern requires.
- A **keyboard operability gap or focus trap** — an interactive control reachable or actionable
  only by mouse (no `tabindex`, no key handler), or a modal/overlay that takes focus and never
  returns it. Name the control and the missing key path.
- An **image of text**, or a **missing/incorrect `lang`** — text baked into an image so it can't
  be read or resized; a page or fragment whose language is unset or wrong.

## Color & contrast

Meaning or legibility depends on color the diff can be seen to set:

- **Insufficient contrast** — text (or a meaningful icon) rendered against a background at a ratio
  below the WCAG floor, flagged when the diff shows the actual values (a hard-coded hex, an rgb, a
  utility class whose color is legible from the change). Name the foreground/background pair.
- **Color as the only signal** — a state, error, required field, or category conveyed *only* by
  color (a red border, a green dot) with no text, icon, or pattern backing it. Name what carries
  the meaning and what a non-color cue would add.

## Motion & timing

The rendering moves or expires without giving the user control:

- **Motion with no reduced-motion respect** — an auto-playing, looping, or parallax animation, a
  carousel that advances itself, a transition, with no `prefers-reduced-motion` guard.
- **A time limit with no extension** — a control, session, or message that expires or advances on
  a timer the user can't pause, extend, or turn off. Name the limit and what's lost when it fires.

## Dynamic announcements

Content changes after load, but assistive technology is never told:

- **A live-region update not announced** — a status message, validation error, toast, search
  count, or async result injected into the DOM with no `aria-live`, `role="status"`, or
  `role="alert"`.
- **Focus not managed on a view change** — after a route change, a modal open, a dialog dismiss,
  or a dynamic content swap, focus is left where it was (or reset to the top) instead of moved to
  the new content. Name the transition.

## What is not a finding

Keep the floor honest — these belong elsewhere or to no one:

- An **already-accessible rendering** — a labelled control, an image with a real `alt`, a semantic
  element used correctly, a contrast pair above the floor — is not a barrier; touching it is not a
  finding.
- **Identity ambiguity** — a name several records share with no disambiguating path, two options
  that render identically — is the **Data-presentation** lens's concern, not this one, even when
  it happens on a rendered surface. Out of scope here.
- **General visual design, copy quality, or layout taste** — spacing, alignment, brand color
  choices, tone of wording — real, but not an accessibility barrier unless it crosses one of the
  classes above (a contrast floor, a missing name).
- **A barrier the diff doesn't touch** — an inaccessible view elsewhere the change never renders,
  or a themed color the diff can't resolve. Out of reach by this facet's boundary, and an explicit
  non-goal.
