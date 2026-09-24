---
type: tool_used
tool: Write
input_match: '\.guardtower/\d{4}-\d{2}-\d{2}-[a-z0-9][a-z0-9-]*/report\.md'
min: 1
arm: with-only
---

The report must be written to `.guardtower/{date}-{run-name}/report.md` — a dated (`YYYY-MM-DD`), kebab-case-named run directory under `.guardtower/`.
