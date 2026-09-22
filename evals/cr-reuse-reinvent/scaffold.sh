#!/usr/bin/env bash
# The repo already ships a shared BackoffRetry helper. The change under review
# adds a new SMS client that hand-rolls its OWN retry/backoff loop instead of
# reusing it — a reuse miss only catchable if you look at the wider codebase.
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src

cat > README.md <<'MD'
# Bookery (excerpt)
PHP 8.2. Shared helpers live in `src/`. `src/BackoffRetry.php` is the standard
way to retry a flaky operation with exponential backoff — use it everywhere we
call an external service.
MD

cat > src/BackoffRetry.php <<'PHP'
<?php
namespace App;
/** Standard exponential-backoff retry helper used across Bookery. */
final class BackoffRetry
{
    public static function run(callable $op, int $max = 5, int $baseMs = 100): mixed
    {
        $attempt = 0;
        while (true) {
            try { return $op(); }
            catch (\Throwable $e) {
                if (++$attempt >= $max) { throw $e; }
                usleep($baseMs * (2 ** ($attempt - 1)) * 1000);
            }
        }
    }
}
PHP

cat > src/Mailer.php <<'PHP'
<?php
namespace App;
final class Mailer
{
    public function send(string $to, string $subject, string $body): void
    {
        // Note how the existing mailer leans on the shared helper.
        BackoffRetry::run(fn () => $this->transport->deliver($to, $subject, $body));
    }
    public function __construct(private Transport $transport) {}
}
PHP
git add -A
git commit -qm "base: mailer uses shared BackoffRetry"

# --- change under review: new SMS client reinvents backoff instead of reusing BackoffRetry ---
cat > src/SmsClient.php <<'PHP'
<?php
namespace App;

final class SmsClient
{
    public function __construct(private Gateway $gateway) {}

    public function send(string $phone, string $message): void
    {
        // Retry the gateway a few times if it's flaky.
        $tries = 0;
        $delayMs = 100;
        while (true) {
            try {
                $this->gateway->dispatch($phone, $message);
                return;
            } catch (\Throwable $e) {
                $tries++;
                if ($tries >= 5) {
                    throw $e;
                }
                usleep($delayMs * 1000);
                $delayMs = $delayMs * 2;
            }
        }
    }
}
PHP
git add -A -N
git --no-pager diff > CHANGE.diff
echo "scaffold complete"
