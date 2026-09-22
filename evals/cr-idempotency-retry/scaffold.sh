#!/usr/bin/env bash
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src
cat > src/payments.py <<'PY'
"""Payment charging."""


def charge(gateway, order_id: str, amount_cents: int) -> str:
    # Charges once; caller handles failures.
    return gateway.charge(order_id=order_id, amount_cents=amount_cents)
PY
git add -A
git commit -qm "base: single charge"

# change: adds a retry loop with NO idempotency key -> double charge on replay.
cat > src/payments.py <<'PY'
"""Payment charging."""

import time


def charge(gateway, order_id: str, amount_cents: int, attempts: int = 3) -> str:
    # Retry transient gateway failures.
    last_err = None
    for _ in range(attempts):
        try:
            # No idempotency key: each retry is a brand-new charge to the gateway.
            return gateway.charge(order_id=order_id, amount_cents=amount_cents)
        except Exception as err:  # noqa: BLE001
            last_err = err
            time.sleep(0.2)
    raise last_err
PY
git --no-pager diff > CHANGE.diff
echo "scaffold complete: non-idempotent retry in src/payments.py, diff in CHANGE.diff"
