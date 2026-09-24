---
type: llm
weight: 2
focus: last_message
arm: with-only
---

The reviewer was asked for a shareable handoff to drop into a PR, showing for each issue the current code, the proposed fix, and why it works. guardtower's handoff template lays each finding out with four labeled parts — evidence (cited `file:line`), current code, a proposed fix, and why this fixes it — grouped for a reader, with fix code in fenced blocks.

This grader measures whether the output actually takes the handoff shape (not the terse default findings table). Accept equivalent labels and headings — the exact wording need not match the template; what matters is the per-finding four-part structure.

PASS if the output is organized per finding and, for the SQL-injection finding at least, shows all four parts: (a) evidence citing `file:line` with the cited code quoted, (b) the current/vulnerable code, (c) a concrete proposed fix (e.g. a prepared statement / parameter binding) shown as code, and (d) an explanation of why the fix resolves it. A contents/theme grouping is a plus but not required.

FAIL if the output is only a flat findings table or prose with no per-finding evidence / current-code / proposed-fix / why breakdown, or if it omits the evidence or the proposed-fix code, or if it misses the SQL injection entirely.
