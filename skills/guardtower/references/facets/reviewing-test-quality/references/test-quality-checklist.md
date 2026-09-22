# Test-quality review checklist — would these tests catch a regression?

The lens for the test-quality facet. Language- and framework-agnostic: these are classes of weak
test to reason about in whatever the change is written in, not a rule table for one test runner.
Every class here is scoped to the **change's own tests and the code they cover** — not a whole-suite
coverage audit, which the diff does not show and this facet does not run.

**Judge by reading, not by running.** For each test the change touches, the question is always the
same: *if the changed behavior regressed, would a value this test actually asserts on change?* You
answer that **without running the suite** — by reading the changed behavior and the assertion side
by side. A test that would stay green through a regression is the defect this facet exists to catch.
Contents:

- Vacuous / tautological assertion — the headline class
- Changed path not exercised
- Assertion too weak
- Uncovered introduced edge case
- Bound to the mock, not the behavior
- What is not a finding

## Vacuous / tautological assertion

An assertion that cannot fail for the reason the test claims to check:

- Asserts a **constant** (`assert True`, `assert 1 == 1`) or a value **against itself**
  (`assert x == x`).
- Asserts only that **setup ran** — the object was constructed, the mock was called — without
  checking the result the changed behavior produces.
- The tell: delete the code under test entirely and the assertion still passes.

## Changed path not exercised

A test that is present but never drives the code the change touched:

- Calls a different branch, an unchanged overload, or a stub — the changed line never executes under
  it.
- Names the changed function in its title but asserts on state set before the change's logic runs. A
  regression in the changed path would not move anything the test observes.

## Assertion too weak

The path runs, but the assertion is too loose to notice a regression:

- Asserts **no-throw only** (`the call didn't raise`) when the change is about *what value* comes
  back, not merely that it returns.
- Asserts the **type or shape** but not the **value** the change actually determines (e.g. "returns a
  number" when the change decides *which* number).
- Asserts a substring or a count where the change's correctness lives in the exact content.

## Uncovered introduced edge case

An edge the change itself creates, with no test exercising it:

- A new branch, a new boundary (empty, zero, negative, overflow, the new error path) the change
  introduces that the tests never reach.
- Scope discipline: the edge must be one **this change introduces**, not a pre-existing gap the diff
  leaves untouched — that belongs to no one here.

## Bound to the mock, not the behavior

An assertion that verifies the test's own scaffolding rather than real behavior:

- Asserts on a **mock's canned return** — effectively asserting the mock returns what it was told to,
  which is always true and tests nothing about the code.
- Asserts a collaborator was **called** but never that the change used the result correctly, so a
  regression in the handling of that result stays green.

## What is not a finding

Keep the floor honest — these belong elsewhere or to no one:

- A **missing test for behavior outside the diff** — this facet judges the change's own tests, not
  the project's whole coverage.
- A **whole-suite coverage gap** the change doesn't touch — out of reach by this facet's boundary,
  and it never runs coverage anyway.
- A **style or naming preference** in the tests — how a test is named or laid out, with no effect on
  whether it would catch a regression.
- A **test-framework choice** — which runner or assertion library, absent an actual weakness in what
  is asserted.
