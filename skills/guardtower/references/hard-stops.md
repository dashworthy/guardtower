# The hard stops

Three stops keep a facet from spending tokens on low-value work. All three run **inside the facet,
at the source** — before it returns — never as trimming the orchestrator does afterward. That
placement is the whole point: a cap applied after the facet has already scanned
everything saves output, not tokens; a gate the facet runs first saves the scan.

There is deliberately **no numeric token ceiling.** Discipline comes from what is worth doing and
reporting, not from a blunt cutoff mid-thought.

## 1. Relevance gate — decided first

Before any lens work, the facet asks: *does this change even warrant me?* A docs-only diff does not
warrant the Security facet; a three-line copy change does not warrant the Architectural facet. If
the answer is no, the facet returns `relevance: { skipped: <reason> }` immediately, having spent
almost nothing, and writes an artifact recording the skip. This is the single largest saver — it
skips whole reviews.

## 2. Top-N severity cap

When the facet runs, it reports at most `caps.top_n` findings, most severe first, then stops. It
does not enumerate every nit it could name. If there are more than `top_n` genuine findings, the
`top_n` most severe are the ones that matter first; the rest can surface on a re-run after those
are addressed.

But "can surface on a re-run" is only honest if the reader knows they exist. The cap orders and
defers; it must never *hide*. So a facet that hits the cap reports **`dropped`** — the count of
genuine, above-floor findings it held back beyond `top_n` — alongside its findings. `dropped` is
`0` when the cap wasn't reached. A capped list that looks complete is the cap lying: a reader who
cannot see that four more real findings wait behind it cannot choose to re-run for them. The
count is the difference between deferral the human can act on and deferral that silently vanishes.
(The floor's drops in §3 are low-confidence or cosmetic noise excluded by design, not deferred
work; `dropped` counts what the *cap* set aside, not what the floor excluded.)

## 3. Confidence / severity floor

The facet drops any finding weaker than `caps.floor` before it returns — low-confidence guesses
and cosmetic nits do not reach the report. The floor applies to the **weaker** of a finding's
severity and confidence: a high-severity but low-confidence hunch scores `low` on the weaker axis
and is held, not asserted, exactly as a low-severity/high-confidence nit is.

This is a drop, not a hedge. A facet does not get to keep a sub-floor finding by wording it
cautiously — "possibly," "might be worth a look," "low confidence, but…". A finding whose weaker
axis is below the floor is not reported at all; a report that carries one has *failed* the floor,
which is the single most common way a facet over-reports. Reaching for a hedged, below-floor
finding rather than returning an empty list is itself the failure mode the floor exists to prevent:
a clean change is a valid, expected result (see `facet-contract.md`), and manufacturing a weak
finding to avoid an empty report is exactly what the floor stops.

**Speculation guard.** A hazard is only as real as the code that would trigger it. A finding whose
realization depends on code *outside the change under review* — a hypothetical caller, an unproven
path, a value some absent code might pass — is capped at **low confidence**, because nothing in the
diff demonstrates it. At a floor of `med` or above, that cap drops it. This is what stops a facet
from reporting, for instance, an authorization hazard about a caller that does not exist in the
change: the review judges the code in front of it, not code it imagines around it.

Fewer, higher-signal findings beat a long list a reader has to triage.

## Together

A facet that self-enforces all three returns quickly when it is not needed, and returns a short,
high-signal, ordered list when it is — which is exactly the budget the plugin promises.
