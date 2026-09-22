# Finding-type blocks

Type-specific sections that layer onto the base handoff template
[`../code-review-handoff.pdf.tsx`](../code-review-handoff.pdf.tsx). The authored `pdf.tsx` the
`using-doc-creation` render wrapper stages **must be a single self-contained file** — it cannot `import` these
at render time. So each block is a **paste-in fragment**, not a runtime module: you copy the base,
then paste the blocks for the finding types present in your review. A file here will not compile on
its own.

## The blocks

| Block | File | Adds | Data key |
|---|---|---|---|
| Security | [`security.tsx`](security.tsx) | Exploit — reproduction / attack path, impact, preconditions | `EXPLOIT` |
| Concurrency | [`concurrency.tsx`](concurrency.tsx) | Interleaving timeline (a `Flow` of the racing threads) | `TIMELINE` |
| Data-safety | [`data-safety.tsx`](data-safety.tsx) | Before → after persisted-state table | `DATA_STATE` |
| API-contract | [`api-contract.tsx`](api-contract.tsx) | Breaking-change matrix (consumer before/after) | `COMPAT` |

Each block renders **per finding**: a finding shows the block only when its id is a key in that
block's map (e.g. `EXPLOIT['A1']`). A finding with no entry renders exactly the base shape.

## How to assemble

Every block is split into up to three labelled parts. Paste each at its marker in the base template:

1. **`[1] DATA`** → the base's `// ⟨finding-blocks: DATA⟩` marker (the DATA section). Keeps the
   block's `type` + its keyed map next to the base's `EVIDENCE` / `DEV_NOTES` / `PROOFS`.
2. **`[2] SETUP`** → the base's `// ⟨finding-blocks: pre-highlight⟩` marker (inside the async
   builder). Only blocks that show highlighted code have this — it adds one `await hlBy(...)` line.
   `hlBy` honours a per-entry `lang` (default `php`), so a `bash` exploit or a `sql` payload
   highlights correctly.
3. **`[3] RENDER`** → the base's `// ⟨finding-blocks: type-specific sections⟩` marker (inside the
   per-finding `.map(...)`, right after the problem `<P>`). It is a spread `...(MAP[e.id] ? [ … ] :
   [])`, so it drops in beside the Evidence / Current / Fix fragments.

Add only the blocks you need. To add a new finding type, copy the closest block and keep the same
three-part shape and the "render only when `e.id` is in the map" guard.

## Discipline

The base template's rules carry into every block: a code sample is real (an exploit that actually
reaches the sink, a state table that matches the rows), and every sample keeps its `path:line`
citation in the caption. An exploit you have not actually run is narration — say so, or leave it
out; never dress an untested reproduction as proof. Verification tests remain the opt-in `PROOFS`
block in the base, gated by the human's answer in the code-review handoff route.
