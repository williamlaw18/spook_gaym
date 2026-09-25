# Dungeon Exploration

Status: draft

## Summary

Below the homebase are procedurally generated caverns/dungeons, explored in
the style of Lethal Company: the player descends, gathers resources, and
must decide when to push further versus retreat.

The threats in these caverns are not generic spawns — they are, at least in
part, the same monsters the player has assembled at the homebase and
released (see `monster-creation.md`). Exploration is therefore a direct
consequence of the player's own progression: the more the player has
created, the more dangerous their own caverns become (Core Tenet 1).

The player is not built to fight — evasion, not combat, is the intended
stance against threats in the caverns.

Extraction pressure comes from two things combined: limited carry capacity
(forcing return trips) and danger that escalates the longer the player
stays on a descent.

## Procedural Generation

The caverns should not read as square/gridded. Layouts are winding and
confusing — non-Euclidean in feel, meant to disorient rather than lay out
cleanly.

Occasionally (not often — a rare, deliberate occurrence rather than a
constant gimmick), the layout should do something physically impossible:
going one way brings you out somewhere that shouldn't be reachable from
where you went in, portal-games-style. This is meant to feel trippy and
uncanny, reinforcing the horror/visual-strangeness tone, not to be a
frequent puzzle mechanic.

**Confusion as a parameter.** The idea being explored: "confusion" (how
winding/tricky/non-Euclidean a layout is) is a variable parameter to
generation, not a fixed baseline. Depth increases confusion the deeper you
go. World corruption acts as a modifier on top of that depth-driven
confusion — corruption doesn't just add its own separate effect, it
amplifies whatever confusion is already there (a simple layout becomes
moderately complex, an already-complex layout becomes wildly complex).
Confusion might also not be uniform across a whole layer — certain areas of
a layer, or proximity to certain kinds of monsters, could locally run a
higher confusion value than the rest of that layer. This is still an idea
being explored, not a locked design.

## Rooms and Tunnel Types

Generation works from a set of pieces that can be viewed and edited in
Godot:

- **Rooms are presets.** Each room is a hand-built scene with a few
  openings that tunnels attach to. Generation picks rooms from the set and
  places them. Any room can connect to any tunnel type.
- **Tunnel types** set how a tunnel looks and how it shapes. Tunnels stay
  procedural, with modifiers such as width and height (more to come).
- A tunnel mostly keeps its type, but occasionally changes; once it
  changes, it stays that way for a fair while unless confusion is high.

The first set is two tunnel types and two rooms, cave and factory:

- **Cave tunnel**: winding. **Factory tunnel**: sharp-edged.
- **Cave room**: a simple misshapen room with 2 openings.
- **Factory room**: a square room with a mezzanine platform and stairs up
  to it, with 3 openings (two downstairs, one from the mezzanine).

## Implementation (first pass)

Lives in `scenes/cavern/`: `generation/` holds the generator, `rooms/` the
room presets and `tunnels/` the tunnel types. All tuning is on
`CavernSettings`, exposed on the `Cavern` node alongside `depth`,
`corruption` and `generation_seed`, including the lists of tunnel types and
rooms to use. Values are placeholders to tune in play.

1. **Confusion** (`confusion_field.gd`): layer confusion =
   `(base + per_depth * (depth - 1)) * (1 + corruption * amplification)`, so
   corruption multiplies whatever depth produced. A few random hotspots
   raise it locally, fading out over their radius.
2. **Tunnel types** (`tunnels/`): a `TunnelType` resource steers a tunnel
   and sets its cross-section. Every type has a width range, and height
   scales with width: height = width × a ratio (`height_ratio_min`-`max`,
   0.65-0.85), never below `min_height` (3.2 m). Wider stretches are
   taller, so a 10 m wide cave is about 6.5-8.5 m tall. Types steer a `TunnelWalker` (`generation/tunnel_walker.gd`), the growing
   end of a tunnel. It's kept separate from `TunnelLayout` so tunnel types
   don't form a load cycle with it.
   - `CaveTunnelType` (`cave_tunnel.tres`): a rounded tube with a flattened
     floor and rough rock walls. Heading, pitch, width and height ratio
     drift on smooth noise. Width is 4.5-10 m, and `width_contrast` makes the drift
     reach both ends of that range, so a single tunnel pinches and swells
     (typically by around 5 m along its length). Local confusion sharpens
     turns and makes them switch direction more often.
   - `FactoryTunnelType` (`factory_tunnel.tres`): a box-section corridor
     with flat walls, floor and ceiling, 4-8 m wide. It runs straight and
     level along the world axes and turns 90° between runs. It keeps one
     width and height for its whole stretch so corners and junctions line
     up; width varies between corridors, not along one. Confusion shortens
     the runs (a placeholder choice that mirrors the cave type; not
     specified).
3. **Layout** (`tunnel_layout.gd`): tunnels are walkers that step forward
   as their type steers them. A layer starts on a random type, and
   branches and room exits carry their tunnel's type on. Past a minimum
   stretch (`type_min_stretch`), a tunnel has a small chance per step
   (`type_change_chance`) of changing to another type. Confusion divides
   the stretch and multiplies the chance by
   `1 + confusion * type_change_confusion`. Local confusion also raises the
   branch chance and the chance that a blocked tunnel joins the one
   blocking it (a loop) instead of ending. Clearance checks skip a
   tunnel's own most recent segments, further back the wider it is, so a
   wide tunnel never blocks itself. Growth continues until the
   layer's length budget is spent. Room openings still waiting at that
   point get a short tunnel each, so none is left as a stub.
4. **Rooms** (`rooms/`): a tunnel sometimes opens into a room picked at
   random from `CavernSettings.rooms`. The room is turned in 90° steps so
   one of its openings faces the tunnel, and placed with that opening's
   floor level with the tunnel's floor. Each other opening starts a new
   tunnel of the same type; one of them carries the original tunnel on.
   Every opening gets a short **mouth**: a flat-sided box of air exactly
   the opening's floor height and slightly bigger than the opening, so any
   tunnel type meets it cleanly. Rounded tunnels narrow to just wrap the
   mouth over `opening_taper_length` (8 m) on the way into a room, and
   widen back out over the same distance leaving one, so a wide cave
   funnels into a doorway instead of meeting it as a flat wall. Box-section
   tunnels keep their size and meet the room wall square. The factory
   room's stairs are drawn as steps but walked as an invisible ramp, since
   the player controller can't climb steps. The posts under its mezzanine are my addition for
   the factory feel, not something specified.
5. **Surface** (`cave_sdf.gd`, `surface_nets.gd`): tunnels and mouths
   become a signed distance field. The rounded cross-section's distance
   uses a gradient-corrected ellipse estimate, so rock noise stays even
   around wide, squat tunnels. Only each segment's cross-section (plus a
   margin) is sampled. Rounded tunnels smooth-blend where they
   meet and get rock noise. Sharp tunnels and mouths join with hard unions
   and no noise, so a factory corridor meeting a cave reads as a rough hole
   broken through a flat wall. Rounded parts are meshed with surface nets
   (smooth, low-poly, no square edges). Sharp parts use dual contouring,
   which keeps flat walls and hard corners, and are flat shaded. Tunnel
   surfaces inside a room's shell are cut away, since rooms bring their own
   geometry. Vertices are coloured by tunnel type as a placeholder.
   Collision uses the same triangles.
6. **Impossible transitions** (`impossible_link.gd`): with a set chance per
   layer, two identical S-bend "locks" are attached to tunnel ends far
   apart. They're snapped to the grid and rotated in 90° steps, with no rock
   noise, so both mesh identically. Crossing one's centre moves the player
   to the same spot in the other, and walking back reverses it. The bends
   hide what's past each end, so the jump is seamless. Locks are always
   rounded, whatever type the tunnels they join are, and a fixed size
   (4.4 m wide); rounded tunnels narrow into them the same way as into
   rooms.

### Making rooms and tunnel types

- **A new room** is a scene whose root has `cavern_room.gd` (`CavernRoom`),
  added to `CavernSettings.rooms`. Its origin is at floor level.
  - Build it inside a solid `CSGBox3D` shell and set `shell_path` to it.
	The shell's box is the room's bounds: tunnels keep clear of it, and
	tunnel surfaces inside it are cut away.
  - Add a `RoomConnector` (`room_connector.gd`) as a direct child of the
	root for each opening. Place it on a shell face, at the centre of the
	opening's floor edge, with its forward (-Z) axis pointing out of the
	room along X or Z, and set its `size`. The editor draws its outline and
	an outward arrow. Cut the opening through the shell to match.
  - Keep openings a few metres from the shell's edges and well below its
	top, so a wide tunnel's end still lands on that face.
  - Anything the player climbs needs ramp collision rather than steps.
- **A new tunnel type** is a `TunnelType` resource added to
  `CavernSettings.tunnel_types`. Width, height ratio and colour are on
  every type. A new *shape* of tunnel needs a new `TunnelType` subclass: the
  distance field currently knows two cross-sections, rounded and box.

Dev: run `cavern.tscn` directly (F6). F2 regenerates with a new seed; M
toggles a top-down debug map (`debug_map.gd`) showing tunnels shaded by
height (factory tunnels tinted blue), rooms and their openings, the player,
the entrance, impossible links and confusion hotspots. The cavern's
environment, the light on the player and the surface colours are
placeholders until the visual style is decided. Generation takes roughly
2-4 seconds per layer at the current size.

## Open questions

Everything below is undecided and needs to be discussed, not assumed.

- What tools/abilities does the player actually have for evasion?
- How does capture (for the sacrifice sub-chain) work as a mechanic,
  separate from evasion?
- What exactly drives escalating danger over time, and how is carry
  capacity structured?
- How rare "occasional" impossible transitions should be in practice
  (currently a 35% chance of one link per layer), and whether confusion
  should affect that.
- The confusion formula's curve and caps (the current linear depth curve is
  a placeholder), and whether hotspots should be tied to features rather
  than placed randomly.
- Confusion hotspots from monster proximity — not implemented, since
  monsters don't exist yet.
- Layer size and shape: how much tunnel a layer has, and how much vertical
  variation it has.
- Room frequency after the tunnel widening: rooms fell from about 2.4 to
  1.6 per layer, since wider tunnels take more space and room spacing is
  measured in tunnel widths. Whether to compensate (e.g. `room_chance`) is
  undecided.
- What rooms are for (resources, monsters, anything else), whether room
  count/type should vary with depth, corruption or confusion, and whether
  factory rooms mean something in the fiction. Rooms are currently picked
  uniformly at random from the set.
- Whether the mix of tunnel types (which one a layer starts on, which one
  a tunnel changes to) should depend on depth, corruption or anything
  else. Currently both are uniform random.
- Whether factory tunnels should ever slope or have stairs (they're
  currently always level), and whether impossible-link locks should take
  on the shape of the tunnels they join.
- Where the cavern entrance connects to the homebase, and how layers
  connect to each other. (The homebase has a placeholder entrance that
  loads the cavern; see `interaction.md`.)
- Whether there are depth tiers, and if so how they're structured/gated.
- What failure/death during a descent actually costs the player.
- How corruption (if at all) touches the caverns specifically.
- Whether/how the player can tell their own created monsters apart from
  other cavern creatures.
