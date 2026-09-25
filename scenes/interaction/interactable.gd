class_name Interactable
extends Area3D
## Something the player can look at and use. Add it as a child of the thing
## being used, give it a CollisionShape3D covering the part the player should
## aim at, and connect `interacted`. The player's Interactor finds it by
## raycast on the "interactable" physics layer.
## See docs/policies/interaction.md.

## Emitted when the player uses this.
signal interacted(interactor: Interactor)

## Physics layer 2, named "interactable" in the project settings.
const LAYER := 1 << 1

## Verb shown in the prompt: "Press E to <prompt>".
@export var prompt := "interact"
## How close the player has to be, in metres, measured from the camera to
## the point they're aiming at. Capped by the Interactor's reach.
@export var interaction_range := 2.5
## Disabled interactables can't be focused or used.
@export var enabled := true


func _init() -> void:
	# Only exists to be found by the Interactor's ray; it never detects
	# anything itself. Enforced at runtime so a new Interactable works without
	# touching its layers (the editor won't show this until it's set there).
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false


func can_interact(_interactor: Interactor) -> bool:
	return enabled


func interact(interactor: Interactor) -> void:
	if can_interact(interactor):
		interacted.emit(interactor)
