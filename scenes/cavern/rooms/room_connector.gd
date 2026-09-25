@tool
class_name RoomConnector
extends Marker3D
## An opening in a cavern room that a tunnel can attach to. Any tunnel type
## can attach to any opening. Place it on a face of the room's shell, at the
## centre of the opening's floor edge, with -Z (forward) pointing out of the
## room. Its outline and an outward arrow are drawn in the editor.

## Width and height of the opening (metres).
@export var size := Vector2(3.0, 3.0):
	set(value):
		size = value
		_update_gizmo()

var _gizmo: MeshInstance3D


func _ready() -> void:
	_update_gizmo()


func _update_gizmo() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if _gizmo == null:
		_gizmo = MeshInstance3D.new()
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.no_depth_test = true
		material.albedo_color = Color(1.0, 0.8, 0.2)
		_gizmo.material_override = material
		add_child(_gizmo, false, Node.INTERNAL_MODE_BACK)

	var half := size.x * 0.5
	var mid := Vector3(0.0, size.y * 0.5, 0.0)
	var tip := mid + Vector3(0.0, 0.0, -1.5)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for line in [
		[Vector3(-half, 0, 0), Vector3(half, 0, 0)],
		[Vector3(half, 0, 0), Vector3(half, size.y, 0)],
		[Vector3(half, size.y, 0), Vector3(-half, size.y, 0)],
		[Vector3(-half, size.y, 0), Vector3(-half, 0, 0)],
		[mid, tip],
		[tip, tip + Vector3(0.3, 0.0, 0.4)],
		[tip, tip + Vector3(-0.3, 0.0, 0.4)],
	]:
		mesh.surface_add_vertex(line[0])
		mesh.surface_add_vertex(line[1])
	mesh.surface_end()
	_gizmo.mesh = mesh
