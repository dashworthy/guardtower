# The facet contract

The uniform interface between the `reviewing` orchestrator and every facet skill. It is identical
for all facets, so the orchestrator knows nothing facet-specific and a new facet is "implement this
contract + add a menu row."

## What every facet does (the shared procedure)

Every facet inherits this skeleton; a facet's own file states only what is **unique** to it — the
lens(es) it applies, the surface that makes it relevant, and the checklist(s) it works. Everything
below holds for all of them and is not repeated per facet.

- **Report-only.** Given the change under review, a facet returns a short, ordered, self-contained
  list of findings — capped and floored — directly to the orchestrator. It never edits code.
- **Diff-bounded reach.** A facet reasons about what the change **visible in the diff** actually
  does, read against the reviewer's own knowledge of the domain — plus, where a lens needs it, the
  public surface of the modules the change already touches. It runs **no proactive repo-wide scan,
  graph, or index**. A defect the change introduces is in reach; what the diff does not show is an
  accepted blind spot, not a defect the facet chases. (A facet that additionally forgoes running any
  tool — suite, scanner, extractor — says so in its own file.)
- **The workflow, in order.** Each facet runs the same four steps; its file fills in steps 1–2:
  1. **Relevance gate — first, before any lens work** (hard-stops.md §1). Does the change touch this
     facet's surface at all? If not, short-circuit and return `relevance: { skipped: <reason> }`,
     having spent almost nothing. The gate is deliberately
     narrow — it is the single largest saver.
  2. **Apply the lens(es).** For a change that passed the gate, work the facet's checklist(s); a
     facet with more than one lens applies each whose surface the diff raises, and the cap spans them
     all.
  3. **Floor, then cap, then tally the cap's drops** (hard-stops.md §2–3) — drop anything below
     `caps.floor`, keep at most `caps.top_n` most severe, and report `dropped` (how many genuine
     above-floor findings the cap held back) so nothing real vanishes unseen.
  4. **Return** per the Result and Finding schemas below.
- **What a facet does not do.** It does not **fix** what it finds. It does not **review beyond its
  own lens** — a smell in another facet's territory is that facet's, not a second report here. It
  does not **enumerate style nits** — the cap and floor are deliberate, and a long low-signal list is
  a failure, not thoroughness. It does not **flag already-sound or pre-existing code** — a defect the
  change neither introduces nor worsens is not a finding. A facet whose file adds a "what this does
  not do" section states only the boundaries **specific** to it (which sibling facet owns an adjacent
  concern); these generic ones are not repeated there.

## Request — orchestrator → facet

```
{
  change_ref:    <git ref / diff / path the review targets>,   // what to review
  spec_ref:      <path to a governing spec> | none,            // an anchor for intent, if one exists
  caps: {
    top_n: <int>,                 // report at most this many findings, most severe first
    floor: "low" | "med" | "high" // drop findings weaker than this bar
  }
}
```

The orchestrator resolves `change_ref` once and hands the same one to every facet — a shared read,
no shared writes, so parallel facets stay independent. `caps` are passed in, not hardcoded per
facet, so the discipline is tuned in one place.

## Result — facet → orchestrator

```
{
  facet:         <facet-skill name>,
  relevance:     "ran" | { skipped: <one-line reason> },   // decided FIRST, before any lens work
  findings:      [ Finding, ... ],   // already floored and capped to <= top_n; [] is a valid clean result
  dropped:       <int>               // genuine above-floor findings the cap held back beyond top_n; 0 when the cap wasn't hit — a count, never silently gone
}
```

A facet returns its findings **in-band**, in this result — there is no per-facet file; the
orchestrator reconciles every facet's result into the single report (SKILL.md step 6). A clean
change returns `findings: []`. That is a valid, complete result — not a facet that
gave up or missed something. The failure mode to guard against is the opposite reflex: reaching
for a hedged, sub-floor finding so the list is not empty. Padding a clean result with a finding
whose weaker of {severity, confidence} sits below `caps.floor` is not thoroughness — it is the
over-reporting the floor exists to stop. If the only thing a facet can find is below the floor,
the honest result is `[]`.

## Finding — the shared schema, every facet

```
{
  severity:   "high" | "med" | "low",
  confidence: "high" | "med" | "low",   // the floor drops anything below caps.floor on the weaker of the two
  location:   <file:line, or a symbol name>,
  claim:      <one sentence: what is wrong>,
  why:        <one sentence: the consequence, or the rule broken>,
  suggestion: <optional: the direction of a fix — never applied; guardtower is report-only>
}
```

`claim` and `why` must read on their own, for a reviewer who did not write the code and holds no
shared context.
