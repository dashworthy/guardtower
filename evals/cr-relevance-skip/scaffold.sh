#!/usr/bin/env bash
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src docs
cat > src/PriceFormatter.php <<'PHP'
<?php
namespace App\Support;

final class PriceFormatter
{
    public function format(int $cents, string $currency = 'USD'): string
    {
        $amount = number_format($cents / 100, 2);
        return $currency . ' ' . $amount;
    }
}
PHP
cat > docs/pricing.md <<'MD'
# Pricing
Prices are stored as integer cents.
MD
git add -A
git commit -qm "base: price formatter + docs"

# change under review: ONLY comments + docs. No logic changes at all.
cat > src/PriceFormatter.php <<'PHP'
<?php
namespace App\Support;

/**
 * Formats an integer-cents amount into a human-readable string.
 *
 * Amounts are always stored and passed as integer cents to avoid float
 * rounding error; this class only renders them for display.
 */
final class PriceFormatter
{
    // Render `cents` as "<CURRENCY> <major>.<minor>" (e.g. USD 12.50).
    public function format(int $cents, string $currency = 'USD'): string
    {
        $amount = number_format($cents / 100, 2);
        return $currency . ' ' . $amount;
    }
}
PHP
cat > docs/pricing.md <<'MD'
# Pricing

Prices are stored as **integer cents** throughout the system. Never store or
compute money as a float. Use `PriceFormatter::format()` for display only.
MD
git --no-pager diff > CHANGE.diff
echo "scaffold complete: comments + docs only change, diff in CHANGE.diff"
