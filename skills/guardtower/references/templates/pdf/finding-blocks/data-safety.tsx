// Data-safety finding block — DATA_STATE (before → after)
// PASTE-IN FRAGMENT, not a standalone module. Adds a table of the persisted state before and after
// the buggy operation, so the corruption or loss is concrete. No code highlight. Uses Eyebrow,
// Table, P, Muted, e — defined in base.

// ── [1] DATA — paste at  ⟨finding-blocks: DATA⟩ ───────────────────────────────────────────────
type DataState = {
  head: string[];   // e.g. ['Column', 'Before', 'After (bug)']
  rows: string[][]; // one row per field that changes
  caption: string;  // 'State — <table.column @ path:line>. The migration nulls status on retry.'
};
const DATA_STATE: Record<string, DataState> = {
  // C1: {
  //   head: ['Column', 'Before', 'After (bug)'],
  //   rows: [
  //     ['orders.status', 'shipped', 'NULL'],
  //     ['orders.updated_at', '2026-09-10', 'unchanged'],
  //   ],
  //   caption: 'State — orders @ database/migrations/…_backfill.php:31. Status is nulled on retry.',
  // },
};

// ── [2] SETUP — none.

// ── [3] RENDER — paste at  ⟨finding-blocks: type-specific sections⟩ ────────────────────────────
...(DATA_STATE[e.id] ? [
  <Eyebrow key={`${e.id}-ds1`}>Data state — before → after</Eyebrow>,
  <Table key={`${e.id}-ds2`} head={DATA_STATE[e.id].head} rows={DATA_STATE[e.id].rows} />,
  <P key={`${e.id}-ds3`}><Muted>{DATA_STATE[e.id].caption}</Muted></P>,
] : []),
