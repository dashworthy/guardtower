---
type: tool_used
tool: Write
input_match: '\.guardtower/\d{4}-\d{2}-\d{2}-[a-z0-9][a-z0-9-]*/report\.md[\s\S]*\*\*Evidence\*\*[\s\S]{0,400}?[\w./-]+\.\w+:\d+[\s\S]*\*\*Current code\*\*[\s\S]*\*\*Proposed fix\*\*[\s\S]*\*\*Why this fixes it\*\*[\s\S]*## Review scope'
min: 1
arm: with-only
---

Deterministic structure check on the report file itself (immune to trace elision in the LLM judge): the `Write` that creates `report.md` carries the handoff template's four per-finding labels in order, with a `file:line` citation inside the Evidence part, — **Evidence**, **Current code**, **Proposed fix**, **Why this fixes it** — and the **Review scope** section.
