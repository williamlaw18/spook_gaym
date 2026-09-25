class_name CaveTunnelType
extends TunnelType
## A winding, rounded tunnel with a flattened floor and rough rock walls. Its
## heading, pitch and size drift on smooth noise; confusion sharpens its turns
## and makes them switch direction more often.

@export_group("Winding")
## Maximum heading change per step at confusion 0.
@export var min_turn_degrees := 6.0
## Maximum heading change per step at confusion 1 and above. Past 1,
## confusion makes turns switch direction more often instead of sharper.
@export var max_turn_degrees := 25.0
@export var max_pitch_degrees := 20.0

@export_group("Width Drift")
## How far the width swings through its range as it drifts. At 1 it rarely
## gets near width_min or width_max; higher values reach them more often and
## hold them for longer, giving tight pinches and wide stretches.
@export var width_contrast := 1.5


func steer(w: TunnelWalker, confusion: float, noise: FastNoiseLite, _rng: RandomNumberGenerator) -> Vector2:
	var t := w.noise_offset + w.travelled
	# Confusion both sharpens turns and makes them switch direction more
	# often, so confused tunnels wind in tighter S-bends rather than coil.
	var turn := deg_to_rad(lerpf(min_turn_degrees, max_turn_degrees, minf(confusion, 1.0)))
	w.yaw += clampf(noise.get_noise_1d(t * (1.0 + confusion)) * 2.0, -1.0, 1.0) * turn
	var max_pitch := deg_to_rad(max_pitch_degrees)
	var pitch_range := max_pitch * clampf(0.3 + confusion, 0.0, 1.0)
	w.pitch = clampf(noise.get_noise_1d(t + 5000.0) * 2.0 * pitch_range - w.pos.y * 0.01, -max_pitch, max_pitch)
	var width := _drift(noise, t + 9000.0, width_min, width_max, width_contrast)
	return Vector2(width, height_for(width, _drift(noise, t + 13000.0, height_ratio_min, height_ratio_max)))


func turn_offsets(_w: TunnelWalker) -> Array[float]:
	return [0.0, 0.5, -0.5, 1.0, -1.0]


func branch_yaw(w: TunnelWalker, rng: RandomNumberGenerator) -> float:
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	return w.yaw + side * deg_to_rad(rng.randf_range(60.0, 110.0))


func _drift(noise: FastNoiseLite, t: float, lo: float, hi: float, contrast := 1.0) -> float:
	return lerpf(lo, hi, clampf(noise.get_noise_1d(t) * contrast + 0.5, 0.0, 1.0))
