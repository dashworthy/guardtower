// Security finding block — EXPLOIT
// PASTE-IN FRAGMENT, not a standalone module (it will not compile on its own). Adds a reproduction
// / attack-path section that shows how the issue is reached, its impact, and any preconditions.
// Uses Eyebrow, CodeBlock, KeyBox, P, Muted, hlBy, R, e — all already defined in the base template.

// ── [1] DATA — paste at the base's  ⟨finding-blocks: DATA⟩  marker ────────────────────────────
type Exploit = {
  code: string;   // the reproduction: curl / payload / script that reaches the sink, verbatim
  lang: string;   // 'bash' | 'http' | 'php' | 'sql' | ...
  impact: string; // what an attacker gains (data read/written, auth bypass, RCE, ...)
  caption: string; // 'Reproduction — <path:line or endpoint>. Runs against current code.'
  pre?: string;   // preconditions (authenticated? role? feature flag?) — omit if none
};
const EXPLOIT: Record<string, Exploit> = {
  // A1: {
  //   lang: 'bash',
  //   code: R`curl -sk 'https://host/api/orders?id=1%20OR%201=1' -H 'Cookie: session=…'`,
  //   impact: 'Reads every row of `orders`, bypassing the tenant scope.',
  //   pre: 'Any authenticated user; no admin role required.',
  //   caption: 'Reproduction — app/Http/OrderController.php:42. Runs against current code.',
  // },
};

// ── [2] SETUP — paste at the base's  ⟨finding-blocks: pre-highlight⟩  marker ───────────────────
const exploitHl = await hlBy(EXPLOIT);

// ── [3] RENDER — paste at the base's  ⟨finding-blocks: type-specific sections⟩  marker ─────────
// (inside the per-finding .map(...) array, right after the problem <P>). Renders only when the
// finding's id is present in EXPLOIT.
...(EXPLOIT[e.id] ? [
  <Eyebrow key={`${e.id}-ex1`}>Exploit — how this is reached</Eyebrow>,
  ...(EXPLOIT[e.id].pre ? [
    <P key={`${e.id}-ex0`}><Muted>Preconditions: {EXPLOIT[e.id].pre}</Muted></P>,
  ] : []),
  <CodeBlock key={`${e.id}-ex2`} code={exploitHl[e.id]} />,
  <KeyBox key={`${e.id}-ex3`} role="negative" title="Impact">{EXPLOIT[e.id].impact}</KeyBox>,
  <P key={`${e.id}-ex4`}><Muted>{EXPLOIT[e.id].caption}</Muted></P>,
] : []),
