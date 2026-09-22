# Readability review checklist — the defects a diff can show

The lens for the readability facet. Language- and stack-agnostic: these are classes of readability
defect to reason about in whatever the change is written in, not a rule table for one framework. Every
class here is scoped to the logic the **diff** adds or reshapes — not the whole codebase's complexity,
which the diff does not show and this facet does not audit. Contents:

- Unearned abstraction — indirection that costs more than it returns
- Over-defensive programming — guarding what cannot happen
- What is not a finding

## Unearned abstraction

For each abstraction the change **introduces** — a new function, method, class, module, interface,
generic, callback, or config point — ask whether it earns the indirection it adds, judged against how
it is actually used in the diff and its tests:

- **Single-use indirection** — a wrapper, method, class, or layer that one call site reaches and that
  only forwards a call without making a decision, so the name restates the call instead of earning
  the seam. Inlining it would read more directly.
- **Premature generalization** — an interface, abstract base, strategy, or generic with a single
  concrete implementation and no second caller in sight. The generality is paid for now and used
  never.
- **Parameterization for a fixed case** — a flag, option, injected value, or config knob for
  something that never varies in practice. The parameter is a constant wearing a costume.
- **Speculative flexibility** — extension points, hooks, or callbacks added "in case we need it
  later," with no committed consumer. Complexity carried for a future that has not arrived.
- **Delegation that hides the one thing happening** — layers of pass-through where the actual
  behavior sits several hops from where a reader looks for it.

The test caveat matters: an abstraction **earns its keep** when it is genuinely reused (two or more
real callers) or materially simplifies the change's tests. Flag the abstraction whose value stays low
*even after* counting testing and reuse — that is the one that costs a reader more than it returns.

## Over-defensive programming

For each guard, validation, error handler, or fallback the change **adds**, ask whether the condition
it defends against can actually occur given the code's own invariants:

- **Guarding an impossible state** — a null-, type-, or bounds-check on a value the code just
  constructed, or that the type system already guarantees. The check can never be true.
- **Re-validating an established invariant** — a defensive check at an internal boundary the caller
  already guaranteed, re-proving one layer down what was proven a layer up.
- **Catching what cannot throw** — a `try`/`catch` around code with no failure mode, or a fallback
  branch for an enum/case value that cannot be reached.
- **Belt-and-suspenders** — the same condition checked at several layers, so a reader cannot tell
  which check is load-bearing.
- **The happy path buried** — defensive scaffolding so thick the actual behavior is hard to find in
  it.

Name the invariant that makes the defense unnecessary, so the reviewer can confirm without the
author's context.

## What is not a finding

- **Defense at a real trust boundary** — validating genuinely external or untrusted input (user
  input, a network or file payload, an environment value, a public entry point) is earned, not
  over-defensive.
- **Error handling for events that happen** — a fallback for a failure mode that can really occur,
  and defense done *badly* (a silently swallowed exception), are the Error Handling facet's concern.
  This facet flags defense that is *unnecessary*, not defense done wrong.
- **An abstraction with real reuse or a genuine test win** — see the test caveat above.
- **Pre-existing complexity** — abstraction or defense the change neither introduces nor worsens. The
  cap and floor keep this facet to what the diff actually creates.
