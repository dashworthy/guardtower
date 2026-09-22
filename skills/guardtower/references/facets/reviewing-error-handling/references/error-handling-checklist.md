# Error-handling review checklist — the silent failures a diff can show

The lens for the error-handling facet. Language- and stack-agnostic: these are classes of
error-handling defect to reason about in whatever the change is written in, not a rule table for one
framework. Every class here is scoped to what the **diff** actually shows — error handling the change
adds or alters — not the whole system's failure behavior, which the diff does not show and this facet
does not audit. Contents:

- Swallowed / empty catch — the headline class
- Over-broad catch
- Masking fallback
- Dropped propagation
- Ignored rejection / return code
- What is not a finding

## Swallowed / empty catch

An error is caught and then **ignored** — the handler is empty, or does nothing but silence:

- An empty `catch {}` (or `except: pass`, a discarded `err`, a rescued exception with no body).
- A handler that only swallows — no re-raise, no recovery, no record — so a real fault continues as
  if nothing happened. Name the caught error and what the code does next, so the reviewer can see the
  failure disappears.

## Over-broad catch

A handler so wide it absorbs failures it was never meant to:

- Catching the base exception type (or a bare `catch`/`except`) around a block where only one narrow
  error was expected, so an unrelated bug — a null dereference, a typo-driven name error — is caught
  and hidden along with the intended case.
- The tell is a mismatch between the **width of the catch** and the **one thing** the guarded code
  was supposed to fail at.

## Masking fallback

A fallback or default that papers over the error instead of surfacing it:

- On error, returning a default, an empty collection, or a cached/placeholder value so the caller
  cannot tell a real failure from a legitimate empty result.
- A retry or fallback path that never signals it was taken, so a persistent fault reads as a slow
  success. A fallback is only a finding when it **hides** a fault the caller needed to know about —
  say what the caller can no longer distinguish.

## Dropped propagation

An error caught and then **neither handled nor re-raised**, so the caller never learns it happened:

- Logging the error and then continuing as if the operation succeeded, returning success up the
  stack.
- Translating an error into a value that later code treats as valid, breaking the chain that would
  have carried the failure to someone who could act on it.

## Ignored rejection / return code

An error signalled by the language's non-exception channel, left unchecked:

- A rejected promise / future with no `.catch`, no `await` inside a `try`, no rejection handler — so
  the rejection is unobserved (or crashes the process later, far from its cause).
- A function that signals failure through its **return value** (a status code, a `false`, an `err`
  tuple, a null) where the change ignores that value and proceeds as if it succeeded.

## What is not a finding

Keep the floor honest — these belong to other facets, to the whole-repo audit this facet refuses, or
to no one:

- A **deliberate, documented ignore** — a comment or a named sentinel stating why this specific error
  is safe to drop here. The intent is on the record; that is not a silent failure.
- A **genuinely total fallback** — every case is handled and the fallback hides no fault (a default
  that is a correct answer, not a mask for an error).
- A **logging-only style preference** — which logger, what level, message wording — no fault is
  hidden by it.
- A **pre-existing swallow the change doesn't touch** — this facet flags what the diff *introduces or
  alters*, not error handling it inherits unchanged. Out of reach by this facet's boundary.
