# Reviewing — Error Handling & Resilience facet

Reviews the change for **error handling that hides problems**. Work
[references/error-handling-checklist.md](references/error-handling-checklist.md), across the
diff-visible classes:

- **Swallowed / empty catch** — an error caught and ignored.
- **Over-broad catch** — a handler so wide it hides unrelated failures.
- **Masking fallback** — a fallback or default that papers over the error instead of surfacing it.
- **Dropped propagation** — an error caught and then neither handled nor re-raised.
- **Ignored rejection / return code** — an unhandled rejected promise or an unchecked
  error-signalling return value.

**Relevance gate:** fires when the change touches error handling — a `try`/`catch` (or the language's
equivalent), an error return or raise path, fallback or retry logic, promise-rejection or return-code
handling. A change with no error-handling surface (pure data, config, docs, or a computation that
neither raises nor guards) is out of scope.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md).

**Facet-specific boundary:** logging preferences and style nits are below the floor by design; its
concern is silent or masked failure, not logging taste.
