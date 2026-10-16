#!/usr/bin/env bash
# Multi-file order-export change, well above the inline threshold. The one
# planted defect sits in a late facet (technical): export_orders_csv looks up
# each order's customer inside the loop, one query per order (N+1).
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src tests

cat > README.md <<'MD'
# Shopline (excerpt)
Python 3.11, stdlib only. `src/db.py` wraps sqlite3; always batch lookups by
id with `query_all(... IN (...))`.
MD

touch src/__init__.py tests/__init__.py

cat > src/db.py <<'PY'
"""Thin sqlite3 helpers returning dict rows."""


def query_one(conn, sql, params=()):
    cur = conn.execute(sql, params)
    row = cur.fetchone()
    if row is None:
        return None
    return dict(zip([c[0] for c in cur.description], row))


def query_all(conn, sql, params=()):
    cur = conn.execute(sql, params)
    cols = [c[0] for c in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]
PY

cat > src/orders.py <<'PY'
"""Order queries."""
from src.db import query_all


def list_orders(conn, since):
    """Return orders created on or after `since` (YYYY-MM-DD), oldest first."""
    return query_all(
        conn,
        "SELECT id, customer_id, total_cents, created_at "
        "FROM orders WHERE created_at >= ? ORDER BY created_at, id",
        (since,),
    )
PY
git add -A
git commit -qm "base: orders store"

# --- change under review: order export across several modules ---
cat > src/customers.py <<'PY'
"""Customer queries."""
from src.db import query_one


def get_customer(conn, customer_id):
    """Return the customer row for `customer_id`, or None if it does not exist."""
    return query_one(
        conn,
        "SELECT id, name, email FROM customers WHERE id = ?",
        (customer_id,),
    )
PY

cat > src/export.py <<'PY'
"""CSV export of orders."""
import csv
import io

from src.customers import get_customer
from src.orders import list_orders

HEADER = ["order_id", "created_at", "customer_name", "customer_email", "total"]


def format_cents(cents):
    """Format integer cents as a decimal string, e.g. 1250 -> '12.50'."""
    return f"{cents // 100}.{cents % 100:02d}"


def export_orders_csv(conn, since):
    """Return a CSV document of orders created on or after `since`."""
    out = io.StringIO()
    writer = csv.writer(out, lineterminator="\n")
    writer.writerow(HEADER)
    for order in list_orders(conn, since):
        customer = get_customer(conn, order["customer_id"])
        name = customer["name"] if customer else ""
        email = customer["email"] if customer else ""
        writer.writerow([
            order["id"],
            order["created_at"],
            name,
            email,
            format_cents(order["total_cents"]),
        ])
    return out.getvalue()
PY

cat > src/cli.py <<'PY'
"""Command-line entry point: python -m src.cli export --since YYYY-MM-DD DB_PATH"""
import argparse
import sqlite3
import sys

from src.export import export_orders_csv


def build_parser():
    parser = argparse.ArgumentParser(prog="shopline")
    sub = parser.add_subparsers(dest="command", required=True)
    export = sub.add_parser("export", help="print orders as CSV")
    export.add_argument("--since", required=True, help="start date, YYYY-MM-DD")
    export.add_argument("db_path", help="path to the sqlite database file")
    return parser


def main(argv=None):
    args = build_parser().parse_args(argv)
    conn = sqlite3.connect(args.db_path)
    try:
        if args.command == "export":
            sys.stdout.write(export_orders_csv(conn, args.since))
    finally:
        conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
PY

cat > tests/test_export.py <<'PY'
import sqlite3
import unittest

from src.export import HEADER, export_orders_csv, format_cents


class ExportOrdersCsvTest(unittest.TestCase):
    def setUp(self):
        self.conn = sqlite3.connect(":memory:")
        self.conn.executescript(
            """
            CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT, email TEXT);
            CREATE TABLE orders (
                id INTEGER PRIMARY KEY, customer_id INTEGER,
                total_cents INTEGER, created_at TEXT
            );
            INSERT INTO customers VALUES (1, 'Ada Lovelace', 'ada@example.com');
            INSERT INTO customers VALUES (2, 'Alan Turing', 'alan@example.com');
            INSERT INTO orders VALUES (10, 1, 1250, '2024-03-01');
            INSERT INTO orders VALUES (11, 2, 99, '2024-03-02');
            INSERT INTO orders VALUES (12, 1, 100000, '2024-03-03');
            """
        )

    def tearDown(self):
        self.conn.close()

    def test_header_row(self):
        lines = export_orders_csv(self.conn, "2024-01-01").splitlines()
        self.assertEqual(lines[0], ",".join(HEADER))

    def test_formatted_row(self):
        lines = export_orders_csv(self.conn, "2024-01-01").splitlines()
        self.assertEqual(lines[1], "10,2024-03-01,Ada Lovelace,ada@example.com,12.50")

    def test_since_filters_orders(self):
        lines = export_orders_csv(self.conn, "2024-03-03").splitlines()
        self.assertEqual(len(lines), 2)
        self.assertTrue(lines[1].startswith("12,"))

    def test_format_cents_pads_small_amounts(self):
        self.assertEqual(format_cents(99), "0.99")
        self.assertEqual(format_cents(100000), "1000.00")


if __name__ == "__main__":
    unittest.main()
PY
git add -A -N
git --no-pager diff > CHANGE.diff
echo "scaffold complete"
