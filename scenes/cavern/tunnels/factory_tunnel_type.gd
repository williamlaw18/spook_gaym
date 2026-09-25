class_name FactoryTunnelType
extends TunnelType
## A sharp-edged, box-section corridor with flat walls, floor and ceiling. It
## follows long, straight, level routes along the world axes, turning 90
## degrees between runs, and keeps one width and height for the whole
## stretch so its corners and junctions line up. Confusion shortens the runs.

@export_group("Runs")
## Length of a straight run before the corridor turns, at confusion 0.
## Confusion divides it by (1 + confusion).
@export var run_length_min := 30.0
@export var run_length_max := 70.0
## A new factory tunnel runs at least this far (unless it's blocked), so it
## reads as a route rather than a stub.
@export var min_length := 40.0
## Shortest straight stretch between two turns. A corridor blocked sooner
## than this after a turn ends there instead of zigzagging.
@export var min_leg_length := 16.0


func is_sharp() -> bool:
	return true


func begin(w: TunnelWalker, confusion: float, rng: RandomNumberGenerator) -> void:
	super(w, confusion, rng)
	w.remaining = maxf(w.remaining, min_length)
	w.yaw = snappedf(w.yaw, PI * 0.5)
	w.pitch = 0.0
	# A new corridor may turn straight away if it has to; only later turns
	# need a full leg between them.
	w.leg = min_leg_length
	w.turn_side = 0.0
	w.run_left = _run_length(confusion, rng)


func steer(w: TunnelWalker, _confusion: float, _noise: FastNoiseLite, rng: RandomNumberGenerator) -> Vector2:
	w.pitch = 0.0
	# Near its end the corridor just carries on, rather than ending in a hook.
	if w.run_left <= 0.0 and w.turn_side == 0.0 and w.remaining >= min_leg_length:
		w.turn_side = 1.0 if rng.randf() < 0.5 else -1.0
	return Vector2(w.width, w.height)


## Always relative to the current heading, so a corridor never doubles back.
func turn_offsets(w: TunnelWalker) -> Array[float]:
	var quarter := PI * 0.5
	if w.turn_side != 0.0:
		return [w.turn_side * quarter, -w.turn_side * quarter, 0.0]
	if w.leg < min_leg_length:
		return [0.0]
	return [0.0, quarter, -quarter]


func advanced(w: TunnelWalker, distance: float, turned: bool, confusion: float, rng: RandomNumberGenerator) -> void:
	w.run_left -= distance
	w.leg += distance
	if turned:
		w.leg = distance
	# A turn (planned or forced) starts a new run. So does going straight on
	# when a planned turn was blocked.
	if turned or w.turn_side != 0.0:
		w.run_left = _run_length(confusion, rng)
		w.turn_side = 0.0


func branch_yaw(w: TunnelWalker, rng: RandomNumberGenerator) -> float:
	return w.yaw + PI * 0.5 * (1.0 if rng.randf() < 0.5 else -1.0)


func _run_length(confusion: float, rng: RandomNumberGenerator) -> float:
	return rng.randf_range(run_length_min, run_length_max) / (1.0 + confusion)
