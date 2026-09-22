# Backbone — framework idiom checklist

The Backbone lens for the framework best-practices facet. These are classes of defect specific to
how Backbone's view/model/event lifecycle expects a change to be shaped — not the generic
reinvention/inefficiency classes the Technical facet already owns. The reach is the
diff: a pattern visible in the changed code, not a proactive audit of the whole application. Contents:

- View lifecycle idioms
- Event-binding idioms
- Model/collection sync idioms
- Re-render idioms
- What is not a finding

## View lifecycle idioms

- **A view removed or discarded (navigated away from, replaced) with no `stopListening()`/
  `remove()` call.**

## Event-binding idioms

- **`model.on(...)` bound directly instead of `this.listenTo(model, ...)`.**

## Model/collection sync idioms

- **A model attribute set via direct property assignment** (`model.attributes.foo = x`) instead
  of `model.set('foo', x)`.

## Re-render idioms

- **A view's DOM manipulated directly in an event handler** (`this.$el.find(...).text(...)`)
  instead of going through the view's own `render()`.

## What is not a finding

- A reinvention of an existing Backbone capability with no Backbone-specific placement/shape
  angle — the **Technical** facet's reuse lens owns reuse over reinvention generically.
- A generic inefficiency (an N+1 shape, an unbounded load) with nothing Backbone-specific about
  it — the **Technical** facet already covers inefficient data access in the abstract.
- A style/formatting preference with no correctness or maintainability consequence.
- A pre-existing pattern in a file the change doesn't touch — this facet reviews the diff, not
  the whole application.
- A departure from a rule here that matches an established, consistent convention already used
  elsewhere in the project — consistency with the existing codebase outranks a rule in this file.
