# Core Loop

Status: draft

## Summary

The moment-to-moment and session-to-session loop the whole game is built
around:

1. **Descend** — enter a procedural cavern/dungeon from the homebase.
2. **Gather** — collect resources while evading or dealing with monsters
   down there, being ones the player previously created.
3. **Return** — bring resources back up to the surface factory before
   running out of time, health, or nerve.
4. **Craft** — assemble new monsters in layers: a base from soul-like
   resources, characteristics layered on from worldly materials, and
   optional modifiers from the sacrifice sub-chain. See
   `monster-creation.md` for the full pipeline.
5. **Release** — created monsters don't stay put; they enter the caverns
   below, becoming part of the threat pool for future descents.
6. **Repeat, deeper** — more monsters and resources unlock access to deeper,
   richer, and more dangerous cavern layers.

## Design notes

- The loop must always keep the gather/craft/create/descend cycle central.
  Any new system (upgrades, unlocks, meta-progression) should attach to one
  of these steps rather than introduce a parallel loop.
- Risk in the caverns should scale with how much the player has built at
  home, not just with depth — see `demon-and-corruption.md` for the
  corruption axis that ties these together.
- Return trips are a tension point (Lethal Company-style): the player should
  feel the pull to grab "one more resource" against the risk of not making
  it back.

## Open questions

- Exact pacing of how many descents are needed per monster tier.
- Whether resources are shared globally or per-run (roguelite reset vs.
  persistent base).
