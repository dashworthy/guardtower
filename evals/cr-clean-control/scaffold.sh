#!/usr/bin/env bash
# A deliberately CLEAN change: a correct, idiomatic, parameterized method with a
# test, in a project that actually resolves and runs. There is no material defect
# to find. This measures false-positive restraint — a disciplined reviewer should
# report no real bug, not manufacture one.
#
# Two things make it genuinely clean rather than merely tidy, and both are
# established in the BASE commit so the reviewed change inherits them:
#   1. It is a runnable project — composer.json with a PSR-4 map (App\ -> src/)
#      and a phpunit.xml, and the class at the path its namespace implies
#      (src/Repository/). Without this a reviewer can correctly flag "the test
#      cannot autoload," a real defect in the fixture, not a false positive.
#   2. The repository sets PDO exception error mode in its constructor, so a
#      failed query throws instead of returning a silent `false`. That is what
#      makes `(int) $stmt->fetchColumn()` on a COUNT provably safe rather than a
#      value that could mask a failure as 0 — closing the one finding a careful
#      reviewer would otherwise (correctly) raise against the count method.
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src/Repository tests

cat > composer.json <<'JSON'
{
    "name": "bookery/book-repository",
    "type": "library",
    "require": {
        "php": ">=8.1",
        "ext-pdo": "*"
    },
    "require-dev": {
        "phpunit/phpunit": "^10",
        "ext-pdo_sqlite": "*"
    },
    "autoload": {
        "psr-4": { "App\\": "src/" }
    }
}
JSON

cat > phpunit.xml <<'XML'
<?xml version="1.0"?>
<phpunit bootstrap="vendor/autoload.php" colors="true">
    <testsuites>
        <testsuite name="default">
            <directory>tests</directory>
        </testsuite>
    </testsuites>
</phpunit>
XML

cat > src/Repository/BookRepository.php <<'PHP'
<?php
namespace App\Repository;

use PDO;

final class BookRepository
{
    public function __construct(private PDO $db)
    {
        // Fail loud: a failed query throws instead of returning a silent false.
        $this->db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    }

    public function listForAuthor(string $authorId): array
    {
        $stmt = $this->db->prepare('SELECT isbn, title FROM books WHERE author_id = :author');
        $stmt->execute(['author' => $authorId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
PHP
git add -A
git commit -qm "base: book repository (composer/psr-4 + phpunit; PDO exception mode)"

# --- change under review: add a correct, parameterized count method + a test ---
cat > src/Repository/BookRepository.php <<'PHP'
<?php
namespace App\Repository;

use PDO;

final class BookRepository
{
    public function __construct(private PDO $db)
    {
        // Fail loud: a failed query throws instead of returning a silent false.
        $this->db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    }

    public function listForAuthor(string $authorId): array
    {
        $stmt = $this->db->prepare('SELECT isbn, title FROM books WHERE author_id = :author');
        $stmt->execute(['author' => $authorId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /** Number of books by an author. */
    public function countForAuthor(string $authorId): int
    {
        $stmt = $this->db->prepare('SELECT COUNT(*) FROM books WHERE author_id = :author');
        $stmt->execute(['author' => $authorId]);
        return (int) $stmt->fetchColumn();
    }
}
PHP

cat > tests/BookRepositoryTest.php <<'PHP'
<?php
use PHPUnit\Framework\TestCase;
use App\Repository\BookRepository;

final class BookRepositoryTest extends TestCase
{
    public function testCountForAuthorCountsExactAuthor(): void
    {
        $pdo = new PDO('sqlite::memory:');
        $pdo->exec('CREATE TABLE books (isbn TEXT, title TEXT, author_id TEXT)');
        $pdo->exec(
            'INSERT INTO books (isbn, title, author_id) VALUES'
            . " ('b1','Tid','author-1'), ('b2','Ebb','author-1'),"  // author-1:  2
            . " ('b3','Arc','author-2'),"                            // author-2:  1
            . " ('b4','Fen','author-10')"                            // author-10: 1, shares the 'author-1' prefix
        );
        $repo = new BookRepository($pdo);
        // Exact match, not a prefix or an inequality: a `LIKE 'author-1%'` or a
        // `>= 'author-1'` bug would fold author-10 into author-1's count and fail here.
        $this->assertSame(2, $repo->countForAuthor('author-1'));
        $this->assertSame(1, $repo->countForAuthor('author-10'));
        $this->assertSame(1, $repo->countForAuthor('author-2'));
        $this->assertSame(0, $repo->countForAuthor('author-3'));
        // Binding pinned: a string-interpolated or LIKE-based query would let
        // these through (a non-zero count, or a SQL error); a correctly bound
        // parameter treats them as literal, unmatched author ids and returns 0.
        $this->assertSame(0, $repo->countForAuthor("author-1' OR '1'='1"));
        $this->assertSame(0, $repo->countForAuthor('author-1%'));
    }
}
PHP
git add -A -N
git --no-pager diff > CHANGE.diff
echo "scaffold complete (clean change)"
