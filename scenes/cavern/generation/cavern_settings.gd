class_name CavernSettings
extends Resource
## Tuning for procedural cavern generation. Every value here is a first-pass
## placeholder to be tuned in play. See docs/policies/dungeon-exploration.md.

@export_group("Confusion")
## Layer confusion at depth 1.
@export var base_confusion := 0.2
## Confusion added per depth level below 1.
@export var confusion_per_depth := 0.15
## Corruption multiplies depth confusion by (1 + corruption * this).
@export var corruption_amplification := 1.0
## Areas of a layer that run more confused than the rest.
@export var hotspot_count := 3
@export var hotspot_radius := 25.0
## Extra confusion at a hotspot's centre, as a multiple of the layer value.
@export var hotspot_strength := 1.0

@export_group("Tunnels")
## The tunnel types generation can use. The first tunnel, branches and extra
## room exits each pick one by weight (see TunnelType.weight).
@export var tunnel_types: Array[TunnelType] = [
	preload("res://scenes/cavern/tunnels/cave_tunnel.tres"),
	preload("res://scenes/cavern/tunnels/factory_tunnel.tres"),
]
## Total tunnel length in the layer, across all branches (metres).
@export var total_length := 350.0
@export var main_tunnel_length := 140.0
## Length of a new branch. A branch blocked before branch_length_min is
## removed rather than left as a stub, and no branch is started once less
## than that is left in the layer's budget.
@export var branch_length_min := 25.0
@export var branch_length_max := 40.0
@export var step_length := 2.0
## Chance per step to fork a branch, and how much confusion adds to it.
@export var branch_chance := 0.06
@export var branch_chance_per_confusion := 0.12
## Chance a blocked tunnel joins the one blocking it (a loop) instead of
## dead-ending, and how much confusion adds to it.
@export var loop_chance := 0.5
@export var loop_chance_per_confusion := 0.5
## Minimum rock between neighbouring tunnels and rooms (metres).
@export var clearance := 1.5

@export_group("Tunnel Type Changes")
## How far a tunnel keeps its type before it can change, at confusion 0
## (metres).
@export var type_min_stretch := 40.0
## Chance per step, once past the minimum stretch, that the tunnel re-picks
## its type by weight. It may pick the same type, so the chance of actually
## changing is lower for common types.
@export var type_change_chance := 0.05
## Confusion divides the minimum stretch by (1 + confusion * this), and
## multiplies the change chance by the same amount.
@export var type_change_confusion := 3.0

@export_group("Rooms")
## The preset rooms generation can place (scenes with a CavernRoom root).
@export var rooms: Array[PackedScene] = [
	preload("res://scenes/cavern/rooms/cave_room_01.tscn"),
	preload("res://scenes/cavern/rooms/factory_room_01.tscn"),
]
## Chance per tunnel step to open into a room.
@export var room_chance := 0.08
## How far the straight, opening-shaped mouth of a tunnel sticks out from a
## room's opening before the tunnel's own shape takes over.
@export var mouth_length := 2.0
## Extra size on the sides and top of a mouth, so it fully covers the opening.
@export var mouth_margin := 0.3
## Rounded tunnels narrow to fit a room opening or impossible-link lock over
## this distance, rather than meeting it as a flat wall.
@export var opening_taper_length := 8.0

@export_group("Impossible Links")
## Chance of each impossible link, rolled up to impossible_link_max times
## per layer.
@export_range(0.0, 1.0) var impossible_link_chance := 0.7
@export_range(0, 8) var impossible_link_max := 2
## Minimum distance between the two ends of a link.
@export var impossible_link_min_distance := 40.0

@export_group("Mesh")
@export var cell_size := 1.0
## Squashes the lower half of a rounded tunnel's profile into a walkable
## floor: below its widest point it is this many times shallower than above.
@export var floor_flatten := 1.6
## How smoothly separate rounded tunnels blend where they meet.
@export var blend := 1.5
@export var noise_amplitude := 0.6
@export var noise_frequency := 0.12
