---
type: llm
weight: 2
focus: last_message
arm: both
---

The change wraps `gateway.charge(...)` in a retry loop but passes NO idempotency key. If the first request actually reached the gateway and succeeded but the response was lost (a timeout), the retry issues a second, independent charge — the customer is charged twice. A charge on a retried/at-least-once path must carry an idempotency key (or otherwise dedupe) so a replay is a no-op.

PASS if the review flags that the retry can double-charge / that the charge is not idempotent / that it needs an idempotency key or dedupe guard before retrying a side-effecting payment.

FAIL if the report misses the idempotency/double-charge issue, or only raises unrelated concerns (the broad `except Exception`, the sleep, style) without naming the non-idempotent retry.
