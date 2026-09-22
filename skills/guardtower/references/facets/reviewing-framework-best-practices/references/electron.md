# Electron — framework idiom checklist

The Electron lens for the framework best-practices facet. This covers Electron's **non-security
idiom** — how a change sits with the framework's process model and conventions — for a repo that
depends on `electron`. The reach is the diff: a pattern visible in the changed code, not a
proactive crawl of the whole app; reason **statically** about the diff-visible code and do not
build, launch, or fuzz the app.

**Boundary — Electron *security* is not here.** Renderer isolation, the preload/context-bridge
exposure surface, the IPC trust boundary, navigation/window-open control, `shell`/`protocol` on
untrusted input, and insecure remote content/CSP are **Electron-specific security** and belong to
the **Security** facet's Electron lens, not this checklist. This file owns only the idiom breaks
that make an Electron app slow, fragile, or structured against the grain of the framework —
weighed as heavily here as any other stack's idiom. Contents:

- Main-process work placement
- Main/renderer responsibility split
- Window & app-lifecycle handling
- Auto-update & packaging hygiene
- Preload & native-module structuring
- What is not a finding

## Main-process work placement

- **Heavy or blocking work on the main process** — synchronous file I/O, a CPU-bound loop, a
  long-running computation, or a blocking IPC round-trip on the main process. Move it off-thread
  (a worker, a utility process) or make it async.

## Main/renderer responsibility split

- **Logic on the wrong side of the main/renderer split** — privileged work (filesystem, native
  modules, secrets) done in the renderer, or UI/DOM concerns pushed into the main process. Name
  what belongs where and why the split is crossed. (Where crossing the split is a *security*
  exposure rather than a structural smell, that is the Security facet's Electron lens.)

## Window & app-lifecycle handling

- **Lifecycle handling that fights the platform** — not recreating a window on macOS `activate`,
  not quitting on `window-all-closed` where expected (or quitting where it should not), leaking
  `BrowserWindow`/listener references, or racing window creation against `app.whenReady()`.

## Auto-update & packaging hygiene

- **Packaging/update hygiene as an idiom break** — secrets or source shipped unpacked in the asar,
  `nodeIntegration`/devtools left on in the packaged build, a dev-only absolute path that will not
  resolve in the built app. (An update feed served over `http:` or without signature verification
  is a *security* finding — the Security facet's Electron lens.)

## Preload & native-module structuring

- **Preload & native-module structuring** — a preload doing more than bridging, or a native module
  loaded in a way that breaks under packaging or across the sandbox. (What the preload *exposes* —
  the capability surface — is a security concern owned by the Security facet; how it is
  *structured* is this checklist's.)

## What is not a finding

- **An idiomatic, well-structured surface** — work correctly off the main thread, responsibilities
  on the right side of the split, lifecycle handled the way the platform expects — is not a
  finding.
- **An Electron *security* defect** — renderer isolation, preload exposure, IPC trust, navigation,
  shell/protocol, insecure content — is the **Security** facet's Electron lens, not this checklist,
  even though it appears in an Electron repo.
- **A generic (non-Electron) smell** — an inefficient query, a coupling problem, a fragile test —
  belongs to the Technical, Architectural, or Test Quality facet.
- **A weakness the diff doesn't touch** — an idiom break elsewhere the change never renders is out
  of reach by this facet's boundary.
