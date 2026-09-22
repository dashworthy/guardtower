---
type: llm
weight: 2
focus: trace
arm: both
---

The change under review rewrites `book_summaries(db, book_ids)` in `src/catalog.py`. The base version issued two batched queries for all ids; the new version returns `[_load_book(db, bid) for bid in book_ids]`, and `_load_book` runs two database queries (`query_one` for the book, `query_all` for its copies) for a single id. So the list comprehension issues two queries per book id — an N+1 (here 2N) query pattern that scales with the number of books, hidden one call deep inside `_load_book`. On the catalog dashboard's hundreds of books this is hundreds of round-trips instead of a constant number.

PASS if the review flags this N+1 / per-item query pattern: it notes that a database query (or queries) runs for every book id inside the loop / comprehension via `_load_book`, that this scales linearly with the input, and it suggests batching (a single query with an IN / ANY over the ids, or loading books and copies in bulk).

FAIL if the review misses the query-per-iteration hazard — e.g. it only comments on style, naming, or the helper extraction, or never connects `_load_book` being called per id to the number of database round-trips.
