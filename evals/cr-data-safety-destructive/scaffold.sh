#!/usr/bin/env bash
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src
cat > src/sessions.py <<'PY'
"""Session maintenance."""


def count_sessions(db) -> int:
    return db.execute("SELECT COUNT(*) FROM sessions").fetchone()[0]
PY
git add -A
git commit -qm "base: session count helper"

# change: bulk cleanup whose WHERE is built from an optional cutoff that can be None.
cat > src/sessions.py <<'PY'
"""Session maintenance."""


def count_sessions(db) -> int:
    return db.execute("SELECT COUNT(*) FROM sessions").fetchone()[0]


def purge_stale_sessions(db, cutoff_days=None):
    # Delete sessions older than cutoff_days. If cutoff_days is None,
    # the WHERE clause is omitted entirely.
    where = ""
    if cutoff_days:
        where = f"WHERE last_seen < datetime('now', '-{cutoff_days} days')"
    db.execute(f"DELETE FROM sessions {where}")
    db.commit()
PY
git --no-pager diff > CHANGE.diff
echo "scaffold complete: unguarded bulk DELETE (WHERE dropped when cutoff is None), diff in CHANGE.diff"
