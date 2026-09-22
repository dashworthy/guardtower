#!/usr/bin/env bash
set -euo pipefail
git init -q
git config user.email "eval@example.com"
git config user.name "eval"
git config commit.gpgsign false
mkdir -p src

cat > src/UserRepository.php <<'PHP'
<?php
namespace App\Repository;

use PDO;

final class UserRepository
{
    public function __construct(private PDO $db) {}

    public function findByEmail(string $email): ?array
    {
        $stmt = $this->db->prepare('SELECT id, email FROM users WHERE email = :email');
        $stmt->execute(['email' => $email]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }
}
PHP
git add -A
git commit -qm "base: user repository with parameterized lookup"

# change under review: FIVE separate SQL injections, each concatenating input.
cat > src/UserRepository.php <<'PHP'
<?php
namespace App\Repository;

use PDO;

final class UserRepository
{
    public function __construct(private PDO $db) {}

    public function findByEmail(string $email): ?array
    {
        $stmt = $this->db->prepare('SELECT id, email FROM users WHERE email = :email');
        $stmt->execute(['email' => $email]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    public function searchByName(string $q): array
    {
        return $this->db->query("SELECT id FROM users WHERE name LIKE '%" . $q . "%'")->fetchAll();
    }

    public function searchByCity(string $c): array
    {
        return $this->db->query("SELECT id FROM users WHERE city = '" . $c . "'")->fetchAll();
    }

    public function searchByRole(string $r): array
    {
        return $this->db->query("SELECT id FROM users WHERE role = '" . $r . "'")->fetchAll();
    }

    public function searchByStatus(string $s): array
    {
        return $this->db->query("SELECT id FROM users WHERE status = '" . $s . "'")->fetchAll();
    }

    public function searchByCompany(string $co): array
    {
        return $this->db->query("SELECT id FROM users WHERE company = '" . $co . "'")->fetchAll();
    }
}
PHP

git --no-pager diff > CHANGE.diff
echo "scaffold complete: 5 SQL injections in src/UserRepository.php, diff in CHANGE.diff"
