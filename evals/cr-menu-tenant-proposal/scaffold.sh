#!/usr/bin/env bash
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src
# Strong multi-tenant signals: tenant_id everywhere, a shared TenantContext.
cat > src/TenantContext.php <<'PHP'
<?php
namespace App\Tenancy;

final class TenantContext
{
    public function __construct(private int $tenantId) {}
    public function id(): int { return $this->tenantId; }
}
PHP
cat > src/InvoiceRepository.php <<'PHP'
<?php
namespace App\Billing;

use App\Tenancy\TenantContext;
use PDO;

final class InvoiceRepository
{
    public function __construct(private PDO $db, private TenantContext $tenant) {}

    // Every query is scoped to the current tenant_id.
    public function findById(int $id): ?array
    {
        $stmt = $this->db->prepare('SELECT * FROM invoices WHERE id = :id AND tenant_id = :t');
        $stmt->execute(['id' => $id, 't' => $this->tenant->id()]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }
}
PHP
git add -A
git commit -qm "base: multi-tenant billing repository (tenant_id scoping)"

# change: a new total query that IS correctly tenant-scoped (not a leak).
cat > src/InvoiceRepository.php <<'PHP'
<?php
namespace App\Billing;

use App\Tenancy\TenantContext;
use PDO;

final class InvoiceRepository
{
    public function __construct(private PDO $db, private TenantContext $tenant) {}

    public function findById(int $id): ?array
    {
        $stmt = $this->db->prepare('SELECT * FROM invoices WHERE id = :id AND tenant_id = :t');
        $stmt->execute(['id' => $id, 't' => $this->tenant->id()]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    public function totalOutstanding(): int
    {
        $stmt = $this->db->prepare(
            'SELECT COALESCE(SUM(amount_cents),0) FROM invoices WHERE status = :s AND tenant_id = :t'
        );
        $stmt->execute(['s' => 'open', 't' => $this->tenant->id()]);
        return (int) $stmt->fetchColumn();
    }
}
PHP
git --no-pager diff > CHANGE.diff
echo "scaffold complete: tenant-scoped total query in a multi-tenant repo, diff in CHANGE.diff"
