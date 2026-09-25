class_name ConfusionField
extends RefCounted
## How confusing (winding, branching, looping) generation is at a point in a
## layer. Depth sets the layer's base confusion, corruption amplifies it, and
## hotspots raise it locally. See docs/policies/dungeon-exploration.md.

var layer_confusion: float

var hotspots := PackedVector3Array()
var hotspot_radius: float
var _hotspot_strength: float


func _init(settings: CavernSettings, depth: int, corruption: float, rng: RandomNumberGenerator, extent: float) -> void:
	var depth_confusion := settings.base_confusion + settings.confusion_per_depth * maxi(depth - 1, 0)
	layer_confusion = depth_confusion * (1.0 + corruption * settings.corruption_amplification)
	hotspot_radius = settings.hotspot_radius
	_hotspot_strength = settings.hotspot_strength
	for i in settings.hotspot_count:
		var angle := rng.randf() * TAU
		var distance := rng.randf() * extent
		hotspots.append(Vector3(cos(angle) * distance, 0.0, sin(angle) * distance))


func sample(pos: Vector3) -> float:
	var boost := 0.0
	for hotspot in hotspots:
		# Hotspots are vertical columns, so height doesn't matter.
		var distance := Vector2(pos.x - hotspot.x, pos.z - hotspot.z).length()
		boost += maxf(0.0, 1.0 - distance / hotspot_radius)
	return layer_confusion * (1.0 + boost * _hotspot_strength)
