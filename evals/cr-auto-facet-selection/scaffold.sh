#!/usr/bin/env bash
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src migrations
cat > src/webhooks.py <<'PY'
"""Outbound shipment webhooks."""


def build_payload(shipment: dict) -> dict:
    return {"id": shipment["id"], "status": shipment["status"]}
PY
git add -A
git commit -qm "base: shipment webhook payload"

# change: a queued (at-least-once) handler that POSTs to a carrier's remote API
# with retries, plus a migration that drops a column.
cat > src/webhooks.py <<'PY'
"""Outbound shipment webhooks."""
import time

import requests

CARRIER_URL = "https://api.carrier.example.com/v2/shipments"


def build_payload(shipment: dict) -> dict:
    return {"id": shipment["id"], "status": shipment["status"]}


def handle_shipment_dispatched(job, db):
    """Queue handler (at-least-once delivery): notify the carrier, then mark notified."""
    shipment = db.get_shipment(job["shipment_id"])
    for attempt in range(5):
        resp = requests.post(CARRIER_URL, json=build_payload(shipment), timeout=10)
        if resp.status_code < 500:
            break
        time.sleep(2 ** attempt)
    db.mark_notified(shipment["id"])
PY
cat > migrations/0042_drop_legacy_tracking.sql <<'SQL'
-- Legacy tracking numbers are superseded by carrier_ref.
ALTER TABLE shipments DROP COLUMN legacy_tracking_number;
SQL
git add -N migrations/0042_drop_legacy_tracking.sql
git --no-pager diff > CHANGE.diff
echo "scaffold complete: queued remote-API call with retries + a DROP COLUMN migration, diff in CHANGE.diff"
