// Code-Review Finding Doc — SKELETON
// -----------------------------------------------------------------------------------------------
// A starting pdf.tsx for a designed code-review PDF handoff, authored with the engineering:using-doc-creation
// skill. Copy this file to the using-doc-creation run dir as  <RUNDIR>/pdf.tsx , fill in the DATA section,
// then render with using-doc-creation's step 3 (run it from the using-doc-creation skill dir so tsx + the package resolve):
//
//   cd "${CLAUDE_PLUGIN_ROOT}/skills/using-doc-creation" \
//     && node --import tsx src/pdf/render.ts "<RUNDIR>"
//
// where <RUNDIR> is the absolute path printed by
//   sh "${CLAUDE_PLUGIN_ROOT}/scripts/run-context.sh" using-doc-creation <slug> --fresh
//
// Discipline (the code-review handoff route in the code-review skill explains the why):
//   • EVIDENCE  = real in-repo code (the mechanism). Never a docblock/comment.
//   • DEV_NOTES = a docblock/comment about an EXTERNAL/unverified boundary. Narration, not proof.
//   • PROOFS    = a REAL passing test only. No test → leave the id out. Never fake a proof note.
//   • Every code sample gets a path:line citation in its caption.
//   • Render BOTH themes and look at the pages before claiming done.
//
// Verification tests (PROOFS) are OPT-IN. Before filling the DATA section, ask the human — as a
// structured choice, following engineering:using-questions for how to shape it and its degraded-run
// fallback — whether to build verification tests for the findings.
//   • On YES: write a real characterization test per finding that asserts *current* behaviour (so it
//     passes today), run them, and fill PROOFS with only the tests that actually pass. A finding whose
//     test was not built or did not pass simply has no Proof block; never fake a proof. Building
//     characterization tests writes new test files only — it never edits the reviewed code.
//   • On NO: leave PROOFS empty and omit every Proof block.
// -----------------------------------------------------------------------------------------------

import {
  PdfDoc, CoverPage, Section, Subhead, Toc, P, B, Muted, Eyebrow, Table, Legend,
  KeyBox, Flow, CodeBlock, highlightCode, type PdfTheme,
} from '@engineering/using-doc-creation';

const R = String.raw; // preserves backslashes and $ in PHP/SQL/YAML. NO backticks inside R`...`.

// ===============================================================================================
// DATA — fill these in. Everything below the DATA section is wiring you can leave alone.
// ===============================================================================================

// --- Cover (full-bleed CoverPage — its own dedicated first page) -------------------------------
const COVER = {
  eyebrow: 'Code Review · <TargetName>',
  title: '<Target> — Code Review',
  subtitle: '<N findings across M facets, each with current code, a proposed fix, and why it works.>',
  tags: ['<1 High>', '<10 Medium>', '<15 Low>', 'Report-only'],
  // The divided metadata strip pinned to the foot of the cover page.
  meta: [
    { label: 'Reviewer', value: '<name>' },
    { label: 'Date', value: '<YYYY-MM-DD>' },
    { label: 'Facets', value: '<M reviewed>' },
    { label: 'Status', value: 'Report-only' },
  ],
};

// --- Themes (groups) --------------------------------------------------------------------------
// One row per theme; findings are grouped under these. `order` drives section order + the table.
const THEME_META: Record<string, { eyebrow: string; title: string; deck: string; focus: string }> = {
  A: { eyebrow: 'Theme A', title: '<Theme A title>', deck: '<one-line deck>', focus: '<table focus>' },
  // B: { ... }, C: { ... }, ...
};
const THEME_ORDER = ['A' /*, 'B', 'C', ... */];

// --- Findings ---------------------------------------------------------------------------------
type Entry = {
  theme: string; id: string; title: string;
  sev: 'High' | 'Medium' | 'Low'; conf: string; loc: string;
  problem: string;
  cur: string; curLang: string;   // Current (buggy) code, verbatim
  fix: string; fixLang: string;   // Proposed fix
  why: string;                    // Why this fixes it (one paragraph)
};

const ENTRIES: Entry[] = [
  {
    theme: 'A', id: 'A1', sev: 'High', conf: 'low confidence',
    title: '<Short finding title>',
    loc: '<path/to/File.php:LINE-LINE>',
    problem: '<One paragraph: what breaks, under what condition, and the consequence.>',
    curLang: 'php',
    cur: R`<the buggy code as it exists today, verbatim>`,
    fixLang: 'php',
    fix: R`<the proposed replacement, small enough to read>`,
    why: '<One paragraph: the mechanism by which the fix removes the failure.>',
  },
  // ... more entries, grouped by theme ...
];

// --- Table-of-contents page numbers -----------------------------------------------------------
// react-pdf cannot resolve a cross-reference page number in a single pass, so fill these on a
// SECOND pass: render once (the ToC shows '—'), open the PDF, read the page each finding lands on,
// enter it here, then re-render. Keyed by finding id; a missing id shows '—'.
const PAGES: Record<string, number> = {
  // A1: 2, A2: 3, ...
};

// --- Evidence (REAL in-repo code — the mechanism) ---------------------------------------------
// Keyed by finding id. Include only where a concrete mechanism exists. Caption = "Real code — path:line".
type Evidence = { code: string; caption: string };
const EVIDENCE: Record<string, Evidence> = {
  // A1: {
  //   caption: 'Real code — <path:line>. <one sentence tying it to the problem / naming what runs externally>.',
  //   code: R`<verbatim in-repo code: the request built, the response parsed, the branch taken>`,
  // },
};

// --- Developer notes (docblock about an EXTERNAL/unverified boundary — narration) -------------
type DevNote = { code: string; caption: string };
const DEV_NOTES: Record<string, DevNote> = {
  // A1: {
  //   caption: '<path:line> — the developers’ record of an unverified boundary, not proof.',
  //   code: R`<verbatim docblock / comment>`,
  // },
};

// --- Proofs (REAL passing test ONLY — omit the id if there is no test) -------------------------
// OPT-IN: populate this only when the human asked for verification tests to be built. Each entry
// must be a real characterization test that passes today; if a test was not built, omit the id.
type Proof = { code: string; result: string; file: string };
const PROOFS: Record<string, Proof> = {
  // A1: {
  //   file: '<TestFile>.php',
  //   result: 'OK (1 test, 3 assertions)',
  //   code: R`<the characterization test that asserts CURRENT behaviour, so it passes today>`,
  // },
};

// ⟨finding-blocks: DATA⟩ — a type-specific block (finding-blocks/) pastes its DATA map
// here, keyed by finding id: EXPLOIT (security), TIMELINE (concurrency), DATA_STATE (data-safety),
// COMPAT (api-contract). Only findings whose id appears in a block's map render that block.

// --- Overview callout boxes (include the ones that apply) -------------------------------------
// Set to null to omit. `role`: positive | warning | accent | negative | neutral.
const SHARED_FIX: { title: string; body: string } | null = null;
// { title: 'The shared fix', body: '<one fix that defuses A1, A2, A4 together>' };
const EXTERNAL_BOUNDARY: { title: string; body: string } | null = null;
// { title: 'About the external boundary — unverified', body: '<name the findings; what the repo does/doesn’t hold>' };
const PROVING_TESTS: { title: string; body: string } | null = null;
// { title: 'Proving tests', body: '<how many findings carry a real test; how to run; the rest have no Proof block by design>' };

// ===============================================================================================
// WIRING — no edits needed below for a standard doc.
// ===============================================================================================

const sevRole = (s: string): 'negative' | 'warning' | 'neutral' =>
  s === 'High' ? 'negative' : s === 'Medium' ? 'warning' : 'neutral';

export default async (theme: PdfTheme) => {
  // Pre-highlight all async assets up front (react-pdf renders synchronously).
  const curFix = await Promise.all(
    ENTRIES.flatMap((e) => [highlightCode(e.cur, e.curLang, theme), highlightCode(e.fix, e.fixLang, theme)]),
  );
  const cur = (i: number) => curFix[i * 2];
  const fix = (i: number) => curFix[i * 2 + 1];

  // Highlight a keyed map of code samples; each entry may set its own `lang` (default php).
  const hlBy = async (m: Record<string, { code: string; lang?: string }>) => {
    const ids = Object.keys(m);
    const arr = await Promise.all(ids.map((id) => highlightCode(m[id].code, m[id].lang ?? 'php', theme)));
    const out: Record<string, (typeof arr)[number]> = {};
    ids.forEach((id, k) => { out[id] = arr[k]; });
    return out;
  };
  const evHl = await hlBy(EVIDENCE);
  const dnHl = await hlBy(DEV_NOTES);
  const proofHl = await hlBy(PROOFS);
  // ⟨finding-blocks: pre-highlight⟩ — a type-specific block that shows code pastes its
  // pre-highlight line here, e.g. (security):  const exploitHl = await hlBy(EXPLOIT);
  // See finding-blocks/README.md.

  const themeRows = THEME_ORDER.map((t) => [
    t, THEME_META[t].focus, String(ENTRIES.filter((e) => e.theme === t).length),
  ]);

  return (
    <PdfDoc
      theme={theme}
      title={COVER.title}
      cover={
        <CoverPage
          eyebrow={COVER.eyebrow}
          title={COVER.title}
          subtitle={COVER.subtitle}
          tags={COVER.tags}
          meta={COVER.meta}
        />
      }
      frontMatter={
        // Table of contents — its own UNNUMBERED page, right after the cover. Page numbers start on
        // the first body page below, so a `PAGES` entry is that body-relative number (1 = first
        // finding page). Auto-built from ENTRIES; page numbers come from PAGES (filled on a 2nd pass).
        <Section eyebrow="Contents" title="Findings" deck="Every finding, in order, with its page.">
          <Toc
            breakAfter={false}
            items={THEME_ORDER.flatMap((t) => [
              { title: THEME_META[t].title, level: 0 as const, link: `theme-${t}` },
              ...ENTRIES.filter((e) => e.theme === t).map((e) => ({
                title: `${e.id} · ${e.sev} — ${e.title}`,
                level: 1 as const,
                page: PAGES[e.id] ?? '—',
                link: `finding-${e.id}`,
              })),
            ])}
          />
        </Section>
      }
    >
      <Section eyebrow="Overview" title="How to read this" deck="Findings are grouped into themes, most-actionable first.">
        <P>
          <B>Scope &amp; method:</B> <Muted>{'<what was reviewed, how (facets/effort), and the overall posture>'}</Muted>
        </P>
        <Legend
          items={[
            { role: 'negative', label: 'High severity' },
            { role: 'warning', label: 'Medium severity' },
            { role: 'neutral', label: 'Low severity' },
          ]}
        />
        <Table head={['Theme', 'Focus', 'Findings']} rows={themeRows} />

        {/* Optional: a Flow illustrating a shared root-cause failure mode. Delete if not needed. */}
        {/*
        <Flow lanes={[
          { tag: 'Write', tone: 'bad', steps: [{ text: '...' }, { text: '...' }] },
          { tag: 'Replay', tone: 'bad', steps: [{ text: '...' }, { text: '...' }] },
        ]} />
        */}

        {SHARED_FIX && <KeyBox role="positive" title={SHARED_FIX.title}>{SHARED_FIX.body}</KeyBox>}
        {EXTERNAL_BOUNDARY && <KeyBox role="warning" title={EXTERNAL_BOUNDARY.title}>{EXTERNAL_BOUNDARY.body}</KeyBox>}
        {PROVING_TESTS && <KeyBox role="accent" title={PROVING_TESTS.title}>{PROVING_TESTS.body}</KeyBox>}
      </Section>

      {THEME_ORDER.map((t) => {
        const meta = THEME_META[t];
        const items = ENTRIES.map((e, i) => ({ e, i })).filter(({ e }) => e.theme === t);
        return (
          <Section key={t} id={`theme-${t}`} eyebrow={meta.eyebrow} title={meta.title} deck={meta.deck}>
            {items.map(({ e, i }) => [
              <Subhead key={`${e.id}-h`} id={`finding-${e.id}`} title={`${e.id}. ${e.title}`} deck={`${e.sev} · ${e.conf} — ${e.loc}`} rule />,
              <P key={`${e.id}-p`}>{e.problem}</P>,

              // ⟨finding-blocks: type-specific sections⟩ — paste a block's render fragment here,
              // right after the problem and before the Evidence/Current/Fix sequence. A finding
              // renders a block only when its id is present in that block's map (e.g. EXPLOIT[e.id]).
              // See finding-blocks/README.md for the catalog.

              // Evidence — real code (optional)
              ...(EVIDENCE[e.id] ? [
                <Eyebrow key={`${e.id}-ev1`}>Evidence — the real code that handles it</Eyebrow>,
                <CodeBlock key={`${e.id}-ev2`} code={evHl[e.id]} />,
                <P key={`${e.id}-ev3`}><Muted>{EVIDENCE[e.id].caption}</Muted></P>,
              ] : []),

              // Developer note — docblock about an external boundary (optional)
              ...(DEV_NOTES[e.id] ? [
                <Eyebrow key={`${e.id}-dn1`}>Developer note — what the docblock says</Eyebrow>,
                <CodeBlock key={`${e.id}-dn2`} code={dnHl[e.id]} />,
                <P key={`${e.id}-dn3`}><Muted>{DEV_NOTES[e.id].caption}</Muted></P>,
              ] : []),

              <Eyebrow key={`${e.id}-c1`}>Current code</Eyebrow>,
              <CodeBlock key={`${e.id}-c2`} code={cur(i)} />,
              <Eyebrow key={`${e.id}-f1`}>Proposed fix</Eyebrow>,
              <CodeBlock key={`${e.id}-f2`} code={fix(i)} />,
              <P key={`${e.id}-w`}><B>Why this fixes it.</B> {e.why}</P>,

              // Proof — REAL passing test only (optional; omit the id in PROOFS if none)
              ...(PROOFS[e.id] ? [
                <Eyebrow key={`${e.id}-pr1`}>Proof — this test passes today</Eyebrow>,
                <CodeBlock key={`${e.id}-pr2`} code={proofHl[e.id]} />,
              ] : []),
            ])}
          </Section>
        );
      })}
    </PdfDoc>
  );
};
