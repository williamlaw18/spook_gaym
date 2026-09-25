extends CharacterBody3D
## First-person player controller (Lethal Company-style view). Movement is
## smoothed rather than snappy: velocity eases toward the input direction,
## control is reduced in the air, and the camera bobs slightly with speed.
## See docs/policies/player-controller.md.

@export_group("Movement")
@export var walk_speed := 5.0
## How quickly velocity reaches walk_speed when input is held.
@export var acceleration := 12.0
## How quickly velocity falls off when input is released.
@export var deceleration := 10.0
## Multiplier on acceleration/deceleration while airborne (0 = no control).
@export_range(0.0, 1.0) var air_control := 0.3
@export var jump_velocity := 4.5

@export_group("Look")
@export var mouse_sensitivity := 0.002
@export var max_pitch_degrees := 89.0

@export_group("Head Bob")
## Set to 0 to disable.
@export var bob_amplitude := 0.04
@export var bob_frequency := 2.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _bob_distance := 0.0

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_head.rotate_x(-event.relative.y * mouse_sensitivity)
		var max_pitch := deg_to_rad(max_pitch_degrees)
		_head.rotation.x = clampf(_head.rotation.x, -max_pitch, max_pitch)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var target := (global_basis * Vector3(input_dir.x, 0.0, input_dir.y)) * walk_speed

	var rate := acceleration if input_dir != Vector2.ZERO else deceleration
	if not is_on_floor():
		rate *= air_control

	# Exponential ease toward the target, frame-rate independent.
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).lerp(target, 1.0 - exp(-rate * delta))
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()
	_update_head_bob(delta)


func _update_head_bob(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	var strength := clampf(speed / walk_speed, 0.0, 1.0) if is_on_floor() else 0.0
	_bob_distance += speed * delta

	var target := Vector3(
		cos(_bob_distance * bob_frequency * 0.5) * bob_amplitude,
		sin(_bob_distance * bob_frequency) * bob_amplitude,
		0.0
	) * strength
	_camera.position = _camera.position.lerp(target, 1.0 - exp(-10.0 * delta))
