#!/usr/bin/env bash
# The change under review replaces a single batched book lookup with a per-id
# helper called inside a list comprehension — an N+1 query pattern (two queries
# per book id), hidden one level deep behind `_load_book` so it isn't blatant.
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src

cat > README.md <<'MD'
# Bookery (excerpt)
Python 3. Data-access helpers live in `src/`. `src/catalog.py` builds book
summaries for the catalog dashboard, which loads hundreds of books at once —
database round-trips there dominate page latency.
MD

cat > src/catalog.py <<'PY'
"""Book summary loading for the catalog dashboard."""


def book_summaries(db, book_ids):
    """Load books and their copies for the given ids in two batched queries."""
    books = db.query_all(
        "SELECT * FROM books WHERE id = ANY(%s)", book_ids
    )
    copies = db.query_all(
        "SELECT * FROM copies WHERE book_id = ANY(%s)", book_ids
    )
    copies_by_book = {}
    for copy in copies:
        copies_by_book.setdefault(copy["book_id"], []).append(copy)
    return [
        {"book": b, "copies": copies_by_book.get(b["id"], [])}
        for b in books
    ]
PY
git add -A
git commit -qm "base: book_summaries uses two batched queries"

# --- change under review: per-id helper queried inside the comprehension (N+1) ---
cat > src/catalog.py <<'PY'
"""Book summary loading for the catalog dashboard."""


def _load_book(db, bid):
    book = db.query_one("SELECT * FROM books WHERE id = %s", bid)
    copies = db.query_all("SELECT * FROM copies WHERE book_id = %s", bid)
    return {"book": book, "copies": copies}


def book_summaries(db, book_ids):
    """Build a summary for each book id."""
    return [_load_book(db, bid) for bid in book_ids]
PY
git add -A -N
git --no-pager diff > CHANGE.diff
echo "scaffold complete"
