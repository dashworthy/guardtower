# Reviewing — Readability facet

Reviews the change for **the readability defects a diff can actually show** — abstraction that costs
more to follow than it returns, and defensive code guarding conditions that cannot or realistically
will not happen. Work [references/readability-checklist.md](references/readability-checklist.md),
across the two classes:

- **Unearned abstraction** — indirection or generalization whose cognitive cost outweighs its value
  *even after counting tests and reuse*: single-use indirection that only forwards, a premature
  interface/generic with one implementation, parameterization for a value that never varies,
  speculative flexibility nothing uses.
- **Over-defensive programming** — a guard, validation, `try`/`catch`, or fallback for a condition
  the code's own invariants make impossible or vanishingly unlikely, or that buries the happy path
  under defense the problem does not warrant.

**Relevance gate:** fires when the change **adds or substantively reshapes executable logic** — a new
function, class, branch, guard, wrapper, or abstraction. A change that ships no such logic (a pure
config/data/doc/formatting edit, a dependency bump, a rename, a test-fixture-only change) has no
readability surface and is out of scope.

Readability is more subjective than a correctness lens, so **hold the floor hard**: a finding must
name the specific cost and the simpler shape it points to, not merely a stylistic preference.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md).

**Facet-specific boundaries:**
- Earned complexity is not a finding — an abstraction with real reuse or that genuinely simplifies the
  change's tests, and defense at a real trust boundary (external, untrusted, or network input), are
  not flagged. The cost must exceed the value the diff itself shows.
- A swallowed exception or a bad fallback is the **Error Handling** facet's; this facet owns defense
  that is *unnecessary*, not defense done badly.
- Needless indirection that creates a new seam the architecture must hold is the **Architectural**
  facet's call; this facet owns unearned complexity *inside* the logic the diff adds or edits.
