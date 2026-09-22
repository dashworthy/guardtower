# Electron security checklist — the process-model defects an Electron diff can show

The Electron lens of the Security facet. One concern: a change to an **Electron** application that
its process model makes dangerous — a renderer given more power than it needs, a preload/IPC seam
that leaks capability, navigation or a shell call an attacker can steer, remote content loaded
insecurely. This is an *Electron-specific security* concern: a defect that is true because the code
runs in Electron, across a main process, a renderer, and the preload bridge between them.

**Generic web vulnerabilities not particular to Electron — a SQL injection in a backend call, a
broken authorization check — are the Security facet's ordinary OWASP/authorization lenses, not this
one.** And the **non-security** Electron idiom (heavy main-process work, main/renderer split,
lifecycle, packaging) is the **Framework Best Practices** facet's Electron stack, not here.

Reason **statically** about the diff-visible code and do not build, launch, or fuzz the app. Every
class here is scoped to what the **diff** actually renders; do not crawl the whole app to prove a
weakness is reachable. Contents:

- Renderer isolation — the headline class
- Preload & context bridge
- IPC trust boundary
- Navigation & window control
- Shell, protocol & external content

## Renderer isolation

A renderer that loads any content it does not fully control must not hold Node or a shared context:

- **`nodeIntegration: true`** in a window that loads remote or semi-trusted content — the renderer
  can `require('child_process')` and run anything. Off is the safe default; on is a finding unless
  the window only ever loads fully-trusted, locally-bundled content and even then is worth
  questioning.
- **`contextIsolation: false`** — the preload and the page share one JavaScript context, so a
  compromised page can reach into privileged preload objects and Electron internals. Isolation on
  (the modern default) is expected; turning it off, or a preload written assuming it is off, is a
  finding.
- **`sandbox: false`** on a renderer that need not be unsandboxed — the OS sandbox is the last line
  of defence when the other flags slip. Disabling it (or relying on a preload feature that forces
  it off) without a stated reason is a finding.
- **`nodeIntegrationInWorker` / `nodeIntegrationInSubFrames` enabled** — the same Node exposure
  widened to workers or nested frames, an easily-missed re-opening of the door isolation just
  closed.

## Preload & context bridge

The preload is the only sanctioned bridge; it must expose a **narrow, specific** API, never raw
power:

- **`contextBridge` exposing `ipcRenderer` directly, or a whole module** — handing the page
  `ipcRenderer`, `require`, `fs`, `child_process`, or an unfiltered `send`/`invoke` lets it call any
  channel or run anything. Expose named functions that each wrap one validated operation, not the
  transport itself.
- **A preload that pollutes the page context** — attaching privileged objects to `window` without
  `contextBridge` (or with `contextIsolation` off), so the page reaches them directly.
- **`@electron/remote` / the legacy `remote` module enabled** — it hands the renderer synchronous
  reach into main-process objects and is a known isolation hole; its introduction or continued use
  is a finding, with migration to explicit IPC the direction.

## IPC trust boundary

Every `ipcMain` handler runs in the trusted main process on input from a less-trusted renderer;
treat that input as hostile:

- **A handler that trusts its sender** — `ipcMain.handle`/`on` acting on a channel with no check on
  `event.senderFrame`/origin, so any frame (including a compromised or injected one) can invoke a
  privileged operation.
- **Unvalidated arguments** — a handler that reads a path, URL, id, or command from the message and
  acts on it without validating type, shape, or allowed range — a path-traversal, an arbitrary file
  read/write, an SSRF, driven straight from the renderer.
- **A privileged capability behind a generic channel** — a single `invoke('do', {...})` that
  dispatches to many operations, so the renderer chooses which privileged action runs. Prefer
  specific channels with narrow, validated payloads.

## Navigation & window control

An Electron window that can navigate or open where an attacker points it becomes a native-privilege
foothold:

- **No `will-navigate` guard / no allow-list** — a window that lets content navigate to an
  arbitrary origin, so a redirect or injected link moves a privileged renderer onto attacker
  content.
- **No `setWindowOpenHandler` (or a legacy `new-window` that returns `allow`)** — window/popup
  creation left open, or opening arbitrary URLs with a fresh renderer instead of denying or handing
  off to the OS browser.
- **`webviewTag: true`, `allowpopups`, or an unvalidated `<webview>`** — the embedded-content tag
  re-enabled or a `<webview>` whose `src`, `preload`, or window features are not constrained.

## Shell, protocol & external content

Native reach and content loading are the highest-blast-radius calls in the API:

- **`shell.openExternal` / `shell.openPath` on untrusted input** — a URL or path from the page, an
  IPC message, or a remote response handed to the OS to open, which can launch an executable or a
  `file:`/custom-scheme handler — effectively remote command execution. The argument must be
  validated against an allow-list of safe schemes/paths.
- **An insecure custom protocol handler** — `protocol.registerFileProtocol`/`handle` that maps a
  request path onto the filesystem without normalizing and confining it, so `..` escapes the
  intended root.
- **Remote content over `http:` or with `webSecurity: false`** — loading app content over
  plaintext, or disabling the same-origin/`webSecurity` protections, exposing the renderer to
  injection and MITM. `allowRunningInsecureContent: true` and `experimentalFeatures: true` are the
  same class. An **update feed served over `http:` or without signature verification** is this
  class too.
- **No Content-Security-Policy** — a renderer that loads any HTML with no CSP restricting script and
  connect sources, so an injected script runs unbounded. A missing or trivially-permissive CSP on a
  content-loading window is a finding.

## What is not a finding

- **An already-hardened, idiomatic surface** — a sandboxed renderer with `contextIsolation` on and
  `nodeIntegration` off, a minimal `contextBridge` of named functions, a sender-checked and
  argument-validated IPC handler — is not a finding; touching it is not one either.
- **Non-security Electron idiom** — heavy main-process work, a wrong-side-of-the-split
  responsibility, lifecycle/packaging structuring — is the Framework Best Practices facet's Electron
  stack, not this lens.
- **A weakness the diff doesn't touch** — an unsafe window or preload elsewhere the change never
  renders. Out of reach by this facet's boundary.
