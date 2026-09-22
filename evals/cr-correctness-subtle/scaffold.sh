#!/usr/bin/env bash
# The change under review reworks a recurring reading-group meeting-date
# generator. The new loop is off-by-one: it starts at i=1 and runs while i<count,
# so it returns count-1 dates and skips the first week — a subtle correctness bug
# in otherwise plausible code.
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src

cat > README.md <<'MD'
# Bookery (excerpt)
TypeScript. Scheduling helpers live in `src/`. `src/schedule.ts` produces the
recurring weekly meeting dates a reading-group series runs on, so its counts
must be exact.
MD

cat > src/schedule.ts <<'TS'
// Weekly reading-group scheduling helpers.

/**
 * Generate the next `count` weekly meeting dates starting from `start`.
 * TODO: implement the real recurrence — this stub only returns the first week.
 */
export function nextMeetings(start: Date, count: number): Date[] {
  const first = new Date(start);
  first.setDate(first.getDate() + 7);
  return [first];
}
TS
git add -A
git commit -qm "base: nextMeetings stub returns the first week only"

# --- change under review: real recurrence, but with an off-by-one loop ---
cat > src/schedule.ts <<'TS'
// Weekly reading-group scheduling helpers.

/**
 * Generate the next `count` weekly meeting dates starting from `start`.
 * The first date is one week after `start`, then weekly thereafter.
 */
export function nextMeetings(start: Date, count: number): Date[] {
  const out: Date[] = [];
  for (let i = 1; i < count; i++) {
    const d = new Date(start);
    d.setDate(d.getDate() + i * 7);
    out.push(d);
  }
  return out;
}
TS
git add -A -N
git --no-pager diff > CHANGE.diff
echo "scaffold complete"
