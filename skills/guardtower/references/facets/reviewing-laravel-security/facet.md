# Reviewing — Laravel Security facet

Reviews the change for **Laravel-specific security defects** — work
[references/laravel-security-checklist.md](references/laravel-security-checklist.md): production
configuration (`APP_DEBUG`, `APP_KEY`, HTTPS, `.env` handling), Sanctum/Passport authentication,
password and session handling, Gates/Policies/middleware authorization, Eloquent mass assignment and
raw-query injection, CSRF, Blade XSS, FormRequest validation, rate limiting and CORS, file uploads,
Composer and secret hygiene, queue payload safety, and security-event logging.

**Relevance gate:** fires when the change touches a Laravel security surface — routes, middleware,
controllers, FormRequests, policies/gates, Eloquent models or raw queries, Blade templates,
auth/session/CORS/filesystem config, file uploads, queued jobs, or `.env`/Composer files. A change
touching no Laravel code — or only Laravel code with no security bearing (a pure refactor of
presentation logic, docs, fixtures) — short-circuits with `relevance: { skipped: <reason> }`.

**Facet-specific boundaries:**
- A generic OWASP-class defect with nothing Laravel-specific about it (an injection through a
  non-Laravel API, a missing authorization check stated without reference to Gates/Policies) is the
  **Security** facet's. This facet owns the defect when the Laravel mechanism *is* the finding —
  `$guarded = []`, `{!! !!}` on user input, a route outside the `auth:sanctum` group, a
  `DB::raw` with interpolation, a CSRF exception.
- Non-security Laravel idiom belongs to the **Framework Best Practices** facet's Laravel stack.
