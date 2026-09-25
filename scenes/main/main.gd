extends Node
## Entry point. Holds whichever mode is active: the surface homebase or the
## caverns below. The two are kept as separate scenes because they are
## distinct modes with different tension levels (Core Tenet 2).
## See docs/policies/core-loop.md.

const HOMEBASE_SCENE := preload("res://scenes/homebase/homebase.tscn")
const CAVERN_SCENE := preload("res://scenes/cavern/cavern.tscn")

var _current_mode: Node


func _ready() -> void:
	go_to_homebase()


func _unhandled_input(event: InputEvent) -> void:
	# Placeholder dev shortcut, mainly for getting back up until returning is
	# designed.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		if _current_mode.scene_file_path == HOMEBASE_SCENE.resource_path:
			go_to_cavern()
		else:
			go_to_homebase()


func go_to_homebase() -> void:
	_switch_mode(HOMEBASE_SCENE)


func go_to_cavern() -> void:
	_switch_mode(CAVERN_SCENE)


func _switch_mode(scene: PackedScene) -> void:
	if _current_mode:
		_current_mode.queue_free()
	_current_mode = scene.instantiate()
	if _current_mode is Homebase:
		# Deferred so the homebase isn't freed mid-way through the input
		# event that triggered the switch.
		_current_mode.cavern_requested.connect(go_to_cavern, CONNECT_DEFERRED)
	add_child(_current_mode)
