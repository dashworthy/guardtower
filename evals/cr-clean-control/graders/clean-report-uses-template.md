---
type: llm
weight: 1
focus: trace
arm: with-only
---

guardtower writes every report from its handoff template, including on a clean change. With no findings, the template's "No findings" section replaces the per-finding blocks, and the "Review scope" section is still filled.

Judge the CONTENT of the `Write` call that creates the report file (`.guardtower/<date>-<run-name>/report.md`), not the chat reply. Accept equivalent heading wording.

PASS if the report file states there are no findings (a "No findings" section or equivalent) AND has a review-scope section naming the effort and the facets that were run.

FAIL if no report file is written, if it has no review-scope section, or if it is a free-form summary that doesn't follow the template's layout.
