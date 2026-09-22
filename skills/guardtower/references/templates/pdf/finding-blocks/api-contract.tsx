// API-contract finding block — COMPAT (breaking-change matrix)
// PASTE-IN FRAGMENT, not a standalone module. Adds a table of what a consumer sent/received before
// vs after, flagging the break. No code highlight. Uses Eyebrow, Table, P, Muted, e — defined in base.

// ── [1] DATA — paste at  ⟨finding-blocks: DATA⟩ ───────────────────────────────────────────────
type Compat = {
  head: string[];   // e.g. ['Field', 'Before', 'After', 'Breaks?']
  rows: string[][];
  caption: string;  // 'Contract — <endpoint / path:line>. Field removed without a version bump.'
};
const COMPAT: Record<string, Compat> = {
  // D1: {
  //   head: ['Field', 'Before', 'After', 'Breaks?'],
  //   rows: [
  //     ['GET /orders → total', 'number', 'string', 'Yes — type change'],
  //     ['GET /orders → tax', 'present', 'removed', 'Yes — field dropped'],
  //   ],
  //   caption: 'Contract — routes/api.php:60. Response shape changed with no version bump.',
  // },
};

// ── [2] SETUP — none.

// ── [3] RENDER — paste at  ⟨finding-blocks: type-specific sections⟩ ────────────────────────────
...(COMPAT[e.id] ? [
  <Eyebrow key={`${e.id}-cm1`}>Compatibility — what breaks</Eyebrow>,
  <Table key={`${e.id}-cm2`} head={COMPAT[e.id].head} rows={COMPAT[e.id].rows} />,
  <P key={`${e.id}-cm3`}><Muted>{COMPAT[e.id].caption}</Muted></P>,
] : []),
