# Security review checklist — OWASP classes + authorization

The lens for the security facet. Language-agnostic: these are classes of defect to reason about in
whatever stack the change is written in, not a rule table for one framework. Contents:

- The OWASP Top-10 classes, each with what to look for in a diff
- Authorization: enforced, not assumed
- What is *not* a security finding

## OWASP Top-10 classes

- **A01 Broken Access Control.** Missing/incorrect authorization on an action; IDOR (acting on an
  id the caller shouldn't reach); privilege escalation; forced browsing; CORS that trusts too much.
  The most common and highest-impact class — cross-check against the authorization section below.
- **A02 Cryptographic Failures.** Secrets or PII sent/stored in cleartext; weak or home-rolled
  crypto; missing TLS; hardcoded keys; predictable tokens; passwords not hashed with a strong KDF.
- **A03 Injection.** SQL/NoSQL/OS-command/LDAP injection; untrusted input reaching an interpreter
  without parameterization; reflected/stored XSS where output isn't encoded for its sink.
- **A04 Insecure Design.** A missing control the feature needs by design — no rate limit on a
  brute-forceable endpoint, no server-side validation of a client-supplied invariant.
- **A05 Security Misconfiguration.** Debug on in production; default credentials; overpermissive
  permissions; verbose errors leaking internals; unnecessary features enabled.
- **A06 Vulnerable/Outdated Components.** A newly added dependency that is unmaintained or carries
  a known CVE; pinning to a vulnerable version.
- **A07 Identification & Authentication Failures.** Weak session handling; missing MFA where
  warranted; credential stuffing not mitigated; session fixation; tokens that don't expire.
- **A08 Software & Data Integrity Failures.** Insecure deserialization of untrusted data;
  unsigned/unchecked updates or plugins; CI/CD trusting untrusted input.
- **A09 Security Logging & Monitoring Failures.** A security-relevant action (login, privilege
  change, access-control failure) that leaves no auditable trace — or logging that records secrets.
- **A10 Server-Side Request Forgery (SSRF).** User-controlled URL/host fetched by the server
  without allow-listing, letting it reach internal services or metadata endpoints.

## Authorization: enforced, not assumed

For every privileged or state-changing action the change adds or touches, find the check that
**actually enforces** it — on the server, for this exact code path:

- A **comment** asserting the caller is authorized is not enforcement.
- A **hidden or disabled UI control** is not enforcement — the endpoint is still reachable.
- "**The caller already checked**" is not enforcement unless *this* path re-checks or provably runs
  only behind that check.
- A check on the **wrong subject** — authenticated but not authorized *for this resource* — is not
  enforcement (this is IDOR).

A privileged path with no enforcing check on it, or one enforced only on the client, is a finding —
typically high severity when the action is destructive or crosses a tenant/user boundary.

## What is *not* a security finding

Keep the floor honest — these belong to other facets or to no one:

- A style/readability nit with no security consequence (Technical facet, or nothing).
- A theoretical concern with no reachable path in this change (below the confidence floor).
- A pre-existing issue the change neither introduces nor touches (out of scope — review the diff).
- A defensive suggestion that isn't responding to an actual weakness ("could add more validation"
  where the input is already constrained).
