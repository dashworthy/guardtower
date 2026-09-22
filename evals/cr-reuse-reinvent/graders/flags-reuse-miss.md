---
type: llm
weight: 2
focus: trace
arm: both
---

The repository already ships `src/BackoffRetry.php`, a shared exponential-backoff retry helper (and `Mailer` uses it). The change under review adds `src/SmsClient.php` whose `send()` hand-rolls its own retry loop with a doubling delay — duplicating what `BackoffRetry` already provides.

PASS if the review notices this duplication / reuse miss: it points out that the new client reimplements retry-with-backoff logic that already exists in the codebase (naming `BackoffRetry` or the existing shared helper) and suggests reusing it instead of hand-rolling.

FAIL if the review never connects the new retry loop to the existing `BackoffRetry` helper — e.g. it only reviews the diff in isolation, or comments only on style, and misses that the codebase already has this exact utility.
