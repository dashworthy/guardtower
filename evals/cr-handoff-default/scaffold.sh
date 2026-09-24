#!/usr/bin/env bash
# Bash-free-for-the-agent fixture: the scaffold (which runs unsandboxed, as the
# author) builds the repo and captures the change as CHANGE.diff. The agent then
# reviews by READING CHANGE.diff + src/ — it needs no Bash/git of its own.
set -euo pipefail

git init -q
git config user.email "eval@example.com"
git config user.name "eval"
git config commit.gpgsign false
mkdir -p src

# --- base (safe, parameterized) ---
cat > src/UserRepository.php <<'PHP'
<?php
namespace App\Repository;

use PDO;

final class UserRepository
{
    public function __construct(private PDO $db) {}

    public function findByEmail(string $email): ?array
    {
        $stmt = $this->db->prepare('SELECT id, email, role FROM users WHERE email = :email');
        $stmt->execute(['email' => $email]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ?: null;
    }
}
PHP
git add -A
git commit -qm "base: user repository with parameterized lookup"

# --- change under review: adds a search method with a SQL injection ---
cat > src/UserRepository.php <<'PHP'
<?php
namespace App\Repository;

use PDO;

final class UserRepository
{
    public function __construct(private PDO $db) {}

    public function findByEmail(string $email): ?array
    {
        $stmt = $this->db->prepare('SELECT id, email, role FROM users WHERE email = :email');
        $stmt->execute(['email' => $email]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ?: null;
    }

    // New: free-text search across users by a name fragment typed in the admin UI.
    public function searchByName(string $q): array
    {
        $sql = "SELECT id, email, role FROM users WHERE name LIKE '%" . $q . "%'";
        $stmt = $this->db->query($sql);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
PHP

# Capture the change as a diff the agent can read (git runs here, in the scaffold, not in the agent's sandbox).
git --no-pager diff > CHANGE.diff

echo "scaffold complete: uncommitted change in src/UserRepository.php, diff in CHANGE.diff"
