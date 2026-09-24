---
type: llm
weight: 2
focus: trace
arm: with-only
---

The prompt gave no effort level. guardtower must not silently assume one: it either asks for it with a question tool, or — when no question tool is available — proceeds at the level it recommends and says so. For this change (untrusted input reaching a SQL query) the recommended level is `high`.

This grader measures the effort question and its fallback, which plain Claude does not produce.

PASS if EITHER of these appears anywhere in the trace:
(a) an `AskUserQuestion` call offering `low`, `medium`, `high`, and `max` as options, with `high` listed first and marked "(Recommended)"; OR
(b) the review runs at `high` effort and the written report or the final message states that the effort was defaulted to the recommendation / not chosen by the user (e.g. "defaulted to the recommendation", "used high without asking", "no question tool was available").

FAIL if the review runs at some effort with no question asked and no statement that the effort was defaulted, or if the recommended/used level is not `high`.
