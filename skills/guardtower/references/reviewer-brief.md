# The reviewer brief

What the one guardtower reviewer is handed. The orchestrator (SKILL.md) selects the facets; the
reviewer reads the change **once** and works each selected facet as one item of a checklist, in
the order given. Each facet's own file states only what is unique to it — its lens(es), the
surface that makes it relevant, its checklist(s), and which sibling facet owns an adjacent
concern. Everything below holds for every facet and is not repeated in them.

## Request — orchestrator → reviewer

```
{
  change_ref: <git ref / diff / path the review targets>,
  spec_ref:   <path to a governing spec> | none,     // an anchor for intent, if one exists
  caps: {
    top_n: <int>,                  // per facet: report at most this many, most severe first
    floor: "low" | "med" | "high"  // per facet: drop findings weaker than this bar
  },
  tenancy:    "shared" | "per-db" | "both" | "none",  // step-3 verdict; selects the tenant-isolation lens
  facets: [ <absolute path to facet.md>, ... ]      // the checklist, in order
}
```

## Procedure

1. **Read the diff once, up front.** Never re-read it. When a facet's lens needs the public
   surface of a module the change touches — the helper a reuse check compares against, the code a
   test exercises, a tenant scope — read it when that facet first needs it, and reuse anything
   already read for later facets. No repo-wide scan, graph, or index: a defect the change
   introduces is in reach; what the diff does not show is an accepted blind spot.
2. **Work the facets in order.** For each one:
   1. Read its `facet.md`.
   2. **Relevance gate, first.** Does the change touch this facet's surface? If not, record
      `relevance: { skipped: <one-line reason> }` and move to the next facet **without opening
      its checklist**.
   3. **Apply the lens(es).** Open the facet's checklist(s) now, not before, and work them against
      the diff you already read (plus
      any touched-module surface this lens needs). A facet with several lenses applies each whose surface the
      change raises; the cap spans them all.
   4. **Floor, then cap, then tally `dropped`** — for this facet alone (hard stops below).
   5. Record this facet's result, then move on. Do not carry an earlier facet's conclusions into
      a later one: judge each lens on the code.
3. **One owner per finding.** A defect goes under the facet whose lens owns it (each `facet.md`
   names its boundaries) and is not filed again under a second facet.
4. **Return** the result below. You are report-only: you never edit code and write no file.

What no facet does: fix what it finds; enumerate style nits; flag pre-existing code the change
neither introduces nor worsens.

## The hard stops

All three run inside the reviewer, per facet, before it moves on — never as trimming afterward. A
cap applied after unbounded work saves output, not tokens; a gate run first saves the work. There
is no numeric token ceiling.

1. **Relevance gate** (procedure 2.2) — the largest saver; it skips whole facets.
2. **Top-N cap.** At most `caps.top_n` findings per facet, most severe first. When more genuine
   above-floor findings exist, report how many as **`dropped`** (`0` when the cap was not hit).
   A capped list that looks complete is the cap lying; `dropped` tells the reader to re-run.
3. **Floor.** Drop any finding whose **weaker** of severity and confidence is below
   `caps.floor`. This is a drop, not a hedge: "possibly", "might be worth a look", "low
   confidence, but…" does not keep a sub-floor finding. `dropped` does not count floor drops.
   - **Speculation guard.** A finding whose realization depends on code *outside the change* — a
     hypothetical caller, an unproven path, a value some absent code might pass — is capped at
     **low confidence**, so a `med` or higher floor drops it.

**A clean result is valid.** `findings: []` is a complete answer, not a facet that gave up.
Reaching for a hedged, sub-floor finding so the list is not empty is the over-reporting the floor
exists to stop.

## Result — reviewer → orchestrator

```
{
  results: [
    {
      facet:     <facet name, e.g. reviewing-security>,
      relevance: "ran" | { skipped: <one-line reason> },
      findings:  [ Finding, ... ],   // floored and capped to <= top_n; [] is valid
      dropped:   <int>               // above-floor findings the cap held back; 0 if not hit
    },
    ...                              // one entry per requested facet, in request order
  ]
}
```

## Finding

```
{
  severity:   "high" | "med" | "low",
  confidence: "high" | "med" | "low",   // the floor tests the weaker of the two
  location:   <file:line, or a symbol name>,
  claim:      <one sentence: what is wrong>,
  why:        <one sentence: the consequence, or the rule broken>,
  evidence:   [ { at: <file:line>, code: <the cited lines, verbatim>, shows: <what they prove> }, ... ],
              // REQUIRED, at least one
  suggestion: <the direction of a fix — never applied>
}
```

`evidence` is the specific lines in this codebase that make the claim true — where untrusted
input enters and the line it reaches, the caller that retries, the column's type, the helper that
already exists. A restatement of the claim is not evidence. **No evidence, no finding.** `claim`
and `why` must read on their own for someone with no shared context. The orchestrator builds the
report's Evidence, Current code, Proposed fix and Why parts from these fields (SKILL.md step 8).
