// Concurrency finding block — TIMELINE (interleaving)
// PASTE-IN FRAGMENT, not a standalone module. Adds a Flow showing the racing interleaving that
// produces the bug. No code highlight needed. Uses Eyebrow, Flow, P, Muted, e — defined in base.

// ── [1] DATA — paste at  ⟨finding-blocks: DATA⟩ ───────────────────────────────────────────────
type Timeline = {
  // One lane per thread/request; tone 'bad' marks the racing pair. Steps read left→right in time.
  lanes: { tag: string; tone: 'bad' | 'good'; steps: { text: string; tone?: 'bad' | 'good' }[] }[];
  caption: string; // 'Interleaving — <path:line>. The lost update when T1 and T2 overlap.'
};
const TIMELINE: Record<string, Timeline> = {
  // B1: {
  //   caption: 'Interleaving — app/Services/Wallet.php:88. Two debits read the same balance.',
  //   lanes: [
  //     { tag: 'T1', tone: 'bad', steps: [{ text: 'read bal=100' }, { text: 'write bal=90' }] },
  //     { tag: 'T2', tone: 'bad', steps: [{ text: 'read bal=100' }, { text: 'write bal=80' }] },
  //   ],
  // },
};

// ── [2] SETUP — none (Flow takes plain data; no pre-highlight line needed).

// ── [3] RENDER — paste at  ⟨finding-blocks: type-specific sections⟩ ────────────────────────────
...(TIMELINE[e.id] ? [
  <Eyebrow key={`${e.id}-tl1`}>Interleaving — the race</Eyebrow>,
  <Flow key={`${e.id}-tl2`} lanes={TIMELINE[e.id].lanes} />,
  <P key={`${e.id}-tl3`}><Muted>{TIMELINE[e.id].caption}</Muted></P>,
] : []),
