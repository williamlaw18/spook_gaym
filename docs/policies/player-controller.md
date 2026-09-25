# Player Controller

Status: draft

## Summary

The player is first-person, in the style of Lethal Company, but with
movement that feels a bit more fluid than a snappy start/stop controller.

Implemented in `scenes/player/` (`player.tscn` + `player.gd`):

- WASD movement, mouse look, jump, gravity.
- Velocity eases toward the input direction (separate acceleration and
  deceleration rates) instead of snapping, using frame-rate independent
  exponential smoothing.
- Reduced control while airborne (`air_control` multiplier).
- Subtle camera head bob scaled by ground speed (amplitude can be set to 0).
- Mouse is captured on start; Esc releases it, clicking recaptures it.
- E interacts with whatever is in view; the player carries an `Interactor`
  and the interaction prompt (see `interaction.md`).

All tuning values are exported on the `Player` node for iteration in the
editor.

## Open questions

- Sprint, crouch, stamina, or any other movement abilities — these tie into
  the undecided evasion toolset in `dungeon-exploration.md`, so they're not
  implemented yet.
- Whether movement differs between the homebase and the caverns.
- Controller/gamepad support and rebindable controls.
