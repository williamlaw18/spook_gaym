# Dungeon Exploration

Status: draft

## Summary

Below the homebase are procedurally generated caverns/dungeons, explored in
the style of Lethal Company: the player descends, gathers resources, and
must decide when to push further versus retreat.

The threats in these caverns are not generic spawns — they are, at least in
part, the same monsters the player has assembled at the homebase and
released (see `monster-creation.md`). Exploration is therefore a direct
consequence of the player's own progression: the more the player has
created, the more dangerous their own caverns become (Core Tenet 1).

The player is not built to fight — evasion, not combat, is the intended
stance against threats in the caverns.

Extraction pressure comes from two things combined: limited carry capacity
(forcing return trips) and danger that escalates the longer the player
stays on a descent.

## Procedural Generation

The caverns should not read as square/gridded. Layouts are winding and
confusing — non-Euclidean in feel, meant to disorient rather than lay out
cleanly.

Occasionally (not often — a rare, deliberate occurrence rather than a
constant gimmick), the layout should do something physically impossible:
going one way brings you out somewhere that shouldn't be reachable from
where you went in, portal-games-style. This is meant to feel trippy and
uncanny, reinforcing the horror/visual-strangeness tone, not to be a
frequent puzzle mechanic.

**Confusion as a parameter.** The idea being explored: "confusion" (how
winding/tricky/non-Euclidean a layout is) is a variable parameter to
generation, not a fixed baseline. Depth increases confusion the deeper you
go. World corruption acts as a modifier on top of that depth-driven
confusion — corruption doesn't just add its own separate effect, it
amplifies whatever confusion is already there (a simple layout becomes
moderately complex, an already-complex layout becomes wildly complex).
Confusion might also not be uniform across a whole layer — certain areas of
a layer, or proximity to certain kinds of monsters, could locally run a
higher confusion value than the rest of that layer. This is still an idea
being explored, not a locked design.

## Open questions

Everything below is undecided and needs to be discussed, not assumed.

- What tools/abilities does the player actually have for evasion?
- How does capture (for the sacrifice sub-chain) work as a mechanic,
  separate from evasion?
- What exactly drives escalating danger over time, and how is carry
  capacity structured?
- How the winding/non-Euclidean layout is actually generated (algorithm/
  approach) — not yet decided.
- How the occasional "impossible" transitions are implemented and how rare
  "occasional" should be in practice.
- How confusion is actually calculated/combined from depth + corruption
  (formula, curve, caps) and how local confusion "hotspots" (areas/monster
  proximity) would work mechanically.
- Whether there are depth tiers, and if so how they're structured/gated.
- What failure/death during a descent actually costs the player.
- How corruption (if at all) touches the caverns specifically.
- Whether/how the player can tell their own created monsters apart from
  other cavern creatures.
