---
type: llm
weight: 2
focus: trace
arm: both
---

The change adds an order export across several modules. `export_orders_csv` in `src/export.py` loads the orders with one query, then calls `get_customer(conn, order["customer_id"])` once per order inside its loop, and `get_customer` runs a `query_one` — so the export issues one extra query per order (an N+1), although the repo's README says lookups by id should be batched with `query_all(... IN (...))`.

PASS if the review flags this per-order query: it connects the `get_customer` call inside the loop to one database round-trip per order, notes it scales with the number of orders, and suggests loading the customers in one batched query (an IN over the distinct customer ids) or a join.

FAIL if the review never connects the loop's `get_customer` call to per-order queries — e.g. it comments only on CSV formatting, the CLI, tests, or style.
