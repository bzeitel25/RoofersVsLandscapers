extends Node3D
# ============================================================
# ROOFERS vs LANDSCAPERS — Procedural Suburban Arena Generator
# ============================================================
# Builds a small upper-class cul-de-sac test arena entirely in
# code so the layout is parametric and tweakable. Attach this to
# a Node3D that sits under a level running test_level.gd (which
# keeps the training UI + Player rig). Everything is generated as
# children of THIS node at _ready().
#
# DESIGN GOALS (see AGENT_HANDOFF.md):
#   * Exercise the parkour toolkit — vaulting, roof-sliding, ziplines.
#   * Enterable houses with roof / chimney / attic infiltration routes.
#   * Big, camera-friendly interiors for a spring-arm TPS (no cramped
#     rooms that clip the SpringArm3D; tall ceilings, wide doorways,
#     open-concept + double-height entry + mezzanine).
#
# GODOT 4 RULES HONORED:
#   * All static world geometry is on collision layer 1 (WORLD_LAYER)
#     — that is what the player's floor query and the vault raycasts
#     (mask == 1) detect. See player_character.gd.
#   * No RigidBody3D is scaled — every collider here is a StaticBody3D
#     and we size the BoxShape/BoxMesh directly (never via `scale`).
#   * Forward is -Z: each house is built in local space with its
#     FRONT on local -Z, then yaw-rotated to face the cul-de-sac.
#
# PARKOUR TUNING TARGETS (from player_character.gd):
#   * Vault: ledge top ~1.0–1.8 m above the approach → fences, planter
#     rims, low walls, car roofs, roof-edge parapets are all vaultable.
#   * Roof slide: floor angle > 5° + hold Crouch → ROOF_PITCH_DEG (~32°).
# ============================================================

const WORLD_LAYER := 1  # static environment collision layer

# ---- Tunables ------------------------------------------------
@export var rng_seed: int = 20260825
@export var ground_size: float = 96.0
@export var house_count: int = 5
@export var house_ring_radius: float = 28.0   # distance of house centers from cul-de-sac center
@export var bulb_radius: float = 15.0         # radius of the circular cul-de-sac road
@export var road_half_width: float = 4.0      # half width of the entry street
@export var island_radius: float = 5.5        # central grass island

# House dimensions (upper-class: large & roomy)
@export var house_width: float = 16.0         # X (local)
@export var house_depth: float = 13.0         # Z (local)
@export var story_height: float = 4.0         # tall ceilings for camera comfort
@export var stories: int = 2
@export var wall_thick: float = 0.3
@export var roof_pitch_deg: float = 32.0
@export var roof_overhang: float = 1.0
@export var roof_ridge_gap: float = 1.4       # open strip at the ridge = attic/roof access
@export var fence_height: float = 1.15        # vaultable

var _rng := RandomNumberGenerator.new()

# ---- Palette (StandardMaterial3D cache) ----------------------
var _mats := {}

func _get_mat(key: String, color: Color, rough: float = 0.95, metal: float = 0.0, emis: Color = Color(0, 0, 0)) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if emis.r + emis.g + emis.b > 0.0:
		m.emission_enabled = true
		m.emission = emis
		m.emission_energy_multiplier = 0.8
	_mats[key] = m
	return m

# ============================================================
# LOW-LEVEL BUILDERS
# ============================================================

# Solid, collidable box (StaticBody3D + BoxMesh + BoxShape). `rot` in radians.
func _solid(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D, rot: Vector3 = Vector3.ZERO, nm: String = "Box") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = nm
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shp := BoxShape3D.new()
	shp.size = size
	cs.shape = shp
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	body.add_child(mi)
	parent.add_child(body)
	body.position = pos
	body.rotation = rot
	return body

# Visual-only box (no collision) — for canopies, decals, etc.
func _decor_box(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	parent.add_child(mi)
	mi.position = pos
	mi.rotation = rot
	return mi

func _cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, mat: StandardMaterial3D, collide: bool = true, nm: String = "Cyl") -> Node3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	if collide:
		var body := StaticBody3D.new()
		body.name = nm
		body.collision_layer = WORLD_LAYER
		body.collision_mask = 0
		var cs := CollisionShape3D.new()
		var shp := CylinderShape3D.new()
		shp.radius = radius
		shp.height = height
		cs.shape = shp
		body.add_child(cs)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		body.add_child(mi)
		parent.add_child(body)
		body.position = pos
		return body
	else:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		parent.add_child(mi)
		mi.position = pos
		return mi

func _sphere(parent: Node3D, radius: float, pos: Vector3, mat: StandardMaterial3D, collide: bool = true, nm: String = "Sph") -> Node3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	if collide:
		var body := StaticBody3D.new()
		body.name = nm
		body.collision_layer = WORLD_LAYER
		body.collision_mask = 0
		var cs := CollisionShape3D.new()
		var shp := SphereShape3D.new()
		shp.radius = radius
		cs.shape = shp
		body.add_child(cs)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		body.add_child(mi)
		parent.add_child(body)
		body.position = pos
		return body
	else:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		parent.add_child(mi)
		mi.position = pos
		return mi

# A vertical wall running from `start` to `end` (both at the wall base, same Y),
# `height` tall and `thick` thick, with rectangular openings cut out.
# openings: Array of Dictionaries {u0,u1,v0,v1}. u = distance along start->end,
# v = height above base. Openings MUST be non-overlapping in u.
func _wall(parent: Node3D, start: Vector3, end: Vector3, height: float, thick: float, mat: StandardMaterial3D, openings: Array = []) -> void:
	var full := start.distance_to(end)
	if full <= 0.001:
		return
	var dir := (end - start) / full
	# Orient the box's local X along `dir` (see notes in AGENT_HANDOFF math):
	var yaw := atan2(-dir.z, dir.x)
	var rot := Vector3(0, yaw, 0)

	# Build the list of u-cut points from opening edges.
	var cuts := [0.0, full]
	for o in openings:
		cuts.append(clampf(o.u0, 0.0, full))
		cuts.append(clampf(o.u1, 0.0, full))
	cuts.sort()

	for i in range(cuts.size() - 1):
		var ua: float = cuts[i]
		var ub: float = cuts[i + 1]
		var seg_len := ub - ua
		if seg_len <= 0.01:
			continue
		var u_mid := (ua + ub) * 0.5
		var base_center := start + dir * u_mid
		# Collect the vertical spans of EVERY opening covering this column
		# (supports stacked windows: e.g. ground-floor + upper-floor).
		var spans := []
		for o in openings:
			if u_mid > o.u0 - 0.001 and u_mid < o.u1 + 0.001:
				spans.append([maxf(o.v0, 0.0), minf(o.v1, height)])
		spans.sort_custom(func(a, b): return a[0] < b[0])
		# Fill the solid pieces = [0, height] minus the union of opening spans.
		var y := 0.0
		for sp in spans:
			if float(sp[0]) > y + 0.01:
				var h: float = float(sp[0]) - y
				_solid(parent, Vector3(seg_len, h, thick),
					Vector3(base_center.x, start.y + y + h * 0.5, base_center.z), mat, rot, "WallSeg")
			y = maxf(y, float(sp[1]))
		if y < height - 0.01:
			var h: float = height - y
			_solid(parent, Vector3(seg_len, h, thick),
				Vector3(base_center.x, start.y + y + h * 0.5, base_center.z), mat, rot, "WallSeg")

# A horizontal slab (floor/ceiling) with an optional rectangular hole.
# Built from up to 4 border boxes in local X/Z. hole given as X/Z ranges.
func _slab_with_hole(parent: Node3D, center: Vector3, sx: float, sz: float, thick: float, mat: StandardMaterial3D, hx0: float = 0.0, hx1: float = 0.0, hz0: float = 0.0, hz1: float = 0.0, nm: String = "Slab") -> void:
	var has_hole := (hx1 - hx0) > 0.05 and (hz1 - hz0) > 0.05
	if not has_hole:
		_solid(parent, Vector3(sx, thick, sz), center, mat, Vector3.ZERO, nm)
		return
	var x_min := -sx * 0.5
	var x_max := sx * 0.5
	var z_min := -sz * 0.5
	var z_max := sz * 0.5
	# Left border (x_min .. hx0), full depth
	if hx0 - x_min > 0.05:
		var w := hx0 - x_min
		_solid(parent, Vector3(w, thick, sz), center + Vector3(x_min + w * 0.5, 0, 0), mat, Vector3.ZERO, nm)
	# Right border (hx1 .. x_max), full depth
	if x_max - hx1 > 0.05:
		var w := x_max - hx1
		_solid(parent, Vector3(w, thick, sz), center + Vector3(hx1 + w * 0.5, 0, 0), mat, Vector3.ZERO, nm)
	# Front border between hx0..hx1, z_min..hz0
	if hz0 - z_min > 0.05:
		var d := hz0 - z_min
		_solid(parent, Vector3(hx1 - hx0, thick, d), center + Vector3((hx0 + hx1) * 0.5, 0, z_min + d * 0.5), mat, Vector3.ZERO, nm)
	# Back border between hx0..hx1, hz1..z_max
	if z_max - hz1 > 0.05:
		var d := z_max - hz1
		_solid(parent, Vector3(hx1 - hx0, thick, d), center + Vector3((hx0 + hx1) * 0.5, 0, hz1 + d * 0.5), mat, Vector3.ZERO, nm)

# A walkable ramp (thin rotated slab) climbing along +Z from y0 to y1 over run.
# Angle stays under the controller's floor limit so it is walkable up,
# and >5° so crouch-sliding works on it too.
func _ramp(parent: Node3D, width: float, run: float, y0: float, y1: float, center_xz: Vector3, mat: StandardMaterial3D, face_pos_z: bool = true) -> void:
	var rise := y1 - y0
	var length := sqrt(run * run + rise * rise)
	var angle := atan2(rise, run)
	var rot_x := -angle if face_pos_z else angle
	var mid := Vector3(center_xz.x, (y0 + y1) * 0.5, center_xz.z)
	_solid(parent, Vector3(width, 0.3, length), mid, mat, Vector3(rot_x, 0, 0), "Ramp")

# ============================================================
# HIGH-LEVEL BUILDERS
# ============================================================

func _ready() -> void:
	_rng.seed = rng_seed
	_build_ground()
	_build_streets_and_island()
	_build_houses()
	_build_perimeter()
	_scatter_common_props()
	print("[SuburbanArena] Neighborhood generated: %d houses." % house_count)

func _build_ground() -> void:
	var grass := _get_mat("grass", Color(0.36, 0.52, 0.24))
	# Ground top surface sits at y = 0 so it matches house floors.
	_solid(self, Vector3(ground_size, 1.0, ground_size), Vector3(0, -0.5, 0), grass, Vector3.ZERO, "Ground")

func _build_streets_and_island() -> void:
	var road := _get_mat("road", Color(0.22, 0.22, 0.24), 1.0)
	var walk := _get_mat("sidewalk", Color(0.62, 0.62, 0.6), 1.0)
	# Cul-de-sac bulb: a flat disc of road (approximate with a thin cylinder).
	_cylinder(self, bulb_radius, 0.08, Vector3(0, 0.04, 0), road, false, "Bulb")
	# Sidewalk ring around the bulb (slightly larger, thin cylinder underneath rim).
	_cylinder(self, bulb_radius + 1.6, 0.05, Vector3(0, 0.025, 0), walk, false, "BulbWalk")
	_cylinder(self, bulb_radius, 0.09, Vector3(0, 0.045, 0), road, false, "BulbTop")
	# Entry street heading out toward +Z.
	var street_len := ground_size * 0.5 - bulb_radius
	_decor_box(self, Vector3(road_half_width * 2.0, 0.08, street_len),
		Vector3(0, 0.04, bulb_radius + street_len * 0.5), road)
	# Central landscaped island.
	_cylinder(self, island_radius, 0.25, Vector3(0, 0.12, 0), _get_mat("grass", Color(0.36, 0.52, 0.24)), true, "Island")
	# A feature tree + flowerbed ring on the island.
	_build_tree(self, Vector3(0, 0.25, 0), 1.3)
	_planter_ring(self, Vector3(0, 0.25, 0), island_radius - 1.2)

func _planter_ring(parent: Node3D, center: Vector3, radius: float) -> void:
	var brick := _get_mat("brick", Color(0.55, 0.28, 0.22))
	var seg := 10
	for i in range(seg):
		var a := TAU * float(i) / float(seg)
		var p := center + Vector3(cos(a) * radius, 0.35, sin(a) * radius)
		_solid(parent, Vector3(1.4, 0.7, 0.5), p, brick, Vector3(0, -a, 0), "PlanterRim")

# --- Houses --------------------------------------------------

func _build_houses() -> void:
	var arc_start := deg_to_rad(-118.0)
	var arc_end := deg_to_rad(118.0)
	for i in range(house_count):
		var t := 0.5 if house_count == 1 else float(i) / float(house_count - 1)
		var ang := lerpf(arc_start, arc_end, t)
		var dir := Vector3(sin(ang), 0, -cos(ang))       # position direction from center
		var pos := dir * house_ring_radius
		# Face the house FRONT (-Z local) toward the center: point +Z along `dir`.
		var yaw := atan2(dir.x, dir.z)
		var house := Node3D.new()
		house.name = "House_%d" % i
		add_child(house)
		house.position = pos
		house.rotation = Vector3(0, yaw, 0)
		_build_single_house(house, i)

func _build_single_house(house: Node3D, index: int) -> void:
	var W := house_width
	var D := house_depth
	var wall_top := story_height * float(stories)     # top of exterior walls / attic floor level
	var wt := wall_thick

	# Per-house wall color variation (upper-class neutrals).
	var wall_colors := [
		Color(0.86, 0.83, 0.75), Color(0.80, 0.78, 0.72), Color(0.90, 0.86, 0.78),
		Color(0.72, 0.74, 0.72), Color(0.84, 0.80, 0.70)
	]
	var roof_colors := [
		Color(0.30, 0.22, 0.20), Color(0.24, 0.26, 0.30), Color(0.36, 0.24, 0.20),
		Color(0.28, 0.30, 0.28), Color(0.22, 0.20, 0.22)
	]
	var wall_mat := _get_mat("wall_%d" % index, wall_colors[index % wall_colors.size()])
	var roof_mat := _get_mat("roof_%d" % index, roof_colors[index % roof_colors.size()])
	var floor_mat := _get_mat("floor_wood", Color(0.45, 0.33, 0.22))
	var glass := _get_mat("glass", Color(0.4, 0.55, 0.7), 0.15, 0.0, Color(0.10, 0.16, 0.22))

	var xh := W * 0.5
	var zh := D * 0.5

	# ---- Ground + attic floor slabs ----
	_solid(house, Vector3(W, 0.2, D), Vector3(0, -0.1, 0), floor_mat, Vector3.ZERO, "GroundFloor")
	# Attic floor (ceiling of top story) with a hatch hole near the back for infiltration.
	_slab_with_hole(house, Vector3(0, wall_top, 0), W, D, 0.2, floor_mat,
		xh - 3.2, xh - 1.0, zh - 3.2, zh - 1.0, "AtticFloor")

	# ---- Partial 2nd-floor mezzanine (back half) with a railing + stairwell hole ----
	if stories >= 2:
		var mezz_y := story_height
		# Mezzanine covers back half (z from 0 to zh). Leave a stairwell hole on one side.
		_slab_with_hole(house, Vector3(0, mezz_y, zh * 0.5), W, zh, 0.2, floor_mat,
			-xh + 1.0, -xh + 4.5, zh * 0.5 - 1.8, zh * 0.5 + 1.8, "Mezzanine")
		# Low railing (vaultable) along the mezzanine's open front edge (z ~ 0).
		_wall(house, Vector3(-xh + 0.4, mezz_y + 0.1, 0.2), Vector3(xh - 0.4, mezz_y + 0.1, 0.2), 1.0, 0.15, wall_mat, [])
		# Ramp-staircase from ground (front) up to the mezzanine along the -X side.
		_ramp(house, 3.0, 5.4, 0.0, mezz_y, Vector3(-xh + 2.6, 0, -1.0), floor_mat, true)
		# Interior ladder from mezzanine up to the attic hatch (roof infiltration link).
		_place_ladder(house, Vector3(xh - 2.1, mezz_y, zh - 2.1), wall_top - mezz_y, deg_to_rad(180.0))

	# ---- Exterior walls (full height) with door + window openings ----
	# Front (-Z): grand door + flanking windows on the ground floor, windows above.
	var front_openings := [
		{"u0": W * 0.5 - 1.2, "u1": W * 0.5 + 1.2, "v0": 0.0, "v1": 3.0},          # front door (centered)
		{"u0": 1.5, "u1": 4.0, "v0": 1.0, "v1": 2.6},                                # left window
		{"u0": W - 4.0, "u1": W - 1.5, "v0": 1.0, "v1": 2.6},                         # right window
	]
	if stories >= 2:
		front_openings.append({"u0": 2.0, "u1": 4.5, "v0": story_height + 1.0, "v1": story_height + 2.6})
		front_openings.append({"u0": W - 4.5, "u1": W - 2.0, "v0": story_height + 1.0, "v1": story_height + 2.6})
	_wall(house, Vector3(-xh, 0, -zh), Vector3(xh, 0, -zh), wall_top, wt, wall_mat, front_openings)

	# Back (+Z): patio door + windows.
	var back_openings := [
		{"u0": 2.0, "u1": 5.0, "v0": 0.0, "v1": 3.0},
		{"u0": W - 5.0, "u1": W - 2.0, "v0": 1.0, "v1": 2.6},
	]
	_wall(house, Vector3(-xh, 0, zh), Vector3(xh, 0, zh), wall_top, wt, wall_mat, back_openings)

	# Left (-X) and Right (+X) side walls with a couple of windows each.
	var side_openings := [
		{"u0": 2.5, "u1": 4.5, "v0": 1.0, "v1": 2.6},
		{"u0": D - 4.5, "u1": D - 2.5, "v0": 1.0, "v1": 2.6},
	]
	_wall(house, Vector3(-xh, 0, -zh), Vector3(-xh, 0, zh), wall_top, wt, wall_mat, side_openings)
	_wall(house, Vector3(xh, 0, -zh), Vector3(xh, 0, zh), wall_top, wt, wall_mat, side_openings)

	# Glass panes behind windows (visual only, non-collide) — read as an occupied house.
	_decor_box(house, Vector3(2.4, 1.5, 0.05), Vector3(-xh + 3.5, 1.8, -zh + 0.05), glass)
	_decor_box(house, Vector3(2.4, 1.5, 0.05), Vector3(xh - 3.5, 1.8, -zh + 0.05), glass)

	# ---- Interior cover (kept LOW & sparse so the spring-arm camera stays clear) ----
	var couch := _get_mat("couch", Color(0.3, 0.35, 0.42))
	_solid(house, Vector3(3.0, 0.9, 1.2), Vector3(-xh + 4.0, 0.45, zh - 3.0), couch, Vector3.ZERO, "Couch")
	_solid(house, Vector3(1.6, 0.8, 1.0), Vector3(xh - 4.0, 0.4, -zh + 4.0), _get_mat("counter", Color(0.5, 0.45, 0.4)), Vector3.ZERO, "Counter")

	# ---- Pitched gable roof (two slabs, ridge along Z) with a ridge gap = roof access ----
	_build_roof(house, W, D, wall_top, roof_mat, index)

	# ---- Exterior side ladder from ground to eave (fixed roof access) ----
	_place_ladder(house, Vector3(-xh - 0.35, 0, zh - 2.0), wall_top - 0.2, deg_to_rad(90.0))

	# ---- Front porch: slab, posts, low roof, steps ----
	_build_porch(house, W, D, wall_mat, roof_mat)

	# ---- Yard: fence, driveway, car, planters, bushes, tree, ornaments, mailbox, rocks ----
	_build_yard(house, index, W, D)

func _build_roof(house: Node3D, W: float, D: float, wall_top: float, roof_mat: StandardMaterial3D, index: int) -> void:
	var pitch := deg_to_rad(roof_pitch_deg)
	var half := W * 0.5
	var eave_over := roof_overhang
	var ridge_y := wall_top + tan(pitch) * half
	var dz := D + roof_overhang * 2.0
	var gap := roof_ridge_gap * 0.5   # half the ridge gap on each side of x=0

	# +X slab: from ridge-gap point to eave/overhang point.
	var ridge_pt := Vector3(gap, ridge_y - tan(pitch) * gap, 0)
	var eave_pt := Vector3(half + eave_over, wall_top - tan(pitch) * eave_over, 0)
	var mid := (ridge_pt + eave_pt) * 0.5
	var slope_len := ridge_pt.distance_to(eave_pt)
	_solid(house, Vector3(slope_len, 0.2, dz), Vector3(mid.x, mid.y, 0), roof_mat, Vector3(0, 0, -pitch), "RoofR")

	# -X slab (mirror).
	var ridge_pt2 := Vector3(-gap, ridge_y - tan(pitch) * gap, 0)
	var eave_pt2 := Vector3(-(half + eave_over), wall_top - tan(pitch) * eave_over, 0)
	var mid2 := (ridge_pt2 + eave_pt2) * 0.5
	_solid(house, Vector3(slope_len, 0.2, dz), Vector3(mid2.x, mid2.y, 0), roof_mat, Vector3(0, 0, pitch), "RoofL")

	# Hollow chimney straddling the ridge gap toward the back — drop through into the attic.
	_build_chimney(house, Vector3(0, wall_top, D * 0.28))

func _build_chimney(house: Node3D, base: Vector3) -> void:
	var brick := _get_mat("brick", Color(0.55, 0.28, 0.22))
	var h := 2.6
	var s := 1.8         # outer footprint
	var t := 0.25        # wall thickness (hollow so players drop through)
	var cy := base.y + h * 0.5
	var off := s * 0.5 - t * 0.5
	# Four thin walls forming an open-topped, open-bottomed shaft.
	_solid(house, Vector3(s, h, t), base + Vector3(0, h * 0.5, -off), brick, Vector3.ZERO, "ChimN")
	_solid(house, Vector3(s, h, t), base + Vector3(0, h * 0.5, off), brick, Vector3.ZERO, "ChimS")
	_solid(house, Vector3(t, h, s - t * 2.0), base + Vector3(-off, h * 0.5, 0), brick, Vector3.ZERO, "ChimW")
	_solid(house, Vector3(t, h, s - t * 2.0), base + Vector3(off, h * 0.5, 0), brick, Vector3.ZERO, "ChimE")

func _build_porch(house: Node3D, W: float, D: float, wall_mat: StandardMaterial3D, roof_mat: StandardMaterial3D) -> void:
	var zh := D * 0.5
	var wood := _get_mat("porch_wood", Color(0.55, 0.42, 0.3))
	var porch_z := -zh - 1.6
	# Porch slab (raised 0.2).
	_solid(house, Vector3(7.0, 0.2, 3.2), Vector3(0, 0.1, porch_z), wood, Vector3.ZERO, "PorchDeck")
	# Two steps up to the porch (vault-friendly low ledges, and just walkable).
	_solid(house, Vector3(7.0, 0.15, 0.5), Vector3(0, 0.075, porch_z - 1.7), wood, Vector3.ZERO, "Step1")
	# Porch posts + low porch roof (adds a lower roof surface to hop onto).
	for sx in [-3.0, 3.0]:
		_solid(house, Vector3(0.25, 3.0, 0.25), Vector3(sx, 1.5, porch_z - 1.4), wall_mat, Vector3.ZERO, "PorchPost")
	_solid(house, Vector3(7.6, 0.2, 3.6), Vector3(0, 3.1, porch_z - 0.2), roof_mat, Vector3.ZERO, "PorchRoof")

# --- Yards & props ------------------------------------------

func _build_yard(house: Node3D, index: int, W: float, D: float) -> void:
	var zh := D * 0.5
	var xh := W * 0.5
	var wood := _get_mat("fence", Color(0.72, 0.6, 0.42))
	var drive_mat := _get_mat("drive", Color(0.5, 0.5, 0.52), 1.0)

	# Driveway from the house front (-Z) toward the street (further -Z).
	var drive_len := house_ring_radius - bulb_radius - 2.0
	drive_len = maxf(drive_len, 6.0)
	_decor_box(house, Vector3(5.0, 0.1, drive_len), Vector3(xh - 4.0, 0.06, -zh - drive_len * 0.5), drive_mat)

	# A parked car on the driveway (future: hotwire + launch).
	_build_car(house, Vector3(xh - 4.0, 0.0, -zh - 3.5), index)

	# Picket fence around the front yard perimeter (vaultable at ~1.15 m), with a gap for the driveway.
	var fy := -zh - drive_len - 0.5   # front fence line
	# Front fence: two runs leaving the driveway open.
	_fence_run(house, Vector3(-xh - 2.0, 0, fy), Vector3(xh - 6.6, 0, fy), wood)
	_fence_run(house, Vector3(xh - 1.4, 0, fy), Vector3(xh + 2.0, 0, fy), wood)
	# Side fences up to the house.
	_fence_run(house, Vector3(-xh - 2.0, 0, fy), Vector3(-xh - 2.0, 0, -zh), wood)
	_fence_run(house, Vector3(xh + 2.0, 0, fy), Vector3(xh + 2.0, 0, -zh), wood)

	# Raised flowerbed / planter along the porch front (cover + vaultable rim).
	_solid(house, Vector3(5.0, 1.0, 0.9), Vector3(-3.0, 0.5, -zh - 3.4), _get_mat("brick", Color(0.55, 0.28, 0.22)), Vector3.ZERO, "Flowerbed")
	_decor_box(house, Vector3(4.6, 0.4, 0.6), Vector3(-3.0, 1.1, -zh - 3.4), _get_mat("flowers", Color(0.7, 0.3, 0.45), 0.9, 0.0, Color(0.15, 0.03, 0.06)))

	# Brick mural / decorative low wall (cover + vault) along one side.
	_solid(house, Vector3(0.4, 1.3, 5.0), Vector3(-xh - 2.0, 0.65, 2.0), _get_mat("brick", Color(0.55, 0.28, 0.22)), Vector3.ZERO, "BrickMural")

	# Bushes (low, some vaultable), a shade tree, ornaments, mailbox, and rocks.
	for k in range(3):
		var bx := _rng.randf_range(-xh - 1.5, xh + 1.5)
		var bz := _rng.randf_range(-zh - drive_len + 1.0, -zh - 1.0)
		_build_bush(house, Vector3(bx, 0, bz))
	_build_tree(house, Vector3(-xh - 1.0, 0, -zh - 6.0), _rng.randf_range(1.0, 1.4))
	_build_mailbox(house, Vector3(xh - 1.0, 0, fy + 0.6))
	_build_ornament(house, Vector3(3.0, 0, -zh - 5.0), index)
	_build_rock_cluster(house, Vector3(xh + 0.5, 0, -zh - 8.0))

func _fence_run(parent: Node3D, start: Vector3, end: Vector3, mat: StandardMaterial3D) -> void:
	# A solid low wall serves as the fence collider (vaultable). Add post caps for looks.
	var full := start.distance_to(end)
	if full < 0.2:
		return
	var dir := (end - start) / full
	var yaw := atan2(-dir.z, dir.x)
	var mid := (start + end) * 0.5
	_solid(parent, Vector3(full, fence_height, 0.12), Vector3(mid.x, fence_height * 0.5, mid.z), mat, Vector3(0, yaw, 0), "Fence")
	var posts := int(full / 2.0) + 1
	for i in range(posts + 1):
		var p := start + dir * (full * float(i) / float(posts))
		_decor_box(parent, Vector3(0.16, fence_height + 0.2, 0.16), Vector3(p.x, (fence_height + 0.2) * 0.5, p.z), mat, Vector3(0, yaw, 0))

func _build_car(parent: Node3D, pos: Vector3, index: int) -> void:
	var car_colors := [Color(0.7, 0.15, 0.15), Color(0.15, 0.2, 0.5), Color(0.1, 0.1, 0.12), Color(0.85, 0.85, 0.88), Color(0.2, 0.45, 0.3)]
	var body_mat := _get_mat("car_%d" % index, car_colors[index % car_colors.size()], 0.4, 0.5)
	var glass := _get_mat("car_glass", Color(0.2, 0.25, 0.3), 0.1, 0.3, Color(0.05, 0.07, 0.1))
	var tire := _get_mat("tire", Color(0.06, 0.06, 0.07))
	# Group node so a future "hotwire & launch" system can find and drive it.
	var car := Node3D.new()
	car.name = "Car_%d" % index
	parent.add_child(car)
	car.position = pos
	car.add_to_group("vehicles")
	car.add_to_group("hotwireable")
	car.set_meta("hotwireable", true)
	# Lower body (chassis) — roof ~1.5 m so it is a vaultable / climbable surface.
	_solid(car, Vector3(2.1, 0.8, 4.6), Vector3(0, 0.7, 0), body_mat, Vector3.ZERO, "Chassis")
	# Cabin greenhouse.
	_solid(car, Vector3(1.9, 0.7, 2.4), Vector3(0, 1.45, -0.1), glass, Vector3.ZERO, "Cabin")
	# Four wheels (visual cylinders laid on their side).
	for wx in [-1.0, 1.0]:
		for wz in [-1.5, 1.5]:
			_cylinder(car, 0.45, 0.35, Vector3(wx, 0.45, wz), tire, false, "Wheel")

func _build_bush(parent: Node3D, pos: Vector3) -> void:
	var green := _get_mat("bush", Color(0.22, 0.4, 0.2))
	# Low collidable box (cover, ~0.9 m → vaultable) with a rounded top decoration.
	_solid(parent, Vector3(1.4, 0.9, 1.4), pos + Vector3(0, 0.45, 0), green, Vector3.ZERO, "Bush")
	_sphere(parent, 0.9, pos + Vector3(0, 1.0, 0), green, false, "BushTop")

func _build_tree(parent: Node3D, pos: Vector3, scale_f: float = 1.0) -> void:
	var bark := _get_mat("bark", Color(0.35, 0.25, 0.16))
	var leaf := _get_mat("leaf", Color(0.2, 0.42, 0.2))
	var trunk_h := 4.0 * scale_f
	_cylinder(parent, 0.35 * scale_f, trunk_h, pos + Vector3(0, trunk_h * 0.5, 0), bark, true, "Trunk")
	# Canopy (visual only so players can drop through onto branches/roofs).
	_sphere(parent, 2.2 * scale_f, pos + Vector3(0, trunk_h + 1.2 * scale_f, 0), leaf, false, "Canopy")
	_sphere(parent, 1.6 * scale_f, pos + Vector3(1.0 * scale_f, trunk_h + 0.4 * scale_f, 0.6 * scale_f), leaf, false, "Canopy2")

func _build_mailbox(parent: Node3D, pos: Vector3) -> void:
	var m := _get_mat("mailbox", Color(0.3, 0.3, 0.34), 0.6, 0.4)
	_solid(parent, Vector3(0.12, 1.1, 0.12), pos + Vector3(0, 0.55, 0), _get_mat("bark", Color(0.35, 0.25, 0.16)), Vector3.ZERO, "MailPost")
	_solid(parent, Vector3(0.3, 0.35, 0.6), pos + Vector3(0, 1.2, 0), m, Vector3.ZERO, "MailBox")

func _build_ornament(parent: Node3D, pos: Vector3, index: int) -> void:
	# Alternate between a garden gnome, a flamingo, and a birdbath.
	match index % 3:
		0:
			# Gnome: blue body sphere + tan head + red cap (thin cylinder).
			_sphere(parent, 0.25, pos + Vector3(0, 0.3, 0), _get_mat("gnome_body", Color(0.3, 0.5, 0.7)), false, "GnomeBody")
			_sphere(parent, 0.14, pos + Vector3(0, 0.6, 0), _get_mat("gnome_head", Color(0.9, 0.75, 0.6)), false, "GnomeHead")
			_cylinder(parent, 0.16, 0.3, pos + Vector3(0, 0.82, 0), _get_mat("gnome_cap", Color(0.8, 0.15, 0.15)), false, "GnomeCap")
		1:
			# Flamingo: thin leg + pink body.
			_cylinder(parent, 0.04, 1.0, pos + Vector3(0, 0.5, 0), _get_mat("flam_leg", Color(0.9, 0.6, 0.3)), false, "FlamLeg")
			_sphere(parent, 0.22, pos + Vector3(0, 1.1, 0), _get_mat("flamingo", Color(0.95, 0.5, 0.6)), false, "FlamBody")
		2:
			# Birdbath: stone stem + bowl.
			var stone := _get_mat("stone", Color(0.6, 0.6, 0.62))
			_cylinder(parent, 0.2, 1.0, pos + Vector3(0, 0.5, 0), stone, true, "BirdbathStem")
			_cylinder(parent, 0.6, 0.2, pos + Vector3(0, 1.1, 0), stone, true, "BirdbathBowl")

func _build_rock_cluster(parent: Node3D, pos: Vector3) -> void:
	var stone := _get_mat("rock", Color(0.5, 0.5, 0.52))
	# A few boxy boulders of varied height — cover to hide behind, some to climb/vault.
	_solid(parent, Vector3(1.6, 1.4, 1.4), pos + Vector3(0, 0.7, 0), stone, Vector3(0, _rng.randf_range(0, PI), 0), "Rock")
	_solid(parent, Vector3(1.1, 0.8, 1.0), pos + Vector3(1.2, 0.4, 0.4), stone, Vector3(0, _rng.randf_range(0, PI), 0), "Rock")
	_solid(parent, Vector3(0.9, 1.0, 0.9), pos + Vector3(-0.9, 0.5, -0.6), stone, Vector3(0, _rng.randf_range(0, PI), 0), "Rock")

func _place_ladder(parent: Node3D, base_pos: Vector3, height: float, yaw: float) -> void:
	# Uses the project's LadderObject so the climb is functional (Area3D on layer 8).
	var lad := LadderObject.new()
	lad.ladder_height = maxf(height, 2.0)
	parent.add_child(lad)
	lad.position = base_pos
	lad.rotation = Vector3(0, yaw, 0)

func _build_perimeter() -> void:
	# Tall hedge boundary so players cannot wander off the blockout, with the
	# entry street left open. Built as four hedge walls just inside the ground edge.
	var hedge := _get_mat("hedge", Color(0.18, 0.34, 0.18))
	var e := ground_size * 0.5 - 1.0
	var h := 3.2
	# Back and sides (full), front split to leave the street open.
	_solid(self, Vector3(ground_size, h, 1.0), Vector3(0, h * 0.5, -e), hedge, Vector3.ZERO, "HedgeBack")
	_solid(self, Vector3(1.0, h, ground_size), Vector3(-e, h * 0.5, 0), hedge, Vector3.ZERO, "HedgeLeft")
	_solid(self, Vector3(1.0, h, ground_size), Vector3(e, h * 0.5, 0), hedge, Vector3.ZERO, "HedgeRight")
	var side := (ground_size - road_half_width * 2.0) * 0.5
	_solid(self, Vector3(side, h, 1.0), Vector3(-(road_half_width + side * 0.5), h * 0.5, e), hedge, Vector3.ZERO, "HedgeFrontL")
	_solid(self, Vector3(side, h, 1.0), Vector3(road_half_width + side * 0.5, h * 0.5, e), hedge, Vector3.ZERO, "HedgeFrontR")

func _scatter_common_props() -> void:
	# A handful of shared street trees + rocks between the houses for cover / sightline breaks.
	for i in range(6):
		var a := TAU * float(i) / 6.0 + 0.4
		var r := bulb_radius + 2.4
		_build_tree(self, Vector3(cos(a) * r, 0, sin(a) * r), _rng.randf_range(0.9, 1.2))
