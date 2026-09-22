#!/usr/bin/env bash
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src
cat > src/pricing.py <<'PY'
"""Order pricing. Amounts are integer cents."""


def line_total(unit_cents: int, qty: int) -> int:
    return unit_cents * qty
PY
git add -A
git commit -qm "base: integer-cents line total"

# change: introduces float money + a tax rate, with rounding/precision loss.
cat > src/pricing.py <<'PY'
"""Order pricing."""

TAX_RATE = 0.0725


def line_total(unit_cents: int, qty: int) -> int:
    return unit_cents * qty


def order_total_dollars(line_items):
    # Sum in floating-point dollars, apply tax, round at the end.
    total = 0.0
    for unit_cents, qty in line_items:
        total += (unit_cents / 100.0) * qty
    total = total * (1 + TAX_RATE)
    return round(total, 2)
PY
git --no-pager diff > CHANGE.diff
echo "scaffold complete: float money + rounding in src/pricing.py, diff in CHANGE.diff"
