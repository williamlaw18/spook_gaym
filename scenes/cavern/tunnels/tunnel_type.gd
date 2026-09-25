class_name TunnelType
extends Resource
## A kind of tunnel the cavern generator can grow: how it steers and what its
## cross-section looks like. Subclasses define the shape (CaveTunnelType,
## FactoryTunnelType). Width and height are the procedural modifiers every
## type shares. See docs/policies/dungeon-exploration.md.

## How common this type is relative to the others: used when a layer picks
## its first type and whenever a tunnel may change type.
@export var weight := 1.0
## Placeholder surface colour until the visual style is decided.
@export var color := Color(0.35, 0.31, 0.28)

@export_group("Size")
## Full width of the tunnel (metres).
@export var width_min := 3.6
@export var width_max := 4.8
## Floor-to-ceiling height as a fraction of the width, so wider stretches
## are also taller.
@export var height_ratio_min := 0.65
@export var height_ratio_max := 0.85
## Height never goes below this (metres), so narrow stretches stay walkable.
@export var min_height := 3.2


## True for flat-walled, hard-cornered tunnels; false for rounded, rough ones.
func is_sharp() -> bool:
	return false


## Called when a walker starts on this type, or a tunnel changes to it.
func begin(w: TunnelWalker, _confusion: float, rng: RandomNumberGenerator) -> void:
	w.width = rng.randf_range(width_min, width_max)
	w.height = height_for(w.width, rng.randf_range(height_ratio_min, height_ratio_max))


## Floor-to-ceiling height for a tunnel `width` wide at a given height ratio.
func height_for(width: float, ratio: float) -> float:
	return maxf(min_height, width * ratio)


## Sets the walker's heading for its next step and returns the tunnel size
## (width, height) at the end of that step.
func steer(w: TunnelWalker, _confusion: float, _noise: FastNoiseLite, _rng: RandomNumberGenerator) -> Vector2:
	return Vector2(w.width, w.height)


## Heading offsets (radians) to try, in order, when the way ahead is blocked.
## The first is always straight on.
func turn_offsets(_w: TunnelWalker) -> Array[float]:
	return [0.0]


## Called after the walker takes a step. `turned` is true if it had to turn
## away from its planned heading to get past something.
func advanced(_w: TunnelWalker, _distance: float, _turned: bool, _confusion: float, _rng: RandomNumberGenerator) -> void:
	pass


## Heading for a branch forking off the walker.
func branch_yaw(w: TunnelWalker, _rng: RandomNumberGenerator) -> float:
	return w.yaw
