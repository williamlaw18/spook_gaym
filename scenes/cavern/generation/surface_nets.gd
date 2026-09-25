class_name SurfaceNets
extends RefCounted
## Meshes a CaveSdf over a sparse grid (only cells near tunnels are sampled).
##
## Rounded tunnels use naive surface nets: each surface cell's vertex is the
## average of where the surface crosses the cell's edges, giving a smooth,
## low-poly organic surface. Cells touching sharp geometry (box tunnels, room
## mouths) use dual contouring instead: the vertex goes where the crossing
## planes meet, which keeps walls flat and corners hard, and those faces are
## flat shaded. Surfaces inside rooms are cut away, since rooms bring their
## own geometry. Each vertex is coloured by the tunnel type nearest to it.

const CORNERS := [
	Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(1, 1, 0),
	Vector3i(0, 0, 1), Vector3i(1, 0, 1), Vector3i(0, 1, 1), Vector3i(1, 1, 1),
]
const AXES := [Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1)]
## For each axis, the four cells sharing a grid edge along it (as offsets
## subtracted from the edge's start point), in order around the edge.
const RINGS := [
	[Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 1, 1), Vector3i(0, 0, 1)],
	[Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 0, 1), Vector3i(0, 0, 1)],
	[Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 1, 0), Vector3i(0, 1, 0)],
]
## Offset used to measure the field's gradient (metres).
const GRADIENT_STEP := 0.02
## Pulls dual-contouring vertices toward the average crossing point, keeping
## them stable where the crossing planes are nearly parallel.
const QEF_BIAS := 0.05


## Returns non-indexed mesh arrays (vertex, normal, colour) for
## Mesh.PRIMITIVE_TRIANGLES. `colors` holds a colour per tunnel type.
static func build(sdf: CaveSdf, layout: TunnelLayout, cell: float, margin: float, colors: PackedColorArray) -> Array:
	var values := {}
	var sharp := {}
	_sample(sdf, layout, cell, margin, values, sharp)

	var edges: Array[Vector2i] = []
	for c in 8:
		for bit in [1, 2, 4]:
			if c & bit == 0:
				edges.append(Vector2i(c, c | bit))

	# One vertex per cell the surface passes through.
	var cell_vertex := {}
	var positions := PackedVector3Array()
	var vertex_colors := PackedColorArray()
	var vertex_sharp := PackedByteArray()
	var corner_values := PackedFloat32Array()
	corner_values.resize(8)
	for key: Vector3i in values:
		var inside := 0
		var is_sharp := false
		for c in 8:
			var corner: Vector3i = key + CORNERS[c]
			var v: float = values.get(corner, CaveSdf.OUTSIDE)
			corner_values[c] = v
			if v < 0.0:
				inside += 1
			if sharp.has(corner):
				is_sharp = true
		if inside == 0 or inside == 8:
			continue
		var crossings := PackedVector3Array()
		var sum := Vector3.ZERO
		for edge in edges:
			var vi := corner_values[edge.x]
			var vj := corner_values[edge.y]
			if (vi < 0.0) == (vj < 0.0):
				continue
			var crossing := Vector3(CORNERS[edge.x]).lerp(Vector3(CORNERS[edge.y]), vi / (vi - vj))
			crossings.append(crossing)
			sum += crossing
		var local := sum / crossings.size()
		if is_sharp:
			local = _dual_contour(sdf, key, cell, crossings, local)
		var world := (Vector3(key) + local) * cell
		sdf.value(world)
		cell_vertex[key] = positions.size()
		positions.append(world)
		vertex_colors.append(colors[sdf.last_type] if sdf.last_type < colors.size() else Color.WHITE)
		vertex_sharp.append(1 if is_sharp else 0)

	# One quad per grid edge the surface crosses, joining the four cells
	# around it. Godot treats clockwise triangles as front faces, which means
	# the geometric normal of a front face points away from the viewer, i.e.
	# into the rock.
	var indices := PackedInt32Array()
	for axis in 3:
		var ring: Array = RINGS[axis]
		var ring_normal := Vector3(-ring[1] + ring[0]).cross(Vector3(-ring[2] + ring[0]))
		for key: Vector3i in values:
			var v0: float = values[key]
			var v1: float = values.get(key + AXES[axis], CaveSdf.OUTSIDE)
			if (v0 < 0.0) == (v1 < 0.0):
				continue
			var q := PackedInt32Array()
			for offset: Vector3i in ring:
				var index: int = cell_vertex.get(key - offset, -1)
				if index == -1:
					break
				q.append(index)
			if q.size() < 4:
				continue
			var toward_rock := Vector3(AXES[axis]) * (1.0 if v1 > v0 else -1.0)
			if ring_normal.dot(toward_rock) > 0.0:
				indices.append_array(PackedInt32Array([q[0], q[1], q[2], q[0], q[2], q[3]]))
			else:
				indices.append_array(PackedInt32Array([q[0], q[3], q[2], q[0], q[2], q[1]]))

	var normals := PackedVector3Array()
	normals.resize(positions.size())
	for i in range(0, indices.size(), 3):
		var a := positions[indices[i]]
		var face := (positions[indices[i + 1]] - a).cross(positions[indices[i + 2]] - a)
		for n in 3:
			normals[indices[i + n]] -= face
	for i in normals.size():
		normals[i] = normals[i].normalized()

	var clip_boxes: Array[AABB] = []
	for room in layout.rooms:
		clip_boxes.append(room.bounds)

	var out := MeshOut.new()
	for i in range(0, indices.size(), 3):
		var ia := indices[i]
		var ib := indices[i + 1]
		var ic := indices[i + 2]
		var pa := positions[ia]
		var pb := positions[ib]
		var pc := positions[ic]
		var na := normals[ia]
		var nb := normals[ib]
		var nc := normals[ic]
		if vertex_sharp[ia] == 1 and vertex_sharp[ib] == 1 and vertex_sharp[ic] == 1:
			var flat := -(pb - pa).cross(pc - pa).normalized()
			na = flat
			nb = flat
			nc = flat

		var tri_box := AABB(pa, Vector3.ZERO).expand(pb).expand(pc).grow(0.001)
		var clipped := false
		for box in clip_boxes:
			if box.intersects(tri_box):
				clipped = true
				break
		if not clipped:
			out.add(pa, na, vertex_colors[ia])
			out.add(pb, nb, vertex_colors[ib])
			out.add(pc, nc, vertex_colors[ic])
			continue

		var pieces := [[
			[pa, na, vertex_colors[ia]],
			[pb, nb, vertex_colors[ib]],
			[pc, nc, vertex_colors[ic]],
		]]
		for box in clip_boxes:
			if not box.intersects(tri_box):
				continue
			var kept := []
			for piece: Array in pieces:
				kept.append_array(_outside_box(piece, box))
			pieces = kept
		for piece: Array in pieces:
			for n in range(1, piece.size() - 1):
				for v: Array in [piece[0], piece[n], piece[n + 1]]:
					out.add(v[0], v[1], v[2])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = out.positions
	arrays[Mesh.ARRAY_NORMAL] = out.normals
	arrays[Mesh.ARRAY_COLOR] = out.colors
	return arrays


## Flat triangle list of mesh arrays, for a ConcavePolygonShape3D.
static func faces(arrays: Array) -> PackedVector3Array:
	return arrays[Mesh.ARRAY_VERTEX]


class MeshOut:
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()

	func add(p: Vector3, n: Vector3, c: Color) -> void:
		positions.append(p)
		normals.append(n)
		colors.append(c)


## Samples the field at every grid point within reach of a tunnel segment or
## room mouth. Points where sharp geometry is nearest go in `sharp`.
static func _sample(sdf: CaveSdf, layout: TunnelLayout, cell: float, margin: float, values: Dictionary, sharp: Dictionary) -> void:
	for i in layout.segment_count():
		var a := layout.seg_a[i]
		var b := layout.seg_b[i]
		var ab := b - a
		var inv_len_sq := 1.0 / maxf(ab.length_squared(), 0.000001)
		# Segments run along the floor: sample the cross-section (half the
		# width to each side, floor to ceiling) plus the margin, not a sphere
		# of the full size, since wide tunnels are much wider than tall.
		var side := maxf(layout.seg_wa[i], layout.seg_wb[i]) * 0.5 + margin
		var top := maxf(layout.seg_ha[i], layout.seg_hb[i]) + margin
		var side_sq := side * side
		var lo := Vector3i(((a.min(b) - Vector3(side, margin, side)) / cell).floor())
		var hi := Vector3i(((a.max(b) + Vector3(side, top, side)) / cell).ceil())
		for x in range(lo.x, hi.x + 1):
			for y in range(lo.y, hi.y + 1):
				for z in range(lo.z, hi.z + 1):
					var key := Vector3i(x, y, z)
					if values.has(key):
						continue
					var p := Vector3(key) * cell
					var t := clampf((p - a).dot(ab) * inv_len_sq, 0.0, 1.0)
					var d := p - (a + ab * t)
					if d.y < -margin or d.y > top or d.x * d.x + d.z * d.z > side_sq:
						continue
					_sample_point(sdf, key, cell, values, sharp)
	for mouth in layout.mouths:
		var lo := Vector3i(((mouth.position - Vector3.ONE * margin) / cell).floor())
		var hi := Vector3i(((mouth.end + Vector3.ONE * margin) / cell).ceil())
		for x in range(lo.x, hi.x + 1):
			for y in range(lo.y, hi.y + 1):
				for z in range(lo.z, hi.z + 1):
					var key := Vector3i(x, y, z)
					if not values.has(key):
						_sample_point(sdf, key, cell, values, sharp)


static func _sample_point(sdf: CaveSdf, key: Vector3i, cell: float, values: Dictionary, sharp: Dictionary) -> void:
	values[key] = sdf.value(Vector3(key) * cell)
	if sdf.last_sharp:
		sharp[key] = true


## Places a cell's vertex where the planes through its edge crossings (each
## at right angles to the field's gradient there) best meet, relative to
## their average point. Coordinates are in cell units.
static func _dual_contour(sdf: CaveSdf, key: Vector3i, cell: float, crossings: PackedVector3Array, mass: Vector3) -> Vector3:
	var xx := QEF_BIAS
	var xy := 0.0
	var xz := 0.0
	var yy := QEF_BIAS
	var yz := 0.0
	var zz := QEF_BIAS
	var rhs := Vector3.ZERO
	for crossing in crossings:
		var n := _gradient(sdf, (Vector3(key) + crossing) * cell)
		var d := n.dot(crossing - mass)
		xx += n.x * n.x
		xy += n.x * n.y
		xz += n.x * n.z
		yy += n.y * n.y
		yz += n.y * n.z
		zz += n.z * n.z
		rhs += n * d
	var m := Basis(Vector3(xx, xy, xz), Vector3(xy, yy, yz), Vector3(xz, yz, zz))
	var v := mass + m.inverse() * rhs
	# Far outside the cell the planes don't meet sensibly; fall back.
	if v.x < -0.5 or v.y < -0.5 or v.z < -0.5 or v.x > 1.5 or v.y > 1.5 or v.z > 1.5:
		return mass
	return v


static func _gradient(sdf: CaveSdf, p: Vector3) -> Vector3:
	var h := GRADIENT_STEP
	var k1 := Vector3(1, -1, -1)
	var k2 := Vector3(-1, -1, 1)
	var k3 := Vector3(-1, 1, -1)
	var k4 := Vector3(1, 1, 1)
	return (k1 * sdf.value(p + k1 * h) + k2 * sdf.value(p + k2 * h)
		+ k3 * sdf.value(p + k3 * h) + k4 * sdf.value(p + k4 * h)).normalized()


## The parts of a convex polygon outside a box, as convex polygons. A vertex
## is [position, normal, colour].
static func _outside_box(poly: Array, box: AABB) -> Array:
	var outside := []
	var rest := poly
	for axis in 3:
		for high: bool in [false, true]:
			var bound: float = box.end[axis] if high else box.position[axis]
			var parts := _split(rest, axis, bound, 1.0 if high else -1.0)
			if parts[0].size() >= 3:
				outside.append(parts[0])
			rest = parts[1]
			if rest.size() < 3:
				return outside
	return outside


## Splits a convex polygon by an axis-aligned plane into [beyond, within],
## where "beyond" is the side `direction` points to.
static func _split(poly: Array, axis: int, bound: float, direction: float) -> Array:
	var beyond := []
	var within := []
	for i in poly.size():
		var a: Array = poly[i]
		var b: Array = poly[(i + 1) % poly.size()]
		var da: float = direction * ((a[0] as Vector3)[axis] - bound)
		var db: float = direction * ((b[0] as Vector3)[axis] - bound)
		if da > 0.0:
			beyond.append(a)
		else:
			within.append(a)
		if (da > 0.0) != (db > 0.0):
			var t := da / (da - db)
			var v := [
				(a[0] as Vector3).lerp(b[0], t),
				(a[1] as Vector3).lerp(b[1], t).normalized(),
				(a[2] as Color).lerp(b[2], t),
			]
			beyond.append(v)
			within.append(v)
	return [beyond, within]
