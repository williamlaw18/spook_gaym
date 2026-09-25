class_name Interactor
extends RayCast3D
## Finds the Interactable the player is looking at and uses it when the
## "interact" action is pressed. Attach to the camera so the ray follows the
## view. World geometry blocks the ray, so nothing is used through a wall.
## See docs/policies/interaction.md.

## Emitted when the focused Interactable changes (null when there is none).
signal focus_changed(interactable: Interactable)

## Longest reach of any interaction. Each Interactable sets its own range
## within this.
@export var reach := 4.0

## The Interactable currently in view and in range, or null.
var focused: Interactable


func _ready() -> void:
	target_position = Vector3.FORWARD * reach
	collide_with_areas = true
	collide_with_bodies = true
	# World (1) so walls block the ray, plus interactables.
	collision_mask = 1 | Interactable.LAYER
	# Ignore whoever is carrying this (the player's own body).
	var node := get_parent()
	while node:
		if node is CollisionObject3D:
			add_exception(node)
			break
		node = node.get_parent()


func _physics_process(_delta: float) -> void:
	_set_focused(_find_target())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and focused:
		get_viewport().set_input_as_handled()
		focused.interact(self)


func _find_target() -> Interactable:
	force_raycast_update()
	var interactable := get_collider() as Interactable
	if not interactable or not interactable.can_interact(self):
		return null
	if global_position.distance_to(get_collision_point()) > interactable.interaction_range:
		return null
	return interactable


func _set_focused(interactable: Interactable) -> void:
	if interactable == focused:
		return
	focused = interactable
	focus_changed.emit(focused)
