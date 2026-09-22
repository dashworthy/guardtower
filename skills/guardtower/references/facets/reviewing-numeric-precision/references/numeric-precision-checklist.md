# Numeric-precision review checklist — the wrong numbers a diff can show

The lens for the numeric-precision facet. Language- and stack-agnostic: these are classes of precision
and unit defect to reason about in whatever the change is written in, not a rule table for one language's
number types. Every class here is scoped to what the **diff** actually shows — arithmetic the change adds
or alters — not every unsafe numeric expression in the system, which the diff does not show and this
facet does not audit. Contents:

- Binary float for an exact value — the headline class
- Silent rounding or truncation
- Unit mismatch
- Integer overflow
- Precision lost on a cast
- Mixed scale or currency without normalization
- What is not a finding

## Binary float for an exact value

A value that must be **exact** held in a **binary floating-point** type, where values like 0.1 have no
exact representation and error accumulates:

- Money — a price, total, tax, or balance — in a `float`/`double`, so sums and repeated operations drift
  off the true value and rounding to cents becomes unreliable.
- Any quantity where equality or exact accumulation matters, held in binary float. Name the value and
  where the drift becomes visible (a total that is a cent off, a comparison that fails).

## Silent rounding or truncation

A conversion or operation that **drops a fractional part or digits** with no explicit, intended policy:

- Integer division where a remainder is silently discarded and the caller expected the fraction to be
  carried or rounded.
- A cast from a fractional type to an integer that truncates toward zero, when rounding was intended.
- A quantity divided and re-multiplied (splitting an amount into shares) with no handling of the leftover
  remainder, so the parts do not sum back to the whole.

## Unit mismatch

Two quantities in **different units** combined as if they were the same:

- Cents added to or compared with dollars; milliseconds with seconds; bytes with kilobytes; a rate with
  a raw count.
- A value that crosses a boundary (an API, a stored column, a library) in one unit and is used on the
  other side in another, with no conversion. The tell is two numbers meeting in one expression whose
  units do not line up.

## Integer overflow

An operation whose result can **exceed the range of its integer type** and wrap, saturate, or throw:

- An accumulation or multiplication of values that can grow past the type's maximum (a running total in
  a 32-bit int, a byte count, a product of two large factors).
- A cast into a narrower integer type of a value that can exceed the narrower range.

## Precision lost on a cast

Narrowing a wider or higher-precision number into a **smaller or lower-precision** type, discarding
significant digits:

- A large integer cast into a float that cannot represent it exactly, so the low-order digits change.
- A high-precision decimal cast into an int or a lower-precision float, silently dropping the fraction or
  significant figures.

## Mixed scale or currency without normalization

Arithmetic across values at **different scales or in different currencies** with no normalization to a
common basis first:

- Summing amounts in different currencies as if the numbers were comparable, with no conversion to a
  single currency.
- Combining values stored at different scales or precisions (one in cents, one in dollars; one scaled by
  1000, one not) without bringing them to a common scale.

## What is not a finding

Keep the floor honest — these belong to other facets, to the whole-repo audit this facet refuses, or to
no one:

- **An exact type used for an exact value** — a decimal or dedicated money type for money, an integer
  count of minor units (cents) — the representation is already correct.
- **Matched units** — quantities already in the same unit, or converted before they meet. No mismatch.
- **A range that cannot overflow** — a value provably bounded well within its type, or a type wide enough
  for any input the change admits.
- **Display-only formatting** — rounding purely for presentation while the stored or computed value keeps
  full precision. The value is not corrupted; that is presentation.
- **A deliberate, documented rounding policy** — an explicit rounding mode chosen and stated (banker's
  rounding, round-half-up to cents). The intent is on the record; not a silent defect.
- **A wrong formula that is precise and dimensionally sound** — a logic error in the computation belongs
  to a correctness/technical review, not here.
- **A pre-existing unsafe expression the change doesn't touch** — this facet flags what the diff
  *introduces or alters*, not numeric risk it inherits unchanged. Out of reach by this facet's boundary.
