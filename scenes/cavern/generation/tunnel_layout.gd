class_name TunnelLayout
extends RefCounted
## Grows a layer's tunnel network as a list of segments running along tunnel
## floors, each with a width and height.
##
## Tunnels are "walkers" that step forward, steered by their TunnelType: cave
## tunnels wind on smooth noise, factory tunnels run straight and turn 90
## degrees. New tunnels pick a type by weight. A tunnel mostly keeps its type,
## but past a minimum stretch it can change; confusion shortens that stretch
## and raises the chance.
## Local confusion also controls how often tunnels branch, and how often a
## blocked tunnel joins another (a loop) instead of dead-ending.
##
## Tunnels sometimes open into a preset room (a CavernRoom scene). The tunnel
## ends at one of the room's openings; every other opening starts a new
## tunnel, one of which carries the original tunnel (and its type) on. Each
## opening gets a short, opening-shaped mouth so the tunnel meets it exactly.
##
## Occasionally a layer gets an impossible link: two identical S-bend "locks"
## placed far apart, where walking through one's centre puts you in the other.
## See docs/policies/dungeon-exploration.md.

## Size of an impossible link's tunnel. Locks are always rounded and calm.
const LOCK_WIDTH := 4.4
const LOCK_HEIGHT := 3.6
## Entry points of a lock in its local space. Travel through a lock's centre
## runs from local -Z (back) to +Z (front).
const LOCK_ENTRY_BACK := Vector3(8, 0, -6)
const LOCK_ENTRY_FRONT := Vector3(-8, 0, 6)
## A walker's own most recent segments are always near it, so they're skipped
## when checking whether its next step is blocked. This is the minimum; wider
## tunnels skip further back (see _own_ignored).
const OWN_SEGMENTS_IGNORED := 4
## How many times a new branch is started from a random existing tunnel when
## every tunnel has ended but length budget remains.
const MAX_REFILLS := 50


class OpenEnd:
	var pos: Vector3
	var heading: Vector3
	var width: float
	var height: float
	var type: int
	var owner: int
	var last_segment: int


class PlacedRoom:
	var scene: PackedScene
	var transform: Transform3D
	## The room's shell in world space. Tunnel surfaces inside it are cut away.
	var bounds: AABB
	## The bounds plus room for the mouths at its openings; other tunnels keep
	## clear of this.
	var zone: AABB
	var owner: int


class RoomInfo:
	var bounds: AABB
	var connectors: Array[Transform3D] = []
	var sizes := PackedVector2Array()


## Segments run along tunnel floors.
var seg_a := PackedVector3Array()
var seg_b := PackedVector3Array()
var seg_wa := PackedFloat32Array()
var seg_wb := PackedFloat32Array()
var seg_ha := PackedFloat32Array()
var seg_hb := PackedFloat32Array()
var seg_owner := PackedInt32Array()
## Tunnel type index, used for the surface colour.
var seg_type := PackedInt32Array()
## 1 for box-section (sharp) segments, 0 for rounded ones.
var seg_sharp := PackedByteArray()

var types: Array[TunnelType] = []
var entrance := Vector3.ZERO
## Walkers start with yaw 0, which faces -Z.
var entrance_heading := Vector3.FORWARD
## Impossible links as [lock_a: Transform3D, lock_b: Transform3D].
var links: Array = []
var lock_centres := PackedVector3Array()
## Segment owner ids that belong to locks.
var lock_owners: Array[int] = []
var rooms: Array[PlacedRoom] = []
## Opening-shaped boxes of air joining tunnels to room openings, and the
## tunnel type each belongs to.
var mouths: Array[AABB] = []
var mouth_types := PackedInt32Array()

var dead_ends := 0
## Tunnels that fork off another tunnel (room exits aren't counted).
var branches := 0
var loops := 0
var type_changes := 0

var _settings: CavernSettings
var _confusion: ConfusionField
var _rng: RandomNumberGenerator
var _noise: FastNoiseLite
var _open_ends: Array[OpenEnd] = []
var _next_id := 0
## Whether the last walker grown ended by being blocked (without a loop).
var _last_blocked := false
## PackedScene -> RoomInfo (or null if the scene isn't a usable room).
var _room_infos := {}


func generate(settings: CavernSettings, confusion: ConfusionField, rng: RandomNumberGenerator) -> void:
	_settings = settings
	_confusion = confusion
	_rng = rng
	_noise = FastNoiseLite.new()
	_noise.seed = rng.randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.06

	for type in settings.tunnel_types:
		if type:
			types.append(type)
	if types.is_empty():
		push_warning("CavernSettings has no tunnel types; using a default cave tunnel.")
		types.append(CaveTunnelType.new())

	var main := _new_walker(-1, entrance, 0.0, settings.main_tunnel_length, _pick_type())
	entrance_heading = _flat(main.yaw)

	var budget := settings.total_length
	var queue: Array[TunnelWalker] = [main]
	var refills := 0
	while budget > settings.step_length and refills < MAX_REFILLS:
		if queue.is_empty():
			# No new branch unless it can run its full minimum length.
			if budget < settings.branch_length_min:
				break
			refills += 1
			queue.append(_branch_from_random_point())
		var w: TunnelWalker = queue.pop_front()
		var is_branch := w.parent_id != -1 and not _is_room(w.parent_id)
		if is_branch and budget < settings.branch_length_min:
			continue
		var first_segment := seg_a.size()
		var type_changes_before := type_changes
		# A room's openings always get a full-length tunnel, even if that
		# overdraws the budget, so none is left as a stub.
		var allowance := budget if is_branch else maxf(budget, minf(w.remaining, settings.branch_length_min))
		var grown := _grow(w, queue, allowance)
		# A branch that's blocked before its minimum length would be a stub, so
		# it's removed. One that joins another tunnel or opens into a room is
		# connected at both ends, so it stays however short it is.
		if is_branch and _last_blocked and grown < settings.branch_length_min:
			_discard_branch(w, first_segment, queue)
			type_changes = type_changes_before
		else:
			budget -= grown
			if is_branch and grown > 0.0:
				branches += 1

	# Room openings still waiting when the budget ran out get a short tunnel
	# each, so no opening is left as a stub. Their own branches and rooms are
	# skipped.
	for w in queue:
		if _is_room(w.parent_id):
			w.remaining = minf(w.remaining, settings.branch_length_min)
			_grow(w, [], w.remaining, false)

	for n in settings.impossible_link_max:
		if rng.randf() < settings.impossible_link_chance and not _try_add_link():
			break


func segment_count() -> int:
	return seg_a.size()


## Signed distance from p to a box: negative inside.
static func box_distance(p: Vector3, box: AABB) -> float:
	var q := (p - box.get_center()).abs() - box.size * 0.5
	return q.max(Vector3.ZERO).length() + minf(maxf(q.x, maxf(q.y, q.z)), 0.0)


func _new_walker(parent_id: int, pos: Vector3, yaw: float, length: float, type: int) -> TunnelWalker:
	var w := TunnelWalker.new()
	w.id = _new_owner()
	w.parent_id = parent_id
	w.pos = pos
	w.yaw = yaw
	w.type = type
	w.remaining = length
	w.noise_offset = _rng.randf() * 10000.0
	types[type].begin(w, _confusion.sample(pos), _rng)
	var limit := 2.0 * _reach(w.width, w.height) + _settings.clearance
	w.grace_steps = ceili(limit / (_settings.step_length * 0.7)) + 1
	return w


## Grows one walker until it runs out of length or budget, or is blocked.
## Returns the length grown.
func _grow(w: TunnelWalker, queue: Array[TunnelWalker], budget: float, allow_rooms := true) -> float:
	var s := _settings
	var grown := 0.0
	_last_blocked = false

	while w.remaining > 0.0 and grown < budget:
		var confusion := _confusion.sample(w.pos)
		_maybe_change_type(w, confusion)
		var type := types[w.type]
		var sharp := type.is_sharp()
		var size := type.steer(w, confusion, _noise, _rng)
		if not sharp:
			size = _taper_from_entry(w, size)
		var reach := _reach(size.x, size.y)
		var ignore_parent := w.steps < w.grace_steps

		var blocker := -1
		var stepped := false
		for offset: float in type.turn_offsets(w):
			var yaw := w.yaw + offset
			var candidate := w.pos + _direction(yaw, w.pitch) * s.step_length
			var hit := _blocking(_centre(candidate, size.y), reach, w, ignore_parent)
			if hit == -1:
				w.yaw = yaw
				_add_segment(w.pos, candidate, Vector2(w.width, w.height), size, w.id, w.type, sharp)
				w.pos = candidate
				w.width = size.x
				w.height = size.y
				type.advanced(w, s.step_length, offset != 0.0, confusion, _rng)
				stepped = true
				break
			if blocker == -1:
				blocker = hit

		if not stepped:
			# Only tunnels can be joined; running into a room is a dead end. A
			# branch or room exit blocked before its minimum length always
			# tries to join, so it connects rather than ending as a stub.
			var must_join := w.parent_id != -1 and w.travelled < s.branch_length_min
			var join_chance := 1.0 if must_join else s.loop_chance + confusion * s.loop_chance_per_confusion
			if blocker >= 0 and _rng.randf() < join_chance and _join(w, blocker, sharp):
				loops += 1
			else:
				dead_ends += 1
				_last_blocked = true
			return grown

		w.steps += 1
		w.steps_since_branch += 1
		w.travelled += s.step_length
		w.type_travelled += s.step_length
		w.remaining -= s.step_length
		grown += s.step_length

		var can_branch := w.steps > w.grace_steps and w.steps_since_branch > w.grace_steps * 2
		if can_branch and _rng.randf() < s.branch_chance + confusion * s.branch_chance_per_confusion:
			# Branches pick their own type, so uncommon types stay occasional
			# routes rather than spreading into whole networks.
			queue.append(_new_walker(w.id, w.pos, type.branch_yaw(w, _rng), _branch_length(), _pick_type()))
			w.steps_since_branch = 0

		w.steps_since_room += 1
		var can_room := w.steps > w.grace_steps and w.steps_since_room > w.grace_steps * 3
		if allow_rooms and can_room and _rng.randf() < s.room_chance and _try_place_room(w, queue):
			return grown

	# Ran out of length rather than being blocked: open rock ahead, which is
	# where an impossible link can be attached.
	var end := OpenEnd.new()
	end.pos = w.pos
	end.heading = _direction(w.yaw, w.pitch)
	end.width = w.width
	end.height = w.height
	end.type = w.type
	end.owner = w.id
	end.last_segment = seg_a.size() - 1
	_open_ends.append(end)
	return grown


## Tunnels mostly keep their type. Past a minimum stretch there is a small
## chance per step of re-picking it by weight; confusion shortens the stretch
## and raises the chance. Re-picking can land on the same type, so common
## types are left rarely and uncommon ones soon. A tunnel doesn't change with
## less than a minimum stretch left, so no type appears as a short stub.
func _maybe_change_type(w: TunnelWalker, confusion: float) -> void:
	if types.size() < 2:
		return
	var scale := 1.0 + confusion * _settings.type_change_confusion
	var stretch := _settings.type_min_stretch / scale
	if w.type_travelled < stretch or w.remaining < stretch:
		return
	if _rng.randf() >= _settings.type_change_chance * scale:
		return
	var next := _pick_type()
	if next == w.type:
		return
	w.type = next
	w.type_travelled = 0.0
	types[next].begin(w, confusion, _rng)
	type_changes += 1


func _is_room(owner: int) -> bool:
	for room in rooms:
		if room.owner == owner:
			return true
	return false


## Removes a branch that was grown from `first_segment` on, along with any
## branches it queued (they haven't been grown yet).
func _discard_branch(w: TunnelWalker, first_segment: int, queue: Array[TunnelWalker]) -> void:
	_remove_segments_from(first_segment)
	dead_ends -= 1
	for i in range(queue.size() - 1, -1, -1):
		if queue[i].parent_id == w.id:
			queue.remove_at(i)


func _remove_segments_from(first: int) -> void:
	seg_a.resize(first)
	seg_b.resize(first)
	seg_wa.resize(first)
	seg_wb.resize(first)
	seg_ha.resize(first)
	seg_hb.resize(first)
	seg_owner.resize(first)
	seg_type.resize(first)
	seg_sharp.resize(first)


## A random tunnel type index, chosen by weight.
func _pick_type() -> int:
	var total := 0.0
	for type in types:
		total += maxf(type.weight, 0.0)
	if total <= 0.0:
		return _rng.randi_range(0, types.size() - 1)
	var roll := _rng.randf() * total
	for i in types.size():
		roll -= maxf(types[i].weight, 0.0)
		if roll < 0.0:
			return i
	return types.size() - 1


## Joins a blocked walker to the tunnel blocking it. Sharp tunnels join
## square: straight on, then a 90 degree turn onto the other tunnel, and only
## if that tunnel is ahead. Returns false if no join was made.
func _join(w: TunnelWalker, blocker: int, sharp: bool) -> bool:
	var here := Vector2(w.width, w.height)
	var target := _closest_point(blocker, w.pos)
	if not sharp:
		_add_segment(w.pos, target, here, here, w.id, w.type, false)
		return true
	var heading := _flat(w.yaw)
	var ahead := (target - w.pos).dot(heading)
	if ahead < 0.0:
		return false
	var corner := w.pos + heading * ahead
	_add_segment(w.pos, corner, here, here, w.id, w.type, true)
	if corner.distance_to(target) > 0.1:
		_add_segment(corner, target, here, here, w.id, w.type, true)
	return true


func _branch_from_random_point() -> TunnelWalker:
	var i := _rng.randi_range(0, seg_a.size() - 1)
	var pos := seg_a[i].lerp(seg_b[i], _rng.randf())
	var walker := _new_walker(seg_owner[i], pos, _yaw_of(seg_b[i] - seg_a[i]), _branch_length(), _pick_type())
	walker.yaw = types[walker.type].branch_yaw(walker, _rng)
	return walker


## Returns the blocking segment's index, -2 - room index for a room, or -1 if
## nothing blocks. `centre` is the middle of the tunnel's cross-section.
func _blocking(centre: Vector3, reach: float, w: TunnelWalker, ignore_parent: bool) -> int:
	var recent_from := seg_a.size() - _own_ignored(reach, reach)
	for i in seg_a.size():
		var owner := seg_owner[i]
		if owner == w.id and i >= recent_from:
			continue
		if ignore_parent and owner == w.parent_id:
			continue
		var limit := reach + _segment_reach(i) + _settings.clearance
		if centre.distance_squared_to(_closest_centre(i, centre)) < limit * limit:
			return i
	for r in rooms.size():
		if ignore_parent and rooms[r].owner == w.parent_id:
			continue
		if box_distance(centre, rooms[r].zone) < reach + _settings.clearance:
			return -2 - r
	return -1


## Closest point on a segment's floor line.
func _closest_point(i: int, p: Vector3) -> Vector3:
	var a := seg_a[i]
	var ab := seg_b[i] - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
	return a + ab * t


## Closest point on the line through the middle of a segment's cross-section.
func _closest_centre(i: int, p: Vector3) -> Vector3:
	var a := _centre(seg_a[i], seg_ha[i])
	var ab := _centre(seg_b[i], seg_hb[i]) - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
	return a + ab * t


func _segment_reach(i: int) -> float:
	return _reach(maxf(seg_wa[i], seg_wb[i]), maxf(seg_ha[i], seg_hb[i]))


## How many of a tunnel's own latest segments to skip in clearance checks:
## enough that a straight tunnel never blocks itself, however wide it is.
func _own_ignored(reach: float, own_reach: float) -> int:
	var spacing := reach + own_reach + _settings.clearance
	return maxi(OWN_SEGMENTS_IGNORED, ceili(spacing / _settings.step_length) + 1)


func _reach(width: float, height: float) -> float:
	return maxf(width, height) * 0.5


func _centre(floor_point: Vector3, height: float) -> Vector3:
	return floor_point + Vector3(0.0, height * 0.5, 0.0)


func _add_segment(a: Vector3, b: Vector3, size_a: Vector2, size_b: Vector2, owner: int, type: int, sharp: bool) -> void:
	seg_a.append(a)
	seg_b.append(b)
	seg_wa.append(size_a.x)
	seg_wb.append(size_b.x)
	seg_ha.append(size_a.y)
	seg_hb.append(size_b.y)
	seg_owner.append(owner)
	seg_type.append(type)
	seg_sharp.append(1 if sharp else 0)


func _new_owner() -> int:
	_next_id += 1
	return _next_id - 1


func _direction(yaw: float, pitch: float) -> Vector3:
	return Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))


func _flat(yaw: float) -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func _yaw_of(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)


## The world axis (X or Z) closest to a direction.
func _snap_axis(direction: Vector3) -> Vector3:
	if absf(direction.x) > absf(direction.z):
		return Vector3(signf(direction.x), 0.0, 0.0)
	return Vector3(0.0, 0.0, signf(direction.z))


func _branch_length() -> float:
	return _rng.randf_range(_settings.branch_length_min, _settings.branch_length_max)


func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap = items[i]
		items[i] = items[j]
		items[j] = swap


# --- Rooms ------------------------------------------------------------------

## Places a random preset room just ahead of the walker, turned (in 90 degree
## steps) so one of its openings faces the walker, and ends the walker there.
func _try_place_room(w: TunnelWalker, queue: Array[TunnelWalker]) -> bool:
	var s := _settings
	if s.rooms.is_empty():
		return false
	var scene: PackedScene = s.rooms[_rng.randi_range(0, s.rooms.size() - 1)]
	var info := _room_info(scene)
	if info == null:
		return false

	var entry := _rng.randi_range(0, info.connectors.size() - 1)
	var ahead := _snap_axis(_flat(w.yaw))
	var basis := _facing_basis(info.connectors[entry], -ahead)
	# The entry opening's floor point, far enough ahead for the mouth.
	var door := w.pos + ahead * (s.mouth_length + s.step_length)
	var room := PlacedRoom.new()
	room.scene = scene
	room.transform = Transform3D(basis, door - basis * info.connectors[entry].origin)
	room.bounds = room.transform * info.bounds
	room.zone = room.bounds.grow(s.mouth_length)
	if not _room_clear(room.zone, w):
		return false
	# Every other opening needs room for a tunnel to start, or it would be a
	# dead-end stub.
	for i in info.connectors.size():
		if i != entry and not _exit_clear(room.transform * info.connectors[i], info.sizes[i], w):
			return false

	room.owner = _new_owner()
	rooms.append(room)
	var here := Vector2(w.width, w.height)
	var sharp := types[w.type].is_sharp()
	if not sharp:
		var fit := _mouth_fit(info.sizes[entry])
		_taper_end(w.id, fit, seg_a.size() - 1)
		here = here.min(fit)
	var outer := _add_mouth(room.transform * info.connectors[entry], info.sizes[entry], w.type)
	_add_segment(w.pos, outer, here, here, w.id, w.type, sharp)

	var exits := range(info.connectors.size())
	exits.erase(entry)
	_shuffle(exits)
	for n in exits.size():
		var i: int = exits[n]
		var connector := room.transform * info.connectors[i]
		var start := _add_mouth(connector, info.sizes[i], w.type)
		# The first exit carries the tunnel (and its type) on; the rest are new
		# branches and pick their own type.
		var length := maxf(w.remaining, s.branch_length_min) if n == 0 else _branch_length()
		var exit_type := w.type if n == 0 else _pick_type()
		var walker := _new_walker(room.owner, start, _yaw_of(_snap_axis(-connector.basis.z)), length, exit_type)
		walker.grace_steps += ceili(s.mouth_length / s.step_length) + 1
		walker.entry_size = _mouth_fit(info.sizes[i])
		if not types[exit_type].is_sharp():
			walker.width = minf(walker.width, walker.entry_size.x)
			walker.height = minf(walker.height, walker.entry_size.y)
		queue.append(walker)
	return true


## Whether a tunnel can run a few steps straight out of an opening, at the
## size it starts at there (see _taper_from_entry).
func _exit_clear(connector: Transform3D, opening: Vector2, w: TunnelWalker) -> bool:
	var outward := _snap_axis(-connector.basis.z)
	var start := connector.origin + outward * _settings.mouth_length
	var fit := _mouth_fit(opening)
	var reach := _reach(fit.x, fit.y)
	for n in range(1, 4):
		var p := start + outward * _settings.step_length * n
		if _blocking(_centre(p, fit.y), reach, w, false) != -1:
			return false
	return true


func _room_info(scene: PackedScene) -> RoomInfo:
	if _room_infos.has(scene):
		return _room_infos[scene]
	var info: RoomInfo = null
	var node := scene.instantiate()
	var room := node as CavernRoom
	if room == null:
		push_warning("Cavern room %s doesn't have a CavernRoom root; skipping it." % scene.resource_path)
	else:
		info = RoomInfo.new()
		info.bounds = room.get_bounds()
		for connector in room.get_connectors():
			info.connectors.append(connector.transform)
			info.sizes.append(connector.size)
		if info.connectors.is_empty():
			push_warning("Cavern room %s has no RoomConnectors; skipping it." % scene.resource_path)
			info = null
	node.free()
	_room_infos[scene] = info
	return info


## The 90 degree yaw rotation that points a connector's outward direction
## (local -Z) closest to `want`.
func _facing_basis(connector: Transform3D, want: Vector3) -> Basis:
	var outward := -connector.basis.z
	var best := Basis.IDENTITY
	var best_dot := -INF
	for k in 4:
		var basis := Basis(Vector3.UP, k * PI * 0.5)
		basis = Basis(basis.x.round(), basis.y.round(), basis.z.round())
		var alignment := (basis * outward).dot(want)
		if alignment > best_dot:
			best_dot = alignment
			best = basis
	return best


func _room_clear(zone: AABB, w: TunnelWalker) -> bool:
	var padded := zone.grow(_settings.clearance)
	var own_reach := _reach(w.width, w.height)
	var ignore_from := seg_a.size() - _own_ignored(own_reach, own_reach)
	for i in seg_a.size():
		if seg_owner[i] == w.id and i >= ignore_from:
			continue
		var reach := _segment_reach(i)
		var a := _centre(seg_a[i], seg_ha[i])
		var b := _centre(seg_b[i], seg_hb[i])
		for p: Vector3 in [a, (a + b) * 0.5, b]:
			if box_distance(p, padded) < reach:
				return false
	for other in rooms:
		if other.zone.grow(_settings.clearance).intersects(zone):
			return false
	return true


## Adds the mouth for a room opening: a box of air exactly the opening's floor
## height, a little wider and taller, running from inside the shell face out
## to mouth_length. Returns the floor point at its outer end, where the
## tunnel attaches.
func _add_mouth(connector: Transform3D, size: Vector2, type: int) -> Vector3:
	var s := _settings
	var outward := _snap_axis(-connector.basis.z)
	var side := Vector3(absf(outward.z), 0.0, absf(outward.x))
	var half_width := size.x * 0.5 + s.mouth_margin
	var p := connector.origin
	# It runs two cells into the room (cut away there) so its inner end is too
	# far from the opening to bend the floor mesh near it.
	var box := AABB(p - outward * s.cell_size * 2.0 - side * half_width, Vector3.ZERO)
	box = box.expand(p + outward * s.mouth_length + side * half_width + Vector3.UP * (size.y + s.mouth_margin))
	mouths.append(box)
	mouth_types.append(type)
	return p + outward * s.mouth_length


## The smallest tunnel size that still wraps a mouth for an opening of `size`.
func _mouth_fit(size: Vector2) -> Vector2:
	return Vector2(size.x + _settings.mouth_margin * 2.0, size.y + _settings.mouth_margin)


## A rounded tunnel leaving a room opening eases out from the opening's size
## to its own over opening_taper_length.
func _taper_from_entry(w: TunnelWalker, size: Vector2) -> Vector2:
	if w.entry_size == Vector2.ZERO:
		return size
	var k := smoothstep(0.0, _settings.opening_taper_length, w.travelled + _settings.step_length)
	return size.min(w.entry_size.lerp(size, k))


## Narrows the final opening_taper_length of a rounded tunnel, whose last
## segment is `last`, so it arrives at `size`. Only ever narrows, so it can't
## break clearance, and stops at box-section segments, which keep one size.
func _taper_end(owner: int, size: Vector2, last: int) -> void:
	var taper := _settings.opening_taper_length
	var from_end := 0.0
	var i := last
	while i >= 0 and seg_owner[i] == owner and seg_sharp[i] == 0 and from_end < taper:
		seg_wb[i] = _narrowed(seg_wb[i], size.x, from_end)
		seg_hb[i] = _narrowed(seg_hb[i], size.y, from_end)
		from_end += seg_a[i].distance_to(seg_b[i])
		seg_wa[i] = _narrowed(seg_wa[i], size.x, from_end)
		seg_ha[i] = _narrowed(seg_ha[i], size.y, from_end)
		i -= 1


func _narrowed(value: float, target: float, from_end: float) -> float:
	return minf(value, lerpf(target, value, smoothstep(0.0, _settings.opening_taper_length, from_end)))


# --- Impossible links -------------------------------------------------------

## The lock's S-bend floor path in local space. Both locks of a link use
## exactly this path, so they mesh identically; the bends hide everything past
## each end.
static func _lock_path() -> PackedVector3Array:
	return PackedVector3Array([
		LOCK_ENTRY_BACK, Vector3(3, 0, -6), Vector3(1, 0, -5), Vector3(0, 0, -3),
		Vector3(0, 0, 0),
		Vector3(0, 0, 3), Vector3(-1, 0, 5), Vector3(-3, 0, 6), LOCK_ENTRY_FRONT,
	])


## Links two open ends that are far enough apart and have room for a lock.
## Each end is used by at most one link. Returns false if no pair fits.
func _try_add_link() -> bool:
	var ends := _open_ends.duplicate()
	_shuffle(ends)

	for from_end: OpenEnd in ends:
		for to_end: OpenEnd in ends:
			if from_end == to_end:
				continue
			if from_end.pos.distance_to(to_end.pos) < _settings.impossible_link_min_distance:
				continue
			# Lock A is entered from its back, lock B from its front.
			var lock_a := _lock_transform(from_end, LOCK_ENTRY_BACK, Vector3.LEFT)
			var lock_b := _lock_transform(to_end, LOCK_ENTRY_FRONT, Vector3.RIGHT)
			if lock_a.origin.distance_to(lock_b.origin) < _settings.impossible_link_min_distance:
				continue
			if not _lock_clear(lock_a, from_end, LOCK_ENTRY_BACK):
				continue
			if not _lock_clear(lock_b, to_end, LOCK_ENTRY_FRONT):
				continue
			# Both locks take the first end's type so they look identical.
			_add_lock(lock_a, from_end, LOCK_ENTRY_BACK, from_end.type)
			_add_lock(lock_b, to_end, LOCK_ENTRY_FRONT, from_end.type)
			links.append([lock_a, lock_b])
			_open_ends.erase(from_end)
			_open_ends.erase(to_end)
			return true
	return false


## Places a lock just past an open end, rotated in 90 degree steps and snapped
## to the mesh grid so both locks of a link produce identical geometry.
func _lock_transform(end: OpenEnd, entry: Vector3, entry_direction: Vector3) -> Transform3D:
	var flat := Vector3(end.heading.x, 0.0, end.heading.z).normalized()
	var best := Basis.IDENTITY
	var best_dot := -INF
	for k in 4:
		var basis := Basis(Vector3.UP, k * PI * 0.5)
		basis = Basis(basis.x.round(), basis.y.round(), basis.z.round())
		var alignment := (basis * entry_direction).dot(flat)
		if alignment > best_dot:
			best_dot = alignment
			best = basis
	var centre := end.pos + flat * 3.0 - best * entry
	centre = centre.snapped(Vector3.ONE * _settings.cell_size)
	return Transform3D(best, centre)


func _lock_clear(xf: Transform3D, end: OpenEnd, entry: Vector3) -> bool:
	var path := _lock_path()
	var points := PackedVector3Array()
	for i in path.size() - 1:
		var a := xf * path[i]
		var b := xf * path[i + 1]
		var count := ceili(a.distance_to(b))
		for n in count:
			points.append(a.lerp(b, float(n) / count))
	points.append(xf * path[path.size() - 1])

	var reach := _reach(LOCK_WIDTH, LOCK_HEIGHT)
	var entry_world := xf * entry
	var recent_from := end.last_segment - _own_ignored(reach, _reach(end.width, end.height))
	for p in points:
		# The end of the lock that joins the open end is allowed near it.
		if p.distance_to(entry_world) < reach * 2.0:
			continue
		var centre := _centre(p, LOCK_HEIGHT)
		for i in seg_a.size():
			if seg_owner[i] == end.owner and i > recent_from:
				continue
			var limit := reach + _segment_reach(i) + _settings.clearance
			if centre.distance_squared_to(_closest_centre(i, centre)) < limit * limit:
				return false
		for room in rooms:
			if box_distance(centre, room.zone) < reach + _settings.clearance:
				return false
	return true


func _add_lock(xf: Transform3D, end: OpenEnd, entry: Vector3, type: int) -> void:
	var owner := _new_owner()
	var lock_size := Vector2(LOCK_WIDTH, LOCK_HEIGHT)
	var start := Vector2(end.width, end.height)
	var sharp := types[end.type].is_sharp()
	if not sharp:
		_taper_end(end.owner, lock_size, end.last_segment)
		start = start.min(lock_size)
	_add_segment(end.pos, xf * entry, start, lock_size, owner, end.type, sharp)
	var path := _lock_path()
	for i in path.size() - 1:
		_add_segment(xf * path[i], xf * path[i + 1], lock_size, lock_size, owner, type, false)
	lock_centres.append(xf.origin)
	lock_owners.append(owner)
