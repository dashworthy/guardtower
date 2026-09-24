---
type: llm
weight: 1
focus: trace
arm: with-only
---

guardtower writes every artifact of a run into one directory, `.guardtower/{date}-{run-name}/`, and nowhere else (no `guardtower-report.md` in the working directory, no stray files beside the code).

PASS if every `Write` call in the trace targets a path inside a single `.guardtower/YYYY-MM-DD-<run-name>/` directory, and the final message tells the human where the report is.

FAIL if any `Write` call targets a path outside that run directory, if artifacts are split across more than one run directory, or if no report file is written at all.
