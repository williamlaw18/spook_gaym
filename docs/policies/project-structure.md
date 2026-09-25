# Project Structure

Status: draft

## Summary

Technical layout of the Godot project (Godot 4.7, GDScript, Forward+,
Jolt Physics). This covers where things live in the codebase, not game
design.

## Layout

```
scenes/
  main/       Entry scene (run/main_scene). Holds the active mode and
              swaps between homebase and cavern.
  homebase/   Surface homebase/factory mode, including the cavern
              entrance.
  cavern/     Procedural cavern mode.
    generation/  Layout, distance field and meshing (see
                 dungeon-exploration.md).
    rooms/       Preset room scenes and their scripts.
    tunnels/     Tunnel type resources and their scripts.
  player/     First-person player controller (see player-controller.md).
  interaction/  Reusable Interactable / Interactor / prompt (see
                interaction.md).
docs/policies/  Design source of truth (see AGENTS.md Policy Index).
```

- Each scene keeps its script alongside it in the same folder
  (`name.tscn` + `name.gd`).
- The homebase and caverns are separate scenes rather than one shared
  world, reflecting the surface/depths split (Core Tenet 2). `Main` owns
  whichever one is active; `go_to_homebase()` / `go_to_cavern()` switch
  between them. Modes ask for a switch by signal (e.g.
  `Homebase.cavern_requested`, from the cavern entrance) and `Main`
  connects to it; modes never call `Main` directly. F3 toggles modes as a
  placeholder dev shortcut until returning to the surface is designed.
- Physics layers: 1 `world`, 2 `interactable`.
- New systems get their own folder under `scenes/` (or a sibling top-level
  folder if they aren't scene-based) once they're designed in their policy
  doc.

## Open questions

- Where cross-mode state lives (resources carried between modes, corruption,
  released monsters) — e.g. autoload singleton(s) vs. state owned by
  `Main`. Depends on the persistence question in `core-loop.md`.
- Rendering setup for the PS1/PS2 look (see `visual-style.md`).
