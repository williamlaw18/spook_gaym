class_name DebugMap
extends Control
## Dev overlay: top-down map of the current cavern layout, toggled with the
## debug_map action (M). North (-Z) is up; lighter tunnels and rooms are
## higher.

const MARGIN := 48.0
const BACKGROUND := Color(0, 0, 0, 0.8)
const TUNNEL_LOW := Color(0.25, 0.23, 0.21)
const TUNNEL_HIGH := Color(0.85, 0.8, 0.72)
const LOCK_COLOR := Color(0.75, 0.35, 0.9)
const HOTSPOT_COLOR := Color(1.0, 0.5, 0.1, 0.12)
const ENTRANCE_COLOR := Color(0.3, 0.9, 0.3)
const LINK_A_COLOR := Color(0.95, 0.3, 0.3)
const LINK_B_COLOR := Color(0.35, 0.5, 1.0)
const PLAYER_COLOR := Color(1.0, 0.9, 0.2)
const ROOM_OUTLINE := Color(1.0, 1.0, 1.0, 0.5)
const MOUTH_COLOR := Color(0.9, 0.8, 0.3, 0.6)
## Sharp (factory) tunnels are tinted toward this.
const SHARP_TINT := Color(0.4, 0.6, 0.8)

var layout: TunnelLayout
var confusion: ConfusionField
var player: Node3D
## Shown in the top-left corner.
var info := ""

var _scale := 1.0
var _offset := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_map"):
		visible = not visible


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	if layout == null or layout.segment_count() == 0:
		return

	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var y_lo := INF
	var y_hi := -INF
	for p in layout.seg_a + layout.seg_b:
		lo = lo.min(Vector2(p.x, p.z))
		hi = hi.max(Vector2(p.x, p.z))
		y_lo = minf(y_lo, p.y)
		y_hi = maxf(y_hi, p.y)
	var extent := (hi - lo).max(Vector2.ONE)
	_scale = minf((size.x - MARGIN * 2.0) / extent.x, (size.y - MARGIN * 2.0) / extent.y)
	_offset = size * 0.5 - (lo + hi) * 0.5 * _scale

	for hotspot in confusion.hotspots:
		draw_circle(_to_map(hotspot), confusion.hotspot_radius * _scale, HOTSPOT_COLOR)

	for room in layout.rooms:
		var color := TUNNEL_LOW.lerp(TUNNEL_HIGH, inverse_lerp(y_lo, y_hi, room.bounds.position.y) if y_hi > y_lo else 0.5)
		var rect := Rect2(_to_map(room.bounds.position), Vector2(room.bounds.size.x, room.bounds.size.z) * _scale)
		draw_rect(rect, color.darkened(0.3))
		draw_rect(rect, ROOM_OUTLINE, false, 1.5)
	for mouth in layout.mouths:
		draw_rect(Rect2(_to_map(mouth.position), Vector2(mouth.size.x, mouth.size.z) * _scale), MOUTH_COLOR)

	# Draw lower tunnels first so higher ones sit on top where they cross.
	var order := range(layout.segment_count())
	order.sort_custom(func(a: int, b: int) -> bool:
		return layout.seg_a[a].y + layout.seg_b[a].y < layout.seg_a[b].y + layout.seg_b[b].y)
	for i: int in order:
		var a := layout.seg_a[i]
		var b := layout.seg_b[i]
		var color := LOCK_COLOR
		if not layout.lock_owners.has(layout.seg_owner[i]):
			color = TUNNEL_LOW.lerp(TUNNEL_HIGH, inverse_lerp(y_lo, y_hi, (a.y + b.y) * 0.5) if y_hi > y_lo else 0.5)
			if layout.seg_sharp[i] == 1:
				color = color.lerp(SHARP_TINT, 0.35)
		var width := (layout.seg_wa[i] + layout.seg_wb[i]) * 0.5 * _scale
		draw_line(_to_map(a), _to_map(b), color, width)
		if layout.seg_sharp[i] == 0:
			draw_circle(_to_map(a), layout.seg_wa[i] * 0.5 * _scale, color)
			draw_circle(_to_map(b), layout.seg_wb[i] * 0.5 * _scale, color)

	draw_circle(_to_map(layout.entrance), 5.0, ENTRANCE_COLOR)
	for pair: Array in layout.links:
		var a: Vector3 = (pair[0] as Transform3D).origin
		var b: Vector3 = (pair[1] as Transform3D).origin
		draw_dashed_line(_to_map(a), _to_map(b), Color(1, 1, 1, 0.35), 1.5, 6.0)
		draw_circle(_to_map(a), 5.0, LINK_A_COLOR)
		draw_circle(_to_map(b), 5.0, LINK_B_COLOR)

	if player:
		var pos := _to_map(player.global_position)
		var forward := -player.global_basis.z
		draw_line(pos, pos + Vector2(forward.x, forward.z).normalized() * 14.0, PLAYER_COLOR, 2.0)
		draw_circle(pos, 5.0, PLAYER_COLOR)

	var font := ThemeDB.fallback_font
	var lines := [
		info,
		"M: close map   F2: regenerate",
		"green: entrance   red/blue: impossible link   orange: confusion hotspot",
		"outlined: rooms   yellow: room openings   blue-tinted: factory tunnels",
	]
	for n in lines.size():
		draw_string(font, Vector2(16, 24 + n * 18), lines[n], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.85))


func _to_map(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z) * _scale + _offset
