# Monster Creation

Status: draft

## Summary

Monster creation is a three-layer pipeline, not a single fixed recipe. Each
layer is its own small resource sink with its own sourcing method:

1. **Base (soul)** — combine soul-like resources (found in the caverns, tied
   to the demon/corruption fiction) to form the base being. The base
   establishes the monster's core nature/foundation — what it fundamentally
   *is* before anything is layered onto it.
2. **Characteristics (worldly materials)** — layer combinations of ordinary
   worldly materials (mundane cavern/surface resources the player uncovers
   over time) onto the base. These determine the monster's physical
   characteristics and general capabilities.
3. **Modifiers (sacrifice)** — apply modifiers sourced from a separate
   sacrificial sub-chain: the player captures a creature and feeds it into
   a dedicated sacrifice device/ritual elsewhere in the factory, which
   converts it into a modifier resource. Modifiers are the twist layer —
   higher-risk, higher-impact changes layered on last.

A finished monster is therefore the product of a base + a set of
characteristics + (optionally) modifiers, not a single `resource -> monster`
lookup. Two monsters can share a base and diverge entirely based on which
characteristics and modifiers were layered on, or vice versa.

Every created monster, regardless of how it was assembled, still follows
the rest of the game's rules: it's released into the caverns below (see
`core-loop.md`), its full trait/behavior set is only learned through play
(see `monster-design.md`), and its darkness/severity trends with corruption
over time (see `demon-and-corruption.md`).

## Design notes

- Each layer should be a meaningfully separate crafting step/station in the
  factory, not one combined menu — this keeps the "layering" feel tactile
  and gives each resource type (soul / worldly / sacrificial) its own
  gathering and processing identity.
- The base layer likely gates which characteristics/modifiers are even
  compatible (a soul base could constrain the possibility space), so the
  system stays combinatorial rather than fully open, avoiding
  nonsensical or unbuildable combinations.
- The sacrifice sub-chain (capture -> feed -> modifier resource) is a
  system in its own right — see `sacrifice-system.md` for the capture and
  ritual/conversion details.
- Consider whether characteristics are the primary lever for "monster
  power/tier" (since worldly materials are the most plentiful/uncovered-
  over-time resource), while modifiers stay rarer and more consequential
  given the cost of sacrifice.

## Open questions

- Full taxonomy of soul-like resources, worldly materials, and sacrificial
  modifier resources, and how each is sourced/found.
- How many characteristics/modifiers can be layered onto a single base
  (fixed slots vs. open-ended stacking).
- Whether a base can be reused across multiple creation attempts or is
  consumed per monster.
- Whether modifiers can be applied post-creation (to an existing released
  monster) or only at initial assembly.
