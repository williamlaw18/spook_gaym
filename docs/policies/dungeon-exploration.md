# Dungeon Exploration

Status: draft

## Summary

Below the homebase are procedurally generated caverns/dungeons, explored
first-person/third-person in the style of Lethal Company: the player enters,
gathers resources, and must decide when to push further versus retreat.

The threats in these caverns are not generic spawns — they are, at least in
part, the same monsters the player has created at the homebase and released.
Exploration is therefore a direct consequence of the player's own
progression: the more successful the player has been at creating monsters,
the more dangerous their own caverns become.

## Design notes

- Procedural generation should support escalating depth tiers, each with
  richer resources and a denser/tougher threat pool.
- Player tools/abilities for this mode (lighting, traversal, combat vs.
  stealth/evasion) need to support the "one more resource, or retreat"
  tension called out in `core-loop.md`.
- As corruption escalates (see `demon-and-corruption.md`), caverns should
  visibly change: fissures/cracks opening up, exposing new resource types
  alongside new hazards.
- Consider whether specific player-created monsters can be "tracked" or
  recognized in the caverns (e.g., a monster the player made feels
  different to encounter than a native cavern creature).

## Open questions

- Generation algorithm/approach (tile-based, room-graph, etc.) — not yet
  decided.
- How depth tiers gate progression (resource-locked, monster-tier-locked, or
  both).
- Whether death/failure in a descent has permanent consequences (lost
  resources, lost monsters, run reset) or is purely a setback.
