# Reviewing — Test Quality facet

Reviews the tests the change carries and asks whether they would actually catch a regression in the
changed behavior. Work [references/test-quality-checklist.md](references/test-quality-checklist.md),
across the diff-visible classes:

- **Vacuous / tautological assertion** — asserts a constant, a value against itself, or only that
  setup ran.
- **Changed path not exercised** — a test that never actually drives the changed code path.
- **Assertion too weak** — asserts no-throw only, or a type but not the value the change determines,
  so a regression slips through.
- **Uncovered introduced edge case** — an edge case the change itself introduces that no test covers.
- **Bound to the mock, not the behavior** — an assertion that only checks a mock's own canned return
  rather than real behavior.

**It judges structurally, and never runs the suite.** "Would this test fail if the changed behavior
broke?" is answered by *reasoning* about whether each assertion binds to an output the changed
behavior determines — not by executing anything. Its reach is the change's own tests and the code
they cover; no whole-suite audit, no coverage run, no execution.

**Relevance gate:** fires when the change has a test surface to judge — it adds or edits tests, **or**
it changes behavior that should carry tests. A change with no tests in the diff and no behavior
needing them (pure docs, config, comment, or a rename with no behavior change) is out of scope.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md).

**Facet-specific boundary:** a security or correctness smell in the code under test is another
facet's; this one judges the tests. Test naming, framework choice, and formatting are below the floor
by design.
