#!/usr/bin/env bash
# The change under review adds bookIfFree(): it SELECTs to see whether a room
# already has an overlapping booking window and, if not, INSERTs — with no
# transaction or lock between the check and the act. Two concurrent callers can
# both pass the overlap check and both insert, double-booking the room (TOCTOU).
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src

cat > README.md <<'MD'
# Bookery (excerpt)
PHP 8.2. Scheduling code lives in `src/`. `RoomScheduler` assigns study rooms to
bookings by time window. Staff have reported the same room being double-booked
for overlapping windows under load.
MD

cat > src/RoomScheduler.php <<'PHP'
<?php
namespace App;

use PDO;

final class RoomScheduler
{
    public function __construct(private PDO $db) {}

    /** Record a room booking for a time window. */
    public function assign(string $bookingId, string $roomId, string $start, string $end): void
    {
        $ins = $this->db->prepare(
            'INSERT INTO bookings(booking_id,room_id,win_start,win_end) VALUES(:b,:r,:a,:c)'
        );
        $ins->execute(['b' => $bookingId, 'r' => $roomId, 'a' => $start, 'c' => $end]);
    }
}
PHP
git add -A
git commit -qm "base: RoomScheduler.assign inserts a booking"

# --- change under review: add bookIfFree() with a check-then-act race ---
cat > src/RoomScheduler.php <<'PHP'
<?php
namespace App;

use PDO;

final class RoomScheduler
{
    public function __construct(private PDO $db) {}

    /** Record a room booking for a time window. */
    public function assign(string $bookingId, string $roomId, string $start, string $end): void
    {
        $ins = $this->db->prepare(
            'INSERT INTO bookings(booking_id,room_id,win_start,win_end) VALUES(:b,:r,:a,:c)'
        );
        $ins->execute(['b' => $bookingId, 'r' => $roomId, 'a' => $start, 'c' => $end]);
    }

    /** Book the room only if it has no overlapping window; return false if busy. */
    public function bookIfFree(string $bookingId, string $roomId, string $start, string $end): bool
    {
        // check
        $q = $this->db->prepare(
            'SELECT COUNT(*) FROM bookings WHERE room_id = :r AND win_start < :e AND win_end > :s'
        );
        $q->execute(['r' => $roomId, 's' => $start, 'e' => $end]);
        if ((int) $q->fetchColumn() > 0) {
            return false; // already busy
        }
        // ...then act
        $ins = $this->db->prepare(
            'INSERT INTO bookings(booking_id,room_id,win_start,win_end) VALUES(:b,:r,:a,:c)'
        );
        $ins->execute(['b' => $bookingId, 'r' => $roomId, 'a' => $start, 'c' => $end]);
        return true;
    }
}
PHP
git add -A -N
git --no-pager diff > CHANGE.diff
echo "scaffold complete"
