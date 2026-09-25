extends Node3D
## The procedural caverns below the homebase: the dangerous mode. Resources
## are gathered here while evading the monsters the player has released.
## See docs/policies/dungeon-exploration.md.

## Seed for the layout. 0 picks a random one each time.
@export var generation_seed := 0
@export_range(1, 20) var depth := 1
@export_range(0.0, 1.0) var corruption := 0.0
@export var settings := CavernSettings.new()

## The most recently generated layout.
var layout: TunnelLayout

var _generated: Node3D
var _map: DebugMap

@onready var _player: CharacterBody3D = $Player
@onready var _map_hint: Control = $DebugHintLayer/DebugMapHint


func _ready() -> void:
	var map_layer := CanvasLayer.new()
	map_layer.name = "DebugMapLayer"
	_map = DebugMap.new()
	_map.player = _player
	map_layer.add_child(_map)
	add_child(map_layer)
	# The open map lists its own controls, so the hint only shows while it's closed.
	_map.visibility_changed.connect(func() -> void: _map_hint.visible = not _map.visible)
	generate()


func _unhandled_input(event: InputEvent) -> void:
	# Placeholder dev shortcut: regenerate with a fresh random seed.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		generation_seed = 0
		generate()


func generate() -> void:
	var start := Time.get_ticks_msec()
	if _generated:
		remove_child(_generated)
		_generated.queue_free()
	_generated = Node3D.new()
	_generated.name = "Generated"
	add_child(_generated)

	var rng := RandomNumberGenerator.new()
	rng.seed = generation_seed if generation_seed != 0 else randi()
	var used_seed := rng.seed

	var confusion := ConfusionField.new(settings, depth, corruption, rng, settings.main_tunnel_length * 0.4)
	layout = TunnelLayout.new()
	layout.generate(settings, confusion, rng)

	var margin := settings.noise_amplitude + settings.blend + settings.cell_size * 2.0 + 0.5
	var sdf := CaveSdf.new(layout, settings, rng.randi(), margin)
	var colors := PackedColorArray()
	for type in layout.types:
		colors.append(type.color)
	var arrays := SurfaceNets.build(sdf, layout, settings.cell_size, margin, colors)

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Placeholder surface: each tunnel type's colour is baked into the vertices.
	var surface := StandardMaterial3D.new()
	surface.vertex_color_use_as_albedo = true
	surface.roughness = 1.0
	mesh.surface_set_material(0, surface)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	_generated.add_child(mesh_instance)

	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(SurfaceNets.faces(arrays))
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var body := StaticBody3D.new()
	body.add_child(collision)
	_generated.add_child(body)

	for room in layout.rooms:
		var node := room.scene.instantiate() as Node3D
		node.transform = room.transform
		_generated.add_child(node)

	_spawn_player()

	for pair: Array in layout.links:
		var link := ImpossibleLink.new()
		link.lock_a = pair[0]
		link.lock_b = pair[1]
		link.player = _player
		_generated.add_child(link)

	_map.layout = layout
	_map.confusion = confusion
	_map.info = "seed %d   depth %d   corruption %.2f   confusion %.2f" % [used_seed, depth, corruption, confusion.layer_confusion]

	print("Cavern: seed %d, depth %d, corruption %.2f, confusion %.2f | %d segments, %d rooms, %d type changes, %d branches, %d loops, %d dead ends, %d impossible links | %d triangles | %d ms" % [
		used_seed, depth, corruption, confusion.layer_confusion,
		layout.segment_count(), layout.rooms.size(), layout.type_changes, layout.branches, layout.loops, layout.dead_ends, layout.links.size(),
		(arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3,
		Time.get_ticks_msec() - start,
	])


func _spawn_player() -> void:
	# The entrance is on the tunnel floor.
	_player.global_position = layout.entrance + layout.entrance_heading * 1.5 + Vector3.UP * 0.1
	_player.rotation = Vector3.ZERO
	_player.velocity = Vector3.ZERO
