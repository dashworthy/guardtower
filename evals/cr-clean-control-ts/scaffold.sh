#!/usr/bin/env bash
set -euo pipefail
git init -q
git config user.email "eval@example.com"; git config user.name "eval"; git config commit.gpgsign false
mkdir -p src test
cat > src/text.ts <<'TS'
export function truncate(s: string, max: number): string {
  return s.length <= max ? s : s.slice(0, max);
}
TS
git add -A
git commit -qm "base: truncate helper"

# change: a clean, correct pure function + a real test.
cat > src/text.ts <<'TS'
export function truncate(s: string, max: number): string {
  return s.length <= max ? s : s.slice(0, max);
}

/**
 * Convert a title into a URL-safe slug: lowercase, spaces and non-alphanumerics
 * collapsed to single hyphens, no leading/trailing hyphen.
 */
export function slugify(title: string): string {
  return title
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}
TS
cat > test/text.test.ts <<'TS'
import { slugify } from "../src/text";

describe("slugify", () => {
  it("lowercases and hyphenates", () => {
    expect(slugify("Hello World")).toBe("hello-world");
  });
  it("collapses runs of non-alphanumerics", () => {
    expect(slugify("  A  --  B!! ")).toBe("a-b");
  });
  it("trims leading and trailing hyphens", () => {
    expect(slugify("!!edge!!")).toBe("edge");
  });
});
TS
git --no-pager diff > CHANGE.diff
echo "scaffold complete: clean slugify + test (TypeScript), diff in CHANGE.diff"
