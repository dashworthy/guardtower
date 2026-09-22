# Reviewing — Security facet

Reviews the change for **security defects** across three lenses:

- **OWASP-class defects** — work [references/owasp-checklist.md](references/owasp-checklist.md): the
  Top-10 categories (access control, injection, cryptographic failures, SSRF, insecure
  deserialization, misconfiguration, and the rest).
- **Authorization enforced, not assumed** — for every privileged action the change adds or touches,
  find the check that actually enforces it on the server for *this* path. A comment, a UI-hidden
  control, or an assumption that "the caller already checked" is not enforcement. A hazard about a
  *hypothetical* caller or path absent from the diff is the speculation guard's low-confidence case
  ([../../hard-stops.md](../../hard-stops.md)), dropped at a `med` floor — not a reportable finding
  here.
- **Electron process-model security** — *only when the change touches an Electron surface.* Work
  [references/electron-security-checklist.md](references/electron-security-checklist.md): renderer
  isolation (`nodeIntegration`, `contextIsolation`, `sandbox`), the preload/context-bridge exposure
  surface, the IPC trust boundary, navigation and window-open control, `shell`/`protocol` misuse on
  untrusted input, and insecure remote content/transport.

**Relevance gate:** fires when the change plausibly touches a security surface — auth/session/
permission code, input handling, queries, file or network I/O, crypto, secrets, serialization,
access-control checks, an Electron process-model surface, anything user-facing or handling untrusted
data. A pure docs/comment/formatting change, or a test-fixtures-only change, is out of scope.

The shared procedure — report-only shape, diff-bounded reach, the four-step workflow, and the
generic "what this does not do" — lives in [../../facet-contract.md](../../facet-contract.md); the
hard stops in [../../hard-stops.md](../../hard-stops.md).

**Facet-specific boundary:** the *non-security* Electron idiom (heavy work on the main process, a
wrong-side-of-the-split responsibility, lifecycle/packaging hygiene) belongs to the **Framework Best
Practices** facet's Electron stack, not this facet.
