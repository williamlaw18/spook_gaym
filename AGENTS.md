# AGENTS.md

This file is the entry point for understanding the game: what it is, the rules
that govern its design, and where to find deeper documentation. Read this
before making design or implementation decisions. When a decision isn't
covered here, check the relevant policy doc in `docs/policies/`; if nothing
covers it, treat the gap as something to flag and document once resolved.

## Overview

Working title: **Spook Gaym**

Genre: horror-first. A spooky-monster factory/survival hybrid: Slime
Rancher's creature-collecting and base-building, mixed with Lethal Company's
tense procedural-dungeon scavenging. Visually, simple PS1/PS2-era 3D —
low-poly, low-res textures, dark, and a bit "crispy" (grain/dither/CRT-ish
artifacting), leaning into that era's inherent unease. See
`docs/policies/visual-style.md`.

The player runs a homebase (factory/house) on the surface. Below it lie
procedural caverns and dungeons full of resources. Resources are hauled back
to the surface and layered together to create procedural monsters: a **foundation** (from
soul-like resources), **characteristics** (from worldly resources), and
optional **modifiers** (from a blood scrifice sub-chain — capturing a creature
and feeding it into a ritual device). See `docs/policies/monster-creation.md`
and `docs/policies/sacrifice-system.md`. More monsters and more resources
unlock deeper exploration and further progression.

The hook: monsters you create don't stay in the homebase. They go on to lurk
in the caverns below — the same caverns you must keep entering to gather more
resources. Every monster you make to progress is also a threat you (or a
future run) must survive. Growth and danger scale together by design.

All of this is in service of appeasing (or eventually confronting) an ancient
demon that wants to consume the world. The demon feeds on chaos and is
placated by more, and more terrifying, monsters — but the more it's fed, the
more it stirs, and the world corrupts around the player: fissures and cracks
open in the caverns, exposing richer resources alongside greater danger. The
endgame is tied to a choice about the demon: give it what it wants, or turn
against it.

The tone follows a slow burn: the first monsters the player creates are
fairly mundane, even a little cute — a cookie-clicker-style innocuous start.
As corruption grows, creations trend darker and more disturbing, so the game
gradually reveals itself as a horror game rather than opening as one. See
`docs/policies/demon-and-corruption.md` for the escalation curve and
`docs/policies/monster-design.md` for how individual monsters are designed
and generated.

## Core Tenets

These are non-negotiable design rules. Anything built for the game should be
checked against them.

1. **Creation is the difficulty curve.** The player's own progression
   (building more monsters) is what makes the game harder, not external
   scaling alone. Systems should reinforce this trade-off, not paper over it.
2. **The surface is safe(ish), the depths are not.** Homebase/factory
   management and cavern exploration are distinct modes with different
   tension levels. Don't blur them without a reason tied to the demon/
   corruption arc.
3. **Every monster the player creates must be able to exist as a threat in
   the caverns.** No creature should be "just" a base decoration or "just" a
   dungeon enemy — the dual-purpose nature is the point.
4. **Corruption is a visible, escalating consequence**, not a hidden stat.
   As the demon grows restless, the world should visibly change (fissures,
   corrupted resources, mutated monsters) so the player feels the cost of
   progression.
5. **Resource loop drives everything.** Gather below, spend above, create,
   repeat. New systems should slot into this loop rather than compete with it.
6. **The demon's endgame must stay a real choice.** Placate or oppose — both
   paths need to be viable and meaningfully different, not one "true" ending
   with a token alternative.
7. **Horror is earned, not front-loaded.** Start mundane, escalate to
   disturbing. Early monsters and spaces should feel low-key; the horror
   tone should build alongside corruption, not saturate the game from
   minute one.
8. **A monster's personality is discovered, not read off a stat sheet.**
   Traits and behavior are generated procedurally but revealed to the
   player only through playing with/against that specific monster — no
   up-front spec sheets. See `docs/policies/monster-design.md`.
9. **Visuals stay PS1/PS2-era and grimy.** Low-poly, low-res, dark, and a
   little "crispy" (grain/dither/artifacting) — the aesthetic should support
   the horror tone, not compete with it. See `docs/policies/visual-style.md`.

## Core Loop (summary)

1. Descend into a procedural cavern/dungeon from the homebase.
2. Gather resources while avoiding/evading monsters that lurk there
   (including ones the player previously created).
3. Return resources to the surface factory.
4. Assemble new monsters in layers: base (soul) -> characteristics (worldly
   materials) -> optional modifiers (sacrifice). See `monster-creation.md`.
5. New monsters strengthen the base but are released into the caverns below,
   raising the danger for future descents.
6. Corruption escalates over time/progression, altering caverns, resources,
   and monsters, and moving the player toward a choice about the demon.

See `docs/policies/` for detailed docs on each system as they're written.

## Policy Index

Documents in `docs/policies/` are the source of truth for specific systems.
This index should be kept up to date as docs are added or renamed.

| Doc | Covers |
|---|---|
| [`core-loop.md`](docs/policies/core-loop.md) | Detailed breakdown of the gather → craft → create → descend loop |
| [`monster-creation.md`](docs/policies/monster-creation.md) | Base/characteristics/modifiers creation pipeline, how created monsters enter the world |
| [`sacrifice-system.md`](docs/policies/sacrifice-system.md) | Capture -> sacrifice -> modifier resource sub-chain |
| [`dungeon-exploration.md`](docs/policies/dungeon-exploration.md) | Procedural cavern generation, player tools, stealth/evasion vs. hunting monsters |
| [`demon-and-corruption.md`](docs/policies/demon-and-corruption.md) | The demon, chaos/corruption escalation, and the endgame choice |
| [`monster-design.md`](docs/policies/monster-design.md) | Procedural trait/appearance generation, creepypasta influences, trait discovery through play |
| [`visual-style.md`](docs/policies/visual-style.md) | Art direction: PS1/PS2-era look, dark/crispy rendering treatment |

## Working Agreement

- New mechanics, modules, or major decisions get documented in
  `docs/policies/` as they're designed, not after the fact.
- Keep the Policy Index above in sync with the contents of `docs/policies/`.
- If a policy doc contradicts this file, this file wins for tenets; the
  policy doc wins for system-specific detail. Resolve conflicts by editing,
  not by ignoring one side.
- **AI agents do not manage git.** No committing, staging, pushing,
  branching, or other git operations on behalf of the developer. Git stays
  entirely in the developer's hands; agents only edit files.
