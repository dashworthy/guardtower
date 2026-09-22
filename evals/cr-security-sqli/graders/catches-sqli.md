---
type: llm
weight: 2
focus: trace
arm: both
---

The change under review adds `searchByName($q)` to `src/UserRepository.php`. It builds a SQL string by concatenating the user-supplied `$q` directly into a `LIKE '%...%'` clause and runs it with `$db->query(...)` — a SQL injection. The rest of the file (the parameterized `findByEmail`) is safe.

PASS if the review report identifies this SQL injection: it must call out that `searchByName` concatenates untrusted input into the query (or equivalently, that it fails to use a prepared statement / parameter binding) and flag it as an injection / security vulnerability.

FAIL if the report misses the injection entirely, or only mentions vague or unrelated concerns (style, naming, the safe `findByEmail`) without naming the concatenation-based injection in `searchByName`.
