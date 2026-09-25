# Monster Design

Status: draft

## Summary

Each created monster is a procedurally generated individual, assembled from
the base/characteristics/modifiers layers described in
`monster-creation.md` rather than being a fixed, hand-authored creature per
recipe. This doc covers how that assembly translates into concrete traits,
appearance, and behavior — i.e., what actually comes out the other end of
the base + characteristics + modifiers pipeline. Two monsters built from
the same base, or the same characteristic materials, can still end up
looking and acting differently.

Traits draw stylistic influence from current creepypasta/internet-horror
aesthetics — the kind of imagery and behavioral tropes associated with
well-known creepypasta creatures (uncanny proportions, wrong movement,
familiar-but-off appearances, etc.) — used as a vibe/reference pool rather
than direct copies of specific named characters.

Critically: the player does not get a spec sheet when a monster is created.
Its traits and behaviors are **learned through experience** — by observing,
encountering, and surviving that specific monster in the caverns. This
supports Core Tenet 8 (personality is discovered, not read off a stat
sheet) and reinforces the horror tone (not knowing what a thing does until
it does it to you).

## Design notes

- Traits are driven by which base, characteristics, and modifiers went into
  a monster (see `monster-creation.md`), not fully random rolls — the base
  likely governs core temperament/nature, worldly characteristics govern
  physical traits/capabilities, and sacrificial modifiers govern the
  riskier/rarer twists. The player influences the outcome by choosing
  ingredients, but the precise resulting trait expression should still stay
  unpredictable enough to require discovery through play.
- Trait pool severity/darkness should scale with the corruption axis (see
  `demon-and-corruption.md`) — early monsters draw from milder trait pools,
  later monsters draw from more disturbing ones. This is the mechanical
  backbone of Core Tenet 7 (horror is earned).
- "Learned through experience" implies some in-game system for tracking
  what the player has observed about a given monster — a bestiary/journal
  that fills in as traits are witnessed, rather than being available
  up-front.
- Keep individual monster instances distinguishable — since traits are
  per-instance, the player should be able to tell "this specific one" apart
  from others of the same recipe once they've learned its traits.

## Open questions

- Full taxonomy of trait categories and how many traits compose one
  monster.
- How "creepypasta-inspired" translates into a reusable trait/asset pipeline
  without leaning on any single copyrighted character.
- Mechanics for the bestiary/journal: is it purely lore/flavor, or does
  learning a trait unlock gameplay benefits (e.g., counters/strategies)?
- Whether trait generation is seeded per-monster at creation time, or can
  drift/mutate later under corruption.
