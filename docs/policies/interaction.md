# Interaction

Status: draft

## Summary

The player uses things in the world by looking at them and pressing the
interact key (E). When something usable is in view and in range, a prompt
appears below the centre of the screen: "Press E to <verb>".

The first use is the cavern entrance in the homebase ("Press E to enter"),
which switches to the cavern mode.

## Implementation

Lives in `scenes/interaction/`. Three reusable pieces:

- **`Interactable`** (`interactable.gd`, an `Area3D`): marks something as
  usable. Sits on the `interactable` physics layer (layer 2) and emits
  `interacted(interactor)` when used. Exports:
  - `prompt`: the verb in the prompt ("enter", "interact", ...).
  - `interaction_range`: how close the player must be, from the camera to
    the point aimed at.
  - `enabled`: disabled interactables can't be focused or used.
  Subclasses can override `can_interact()` for conditional use.
- **`Interactor`** (`interactor.gd`, a `RayCast3D`): on the player's camera.
  Each physics frame it casts forward up to `reach` against the world
  (layer 1) and interactables, so walls block interaction. It emits
  `focus_changed(interactable)` and calls `interact()` on the focused
  interactable when the `interact` action is pressed. It ignores the
  player's own body.
- **`InteractionPrompt`** (`interaction_prompt.tscn`, a `Label`): listens to
  an `Interactor` and shows "Press <key> to <prompt>". The key comes from
  the `interact` input action, shown for the current keyboard layout, so it
  follows rebinding. Styling is on the scene and is a placeholder until the
  visual style covers UI.

The player scene has an `Interactor` under its camera and the prompt under
a `HUD` canvas layer, so both modes get interaction automatically.

### Making something interactable

1. Add an `Interactable` (Area3D with `interactable.gd`) as a child of the
   object, with a `CollisionShape3D` covering the part the player aims at.
   If it overlaps solid geometry, make the shape stand slightly proud of it
   so the ray reaches the area first.
2. Set `prompt` and, if needed, `interaction_range`.
3. Connect `interacted` in the object's own script and re-emit something
   meaningful (see `CavernEntrance.entered`). Mode-level changes go up
   through the mode's root (`Homebase.cavern_requested`) to `Main`, rather
   than objects reaching into `Main` directly.

### Cavern entrance

`scenes/homebase/cavern_entrance.tscn` (`CavernEntrance`): a placeholder
doorway with a black void, 8 m in front of the homebase spawn. Using it
disables its interactable and emits `entered`; `Homebase` re-emits it as
`cavern_requested`, and `Main` switches to the cavern (deferred, so the
homebase isn't freed mid-input). Running `homebase.tscn` on its own shows
the prompt, but nothing switches since `Main` isn't there.

## Open questions

- What the cavern entrance actually is in the fiction and how it looks
  (the doorway is placeholder), and how the player returns to the surface
  (F3 is still the dev shortcut).
- Whether entering needs confirmation, a transition or loading screen.
  Cavern generation currently freezes the game for a few seconds on entry.
- Whether interactables should highlight when focused, and whether there's
  a crosshair.
- Hold-to-interact, or multiple actions on one object.
- Gamepad prompts (the prompt currently only knows keyboard keys well).
