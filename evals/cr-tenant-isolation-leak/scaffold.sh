#!/usr/bin/env bash
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src
cat > src/TenantContext.php <<'PHP'
<?php
namespace App\Tenancy;
final class TenantContext { public function __construct(private int $tenantId) {} public function id(): int { return $this->tenantId; } }
PHP
cat > src/CustomerRepository.php <<'PHP'
<?php
namespace App\Billing;

use App\Tenancy\TenantContext;
use PDO;

final class CustomerRepository
{
    public function __construct(private PDO $db, private TenantContext $tenant) {}

    public function findById(int $id): ?array
    {
        $stmt = $this->db->prepare('SELECT * FROM customers WHERE id = :id AND tenant_id = :t');
        $stmt->execute(['id' => $id, 't' => $this->tenant->id()]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }
}
PHP
git add -A
git commit -qm "base: tenant-scoped customer repository"

# change: new lookup that DROPS the tenant_id scope -> cross-tenant leak.
cat > src/CustomerRepository.php <<'PHP'
<?php
namespace App\Billing;

use App\Tenancy\TenantContext;
use PDO;

final class CustomerRepository
{
    public function __construct(private PDO $db, private TenantContext $tenant) {}

    public function findById(int $id): ?array
    {
        $stmt = $this->db->prepare('SELECT * FROM customers WHERE id = :id AND tenant_id = :t');
        $stmt->execute(['id' => $id, 't' => $this->tenant->id()]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    // New: look a customer up by email for the admin console.
    public function findByEmail(string $email): ?array
    {
        // NOTE: no tenant_id filter — returns any tenant's customer.
        $stmt = $this->db->prepare('SELECT * FROM customers WHERE email = :email');
        $stmt->execute(['email' => $email]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }
}
PHP
git --no-pager diff > CHANGE.diff
echo "scaffold complete: cross-tenant leak (findByEmail lacks tenant_id), diff in CHANGE.diff"
