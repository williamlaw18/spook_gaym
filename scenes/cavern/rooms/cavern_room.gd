@tool
class_name CavernRoom
extends Node3D
## A preset room the cavern generator can place. Rooms are built by hand (CSG
## works well) and listed in CavernSettings.rooms.
##
## - The shell is a CSGBox3D: the room's solid outer block. Its box is the
##   room's bounds; tunnel surfaces inside it are cut away, and its outer
##   faces show around each opening, so rooms bring their own walls.
## - RoomConnector children (direct children of this node) mark the openings
##   tunnels attach to. Each sits on a shell face, with its opening cut
##   through the shell. Keep them a few metres from the shell's edges so a
##   wide tunnel's end still lands on that face.
## - The room is only ever rotated in 90 degree steps, so openings should face
##   along the X or Z axis.
## See docs/policies/dungeon-exploration.md.

@export_node_path("CSGBox3D") var shell_path := NodePath("Shell")


## The shell's box, in this node's space.
func get_bounds() -> AABB:
	var shell := get_node_or_null(shell_path) as CSGBox3D
	if shell == null:
		push_warning("%s: shell_path doesn't point at a CSGBox3D." % name)
		return AABB()
	return _relative_transform(shell) * AABB(-shell.size * 0.5, shell.size)


func get_connectors() -> Array[RoomConnector]:
	var result: Array[RoomConnector] = []
	for child in get_children():
		if child is RoomConnector:
			result.append(child)
	return result


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not get_node_or_null(shell_path) is CSGBox3D:
		warnings.append("shell_path must point at a CSGBox3D.")
		return warnings
	var connectors := get_connectors()
	if connectors.is_empty():
		warnings.append("Add at least one RoomConnector as a direct child.")
	var bounds := get_bounds()
	for c in connectors:
		var p := c.position
		var on_face := false
		for axis in 3:
			if is_equal_approx(p[axis], bounds.position[axis]) or is_equal_approx(p[axis], bounds.end[axis]):
				on_face = true
		if not on_face:
			warnings.append("%s isn't on a face of the shell." % c.name)
	return warnings


func _relative_transform(node: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	while node != null and node != self:
		xf = node.transform * xf
		node = node.get_parent() as Node3D
	return xf
