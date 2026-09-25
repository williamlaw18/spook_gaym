class_name ImpossibleLink
extends Node
## Joins two identical S-bend "locks" in different parts of a cavern. Walking
## forward through the centre of lock A puts the player at the same spot in
## lock B; walking back through B's centre returns them to A. Both locks mesh
## identically and their bends hide what lies beyond, so the jump is seamless.
## See docs/policies/dungeon-exploration.md.

## Half-width of the teleport plane at each lock's centre, in local X, and
## its height range above and below the lock's floor.
const HALF_WIDTH := 3.0
const MIN_HEIGHT := -2.0
const MAX_HEIGHT := 6.0

var lock_a: Transform3D
var lock_b: Transform3D
var player: CharacterBody3D

var _prev_a := 0.0
var _prev_b := 0.0


func _ready() -> void:
	_store_positions()


func _physics_process(_delta: float) -> void:
	var local_a := lock_a.affine_inverse() * player.global_position
	var local_b := lock_b.affine_inverse() * player.global_position
	if _prev_a < 0.0 and local_a.z >= 0.0 and _within_plane(local_a):
		_teleport(lock_a, lock_b)
	elif _prev_b >= 0.0 and local_b.z < 0.0 and _within_plane(local_b):
		_teleport(lock_b, lock_a)
	_store_positions()


func _store_positions() -> void:
	_prev_a = (lock_a.affine_inverse() * player.global_position).z
	_prev_b = (lock_b.affine_inverse() * player.global_position).z


func _within_plane(local: Vector3) -> bool:
	return absf(local.x) < HALF_WIDTH and local.y > MIN_HEIGHT and local.y < MAX_HEIGHT


func _teleport(from: Transform3D, to: Transform3D) -> void:
	var offset := to * from.affine_inverse()
	player.global_transform = offset * player.global_transform
	player.velocity = offset.basis * player.velocity
