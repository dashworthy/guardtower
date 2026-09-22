---
type: llm
weight: 2
focus: last_message
arm: both
---

`purge_stale_sessions` builds a `DELETE FROM sessions` whose `WHERE` clause is only added when `cutoff_days` is truthy. Called with no argument (the default `None`), or `0`, the `where` string stays empty and the statement becomes an unqualified `DELETE FROM sessions` — it wipes EVERY session, not just stale ones. This is a destructive, irreversible bulk data operation with no guard.

PASS if the review flags the risk of deleting all rows / the missing-WHERE (unguarded bulk delete) when `cutoff_days` is None or falsy, or otherwise names the destructive/irreversible data-loss hazard.

FAIL if the report misses the mass-delete hazard, or only raises unrelated concerns (SQL string building, style, the unchanged `count_sessions`) without naming the destructive data operation. (Noting the f-string SQL as an injection is fine as an extra, but the data-safety hazard must be named to PASS.)
