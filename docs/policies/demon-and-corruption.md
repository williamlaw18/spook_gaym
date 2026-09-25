# The Demon & Corruption

Status: draft

## Summary

An ancient demon, sealed or dormant beneath the world, wants to consume it.
The demon feeds on chaos, and is placated (for now) by the terrifying
monsters the player creates. The entire game's activity — building the
factory, creating monsters, descending into the caverns — is nominally in
service of keeping this demon fed/satisfied.

But feeding the demon isn't free: as it grows weary/restless, the world
corrupts. This is the mechanism that ties long-term progression to
increasing difficulty:

- Fissures and cracks open in the world/caverns, exposing new (better)
  resources alongside new dangers.
- Existing systems (monsters, resources, maybe the caverns themselves) trend
  toward becoming more evil/corrupted over time.
- This escalation is visible and diegetic, not a hidden difficulty slider.

## Endgame

The game should build toward a real choice regarding the demon:

- **Feed it** — keep providing chaos/monsters, presumably following that
  path to its own (likely bad) conclusion.
- **Destroy it** — turn against the demon, using the monsters and resources
  built up over the game as leverage instead.

Both paths need to be designed as legitimate endings with distinct
mechanical and narrative weight — see Core Tenet 6 in `AGENTS.md`.

## Tone Curve

Corruption isn't just a difficulty axis — it's the game's horror-reveal
mechanism. The game should open low-key: early monsters are mundane, even
a little cute, and the world feels closer to a cozy creature-collector than
a horror game (cookie-clicker-style innocuous start). As corruption climbs,
monster trait pools and world state should shift toward the disturbing and
horrific (see `monster-design.md`), so the horror tone is something the
game grows into rather than opens with. This is Core Tenet 7 in `AGENTS.md`.

## Design notes

- Corruption should likely be tracked as a global, visible axis (not per-
  monster only) so its effects on the world are legible to the player.
- Corruption's effect on monster creation and cavern generation should be
  cross-referenced with `monster-creation.md` and `dungeon-exploration.md`
  as those systems firm up.
- Consider pacing: corruption should escalate with player progress
  (monsters created / depth reached), not on a flat timer, to keep the
  causal link between "you did this" and "the world is worse" intact.

## Open questions

- What triggers corruption increases exactly (monster count? monster tier?
  depth reached? time?).
- Mechanical differences between the two endings — is it a final
  confrontation, a resource sink, a moral-choice cutscene-only branch, or
  something with earlier build-up?
- Whether corruption is reversible/manageable mid-game or strictly one-way
  until the endgame choice.
