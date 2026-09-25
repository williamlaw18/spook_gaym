class_name CaveSdf
extends RefCounted
## Signed distance field for a tunnel layout: negative inside the tunnels
## (air), positive in rock.
##
## Rounded tunnel segments are tubes with a flattened floor. Each tunnel's
## rounded segments form a group, and groups are smooth-blended where they
## meet so junctions stay organic. Sharp (box-section) segments and the
## opening-shaped mouths at room openings are joined with hard unions instead,
## so their walls stay flat. Rock noise roughens the rounded tunnels only: it
## fades out where they meet sharp geometry, and around impossible-link locks,
## which must stay identical.

const OUTSIDE := 1000.0
const BUCKET_SIZE := 4.0
## Rock noise fades in over this distance away from sharp geometry.
const SHARP_CALM_DISTANCE := 1.5
## Noise fades in between these distances from a lock centre.
const LOCK_CALM_INNER := 10.0
const LOCK_CALM_OUTER := 14.0

## Tunnel type index, and whether it's sharp, of whatever is nearest the last
## point passed to value().
var last_type := 0
var last_sharp := false

var _a: PackedVector3Array
var _ab: PackedVector3Array
var _inv_len_sq: PackedFloat32Array
var _len: PackedFloat32Array
var _fwd: PackedVector3Array
var _side: PackedVector3Array
var _up: PackedVector3Array
var _wa: PackedFloat32Array
var _wb: PackedFloat32Array
var _ha: PackedFloat32Array
var _hb: PackedFloat32Array
var _owner: PackedInt32Array
var _type: PackedInt32Array
var _sharp: PackedByteArray
var _mouths: Array[AABB]
var _mouth_types: PackedInt32Array
var _lock_centres: PackedVector3Array
var _reach_margin: float
## Vector3i bucket -> Array of segment indices, in ascending (owner-grouped) order.
var _buckets := {}
var _noise := FastNoiseLite.new()
var _noise_amplitude: float
var _blend: float
var _floor_flatten: float


func _init(layout: TunnelLayout, settings: CavernSettings, noise_seed: int, reach_margin: float) -> void:
	_a = layout.seg_a
	_wa = layout.seg_wa
	_wb = layout.seg_wb
	_ha = layout.seg_ha
	_hb = layout.seg_hb
	_owner = layout.seg_owner
	_type = layout.seg_type
	_sharp = layout.seg_sharp
	_mouths = layout.mouths
	_mouth_types = layout.mouth_types
	_lock_centres = layout.lock_centres
	_reach_margin = reach_margin
	_noise_amplitude = settings.noise_amplitude
	_blend = settings.blend
	_floor_flatten = settings.floor_flatten

	_noise.seed = noise_seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = settings.noise_frequency
	_noise.fractal_octaves = 2

	var count := layout.segment_count()
	_ab.resize(count)
	_inv_len_sq.resize(count)
	_len.resize(count)
	_fwd.resize(count)
	_side.resize(count)
	_up.resize(count)
	for i in count:
		var ab := layout.seg_b[i] - layout.seg_a[i]
		_ab[i] = ab
		_inv_len_sq[i] = 1.0 / maxf(ab.length_squared(), 0.000001)
		_len[i] = ab.length()
		var fwd := ab / _len[i] if _len[i] > 0.0001 else Vector3.FORWARD
		var side := fwd.cross(Vector3.UP)
		side = side.normalized() if side.length_squared() > 0.0001 else Vector3.RIGHT
		_fwd[i] = fwd
		_side[i] = side
		_up[i] = side.cross(fwd)

		# The segment's cross-section plus the margin (it runs along the floor).
		var reach_side := maxf(_wa[i], _wb[i]) * 0.5 + reach_margin
		var reach_top := maxf(_ha[i], _hb[i]) + reach_margin
		var lo := Vector3i(((_a[i].min(layout.seg_b[i]) - Vector3(reach_side, reach_margin, reach_side)) / BUCKET_SIZE).floor())
		var hi := Vector3i(((_a[i].max(layout.seg_b[i]) + Vector3(reach_side, reach_top, reach_side)) / BUCKET_SIZE).floor())
		for x in range(lo.x, hi.x + 1):
			for y in range(lo.y, hi.y + 1):
				for z in range(lo.z, hi.z + 1):
					var key := Vector3i(x, y, z)
					if not _buckets.has(key):
						_buckets[key] = []
					_buckets[key].append(i)


func value(p: Vector3) -> float:
	var rounded := OUTSIDE
	var sharp := OUTSIDE
	var nearest := OUTSIDE
	var nearest_type := 0
	var nearest_sharp := false

	var list = _buckets.get(Vector3i((p / BUCKET_SIZE).floor()))
	if list != null:
		var group := OUTSIDE
		var group_key := -1
		var group_sharp := false
		for i: int in list:
			var key := _owner[i] * 2 + _sharp[i]
			if key != group_key:
				if group_sharp:
					sharp = minf(sharp, group)
				else:
					rounded = _smooth_min(rounded, group, _blend)
				group = OUTSIDE
				group_key = key
				group_sharp = _sharp[i] == 1
			var d := _box_distance(p, i) if group_sharp else _tube_distance(p, i)
			if d < nearest:
				nearest = d
				nearest_type = _type[i]
				nearest_sharp = group_sharp
			group = minf(group, d)
		if group_sharp:
			sharp = minf(sharp, group)
		else:
			rounded = _smooth_min(rounded, group, _blend)

	for m in _mouths.size():
		if _mouths[m].grow(_reach_margin).has_point(p):
			var d := TunnelLayout.box_distance(p, _mouths[m])
			sharp = minf(sharp, d)
			if d < nearest:
				nearest = d
				nearest_type = _mouth_types[m]
				nearest_sharp = true

	last_type = nearest_type
	last_sharp = nearest_sharp
	var total := minf(rounded, sharp)
	var calm := smoothstep(0.0, SHARP_CALM_DISTANCE, sharp - rounded)
	for centre in _lock_centres:
		calm = minf(calm, smoothstep(LOCK_CALM_INNER, LOCK_CALM_OUTER, p.distance_to(centre)))
	if calm > 0.0:
		total += _noise.get_noise_3dv(p) * _noise_amplitude * calm
	return total


## Rounded tube: an ellipse across the tunnel, its widest point part way up,
## with the part below squashed by floor_flatten so the floor is walkable.
func _tube_distance(p: Vector3, i: int) -> float:
	var ap := p - _a[i]
	var t := clampf(ap.dot(_ab[i]) * _inv_len_sq[i], 0.0, 1.0)
	var half_width := lerpf(_wa[i], _wb[i], t) * 0.5
	var height := lerpf(_ha[i], _hb[i], t)
	var below := height / (1.0 + _floor_flatten)
	var d := ap - _ab[i] * t
	var up := d.y - below
	var vertical := (height - below) if up > 0.0 else below
	var across := Vector2(d.x, d.z).length()
	# Ellipse distance, first-order: the implicit value over its gradient.
	# Stays close to true distance near the surface however squat the
	# tunnel is, so rock noise and blending are even all the way round.
	var k0 := Vector2(across / half_width, up / vertical).length()
	var k1 := Vector2(across / (half_width * half_width), up / (vertical * vertical)).length()
	if k1 < 0.000001:
		return -minf(half_width, vertical)
	return k0 * (k0 - 1.0) / k1


## Box section: flat floor, walls and ceiling. It runs half a width past each
## end of the segment so consecutive segments meet in square corners.
func _box_distance(p: Vector3, i: int) -> float:
	var ap := p - _a[i]
	var half_width := _wa[i] * 0.5
	var half_height := _ha[i] * 0.5
	var half_length := _len[i] * 0.5
	var q := Vector3(
		absf(ap.dot(_fwd[i]) - half_length) - (half_length + half_width),
		absf(ap.dot(_side[i])) - half_width,
		absf(ap.dot(_up[i]) - half_height) - half_height,
	)
	return q.max(Vector3.ZERO).length() + minf(maxf(q.x, maxf(q.y, q.z)), 0.0)


static func _smooth_min(a: float, b: float, k: float) -> float:
	var h := maxf(k - absf(a - b), 0.0) / k
	return minf(a, b) - h * h * k * 0.25
