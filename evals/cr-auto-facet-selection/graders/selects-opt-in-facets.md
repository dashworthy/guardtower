---
type: llm
weight: 2
focus: trace
arm: with-only
---

The change does three things beyond ordinary code: it drops a database column in a migration (a destructive, irreversible data operation), it calls a remote HTTP API it does not own (`requests.post` to a carrier), and it runs in an at-least-once queue handler with a retry loop (a side effect that can run more than once). guardtower selects facets on its own from what the change does: the core facets always, plus the opt-in `reviewing-data-safety`, `reviewing-api`, and `reviewing-idempotency` facets whose selection criteria this change matches.

This grader measures automatic facet selection, which plain Claude does not do.

PASS if the trace shows guardtower selected (announced, dispatched, or listed in its report as selected) all three of the data-safety, API, and idempotency facets, and ran them without asking the human to choose or confirm the facet set.

FAIL if any of those three facets is left out of the selection; or if guardtower presents a facet menu / multi-select, or asks in any form (tool or plain text) which facets to run, before running them.
