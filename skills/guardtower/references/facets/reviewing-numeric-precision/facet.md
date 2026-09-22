# Reviewing — Numeric Precision & Units facet

Reviews the change for **arithmetic that quietly produces a wrong number**. Its concern is *the
numeric value being wrong* — precision and units — not general computational logic. Work
[references/numeric-precision-checklist.md](references/numeric-precision-checklist.md), across the
diff-visible classes:

- **Binary float for an exact value** — money or another value requiring exactness held in a binary
  floating-point type, where representation error accumulates.
- **Silent rounding or truncation** — a conversion, integer division, or cast that drops a fractional
  part or digits with no explicit, intended rounding policy.
- **Unit mismatch** — two quantities in different units combined without conversion (cents added to
  dollars, milliseconds compared to seconds, bytes to kilobytes).
- **Integer overflow** — an accumulation, multiplication, or cast whose result can exceed the range
  of its integer type and wrap or saturate.
- **Precision lost on a cast** — narrowing a wider or higher-precision number into a smaller type so
  significant digits are silently discarded.
- **Mixed scale or currency without normalization** — arithmetic across values at different scales or
  currencies with no normalization to a common basis first.

**Relevance gate:** fires **only when the change does arithmetic on a meaningful quantity** — a
monetary amount, a measured value with a unit (time, size, distance, weight, rate), or a value whose
exactness matters — computing, converting, rounding, casting, or accumulating it. String handling,
control flow, a plain counter or index whose magnitude never overflows or converts, config, or docs
is out of scope.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md). When it fires, name the quantity, the
operation, and the wrong value it can produce.

**Facet-specific boundaries:**
- A wrong formula that is dimensionally sound and precise belongs to a correctness/technical review;
  this facet is precision and units only.
- It does not **flag display-only formatting** — rounding a value purely for how it is shown, when
  the underlying stored or computed value keeps full precision, is not a finding.
