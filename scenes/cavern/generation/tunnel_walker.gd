class_name TunnelWalker
extends RefCounted
## The growing end of one tunnel while TunnelLayout builds a layer: where it
## is, where it's heading, and its current size. TunnelTypes steer it.
## Kept in its own file, free of other cavern classes, so tunnel types can use
## it without a load cycle (TunnelLayout -> CavernSettings -> tunnel type
## resources -> TunnelType).
## See docs/policies/dungeon-exploration.md.

var id: int
var parent_id: int
## Floor point at the tunnel's centreline.
var pos: Vector3
var yaw: float
var pitch := 0.0
var width: float
var height: float
## Index into TunnelLayout.types.
var type: int
## Metres travelled since the tunnel last changed type.
var type_travelled := 0.0
## Factory tunnels: metres left in the current straight run, metres since
## the last turn, and the side of a turn that's due (0 if none).
var run_left := 0.0
var leg := 0.0
var turn_side := 0.0
var remaining: float
var travelled := 0.0
var steps := 0
var steps_since_branch := 0
var steps_since_room := 0
## Steps during which the parent tunnel or room is ignored, so a new
## tunnel can get clear of what it started from.
var grace_steps: int
var noise_offset: float
## Size of the room opening the tunnel starts from, or zero. Rounded
## tunnels widen out from it rather than starting at full size.
var entry_size := Vector2.ZERO
