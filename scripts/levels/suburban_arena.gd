extends Node3D
# ============================================================
# ROOFERS vs LANDSCAPERS — Procedural Suburban Arena Generator
# ============================================================
# Objective-shaped cul-de-sac test arena, built in code so the layout
# is parametric. Attach under a level running test_level.gd (training UI
# + Player rig). Everything is generated as children of THIS node at _ready().
#
# LAYOUT (H-pattern, facing the southern approach):
#         [ MAIN ]              main = 3-story capture house / base (north-center, taller)
#   [L1]           [R1]         2-story flanks, bridged to the main roof
#   [L2]           [R2]         2-story, fill the court
#   Pre-built plank BRIDGES connect the main's higher roof down to L1 & R1 roofs.
#
# GODOT 4 RULES (see AGENT_HANDOFF.md): static geometry on collision layer 1;
# never scale a RigidBody; LadderObject via absolute preload (class-cache safe).
#
# HEIGHT LADDER (matches the tuned controller): single jump = low cover only;
# double vaults 3m fences; triple reaches 4m garage awnings; triple-from-awning
# reaches the 8m roofs. The 3-story main tops out ~12m (bridge-only from flanks).
# ============================================================

const WORLD_LAYER := 1
var LADDER_SCRIPT = load("res://scripts/traversal/ladder_object.gd")
var TREE_SCRIPT = load("res://scripts/environment/tree.gd")
var SLIP_TRAP_SCRIPT = load("res://scripts/environment/slip_trap.gd")
var PAINT_TRAP_SCRIPT = load("res://scripts/environment/paint_can_trap.gd")
var CAR_SCRIPT = load("res://scripts/vehicles/hotwire_car.gd")

@export var rng_seed: int = 20260825
@export var ground_size: float = 200.0
@export var drive_length: float = 6.0
@export var bulb_radius: float = 15.0
@export var road_half_width: float = 4.0
@export var island_radius: float = 5.0
@export var sidewalk_width: float = 2.0

@export var story_height: float = 4.0
@export var wall_thick: float = 0.3
@export var roof_pitch_deg: float = 30.0
@export var roof_overhang: float = 0.4   # small eave so it doesn't trap players climbing the roof ladder
@export var fence_height: float = 3.0
@export var add_garages: bool = true
@export var build_bridges: bool = true

var _rng := RandomNumberGenerator.new()
var _mats := {}
var _house_meta := []

func _get_mat(key: String, color: Color, rough: float = 0.95, metal: float = 0.0, emis: Color = Color(0, 0, 0)) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	
	# Apply AI textures based on material key
	if key.begins_with("wall") or key.begins_with("brick"):
		m.albedo_texture = load("res://assets/textures/environment/brick_wall.jpg")
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.15, 0.15, 0.15) # Make the bricks chunkier and larger
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	elif key.begins_with("roof"):
		m.albedo_texture = load("res://assets/textures/environment/roof_shingles.jpg")
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.2, 0.2, 0.2) # Make the shingles larger
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	elif "grass" in key:
		m.albedo_texture = load("res://assets/textures/environment/grass.jpg")
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.1, 0.1, 0.1) # Extra chunky grass
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	elif "wood" in key or "bridge" in key or "fence" in key or "bench" in key or "bark" in key:
		m.albedo_texture = load("res://assets/textures/environment/wood.jpg")
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.15, 0.15, 0.15)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	elif "road" in key or "drive" in key:
		m.albedo_texture = load("res://assets/textures/environment/asphalt.jpg")
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.1, 0.1, 0.1)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	elif "sidewalk" in key or "conc" in key or "stone" in key or "rock" in key:
		m.albedo_texture = load("res://assets/textures/environment/concrete.jpg")
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.15, 0.15, 0.15)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		
	m.albedo_color = color # This will tint the texture, giving us different colored houses!
	m.roughness = rough
	m.metallic = metal
	if emis.r + emis.g + emis.b > 0.0:
		m.emission_enabled = true
		m.emission = emis
		m.emission_energy_multiplier = 0.8
	_mats[key] = m
	return m

# ============================================================
# LOW-LEVEL BUILDERS (validated)
# ============================================================

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

func _wall(parent: Node3D, start: Vector3, end: Vector3, height: float, thick: float, mat: StandardMaterial3D, openings: Array = []) -> void:
	var full := start.distance_to(end)
	if full <= 0.001:
		return
	var dir := (end - start) / full
	var yaw := atan2(-dir.z, dir.x)
	var rot := Vector3(0, yaw, 0)
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
		var spans := []
		for o in openings:
			if u_mid > o.u0 - 0.001 and u_mid < o.u1 + 0.001:
				spans.append([maxf(o.v0, 0.0), minf(o.v1, height)])
		spans.sort_custom(func(a, b): return a[0] < b[0])
		var y := 0.0
		for sp in spans:
			if float(sp[0]) > y + 0.01:
				var h: float = float(sp[0]) - y
				_solid(parent, Vector3(seg_len, h, thick), Vector3(base_center.x, start.y + y + h * 0.5, base_center.z), mat, rot, "WallSeg")
			y = maxf(y, float(sp[1]))
		if y < height - 0.01:
			var h: float = height - y
			_solid(parent, Vector3(seg_len, h, thick), Vector3(base_center.x, start.y + y + h * 0.5, base_center.z), mat, rot, "WallSeg")

func _slab_with_hole(parent: Node3D, center: Vector3, sx: float, sz: float, thick: float, mat: StandardMaterial3D, hx0: float = 0.0, hx1: float = 0.0, hz0: float = 0.0, hz1: float = 0.0, nm: String = "Slab") -> void:
	var has_hole := (hx1 - hx0) > 0.05 and (hz1 - hz0) > 0.05
	if not has_hole:
		_solid(parent, Vector3(sx, thick, sz), center, mat, Vector3.ZERO, nm)
		return
	var x_min := -sx * 0.5
	var x_max := sx * 0.5
	var z_min := -sz * 0.5
	var z_max := sz * 0.5
	if hx0 - x_min > 0.05:
		var w := hx0 - x_min
		_solid(parent, Vector3(w, thick, sz), center + Vector3(x_min + w * 0.5, 0, 0), mat, Vector3.ZERO, nm)
	if x_max - hx1 > 0.05:
		var w := x_max - hx1
		_solid(parent, Vector3(w, thick, sz), center + Vector3(hx1 + w * 0.5, 0, 0), mat, Vector3.ZERO, nm)
	if hz0 - z_min > 0.05:
		var d := hz0 - z_min
		_solid(parent, Vector3(hx1 - hx0, thick, d), center + Vector3((hx0 + hx1) * 0.5, 0, z_min + d * 0.5), mat, Vector3.ZERO, nm)
	if z_max - hz1 > 0.05:
		var d := z_max - hz1
		_solid(parent, Vector3(hx1 - hx0, thick, d), center + Vector3((hx0 + hx1) * 0.5, 0, hz1 + d * 0.5), mat, Vector3.ZERO, nm)

func _ramp(parent: Node3D, width: float, run: float, y0: float, y1: float, center_xz: Vector3, mat: StandardMaterial3D, face_pos_z: bool = true) -> void:
	var rise := y1 - y0
	var length := sqrt(run * run + rise * rise)
	var angle := atan2(rise, run)
	var rot_x := -angle if face_pos_z else angle
	var mid := Vector3(center_xz.x, (y0 + y1) * 0.5, center_xz.z)
	_solid(parent, Vector3(width, 0.3, length), mid, mat, Vector3(rot_x, 0, 0), "Ramp")

# ============================================================
# TOP-LEVEL
# ============================================================

func _ready() -> void:
	_rng.seed = rng_seed
	_house_meta = []
	_build_ground()
	_build_streets_and_island()
	_build_houses()
	if build_bridges:
		_build_bridges()
	_build_perimeter()
	_scatter_common_props()
	_scatter_grass_tufts()
	_scatter_street_trees()
	print("[SuburbanArena] Built %d houses; bridges=%s." % [_house_meta.size(), str(build_bridges)])

func _scatter_grass_tufts() -> void:
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 8000
	
	var quad := QuadMesh.new()
	quad.size = Vector2(0.7, 0.7)
	
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/textures/environment/grass_tuft.png")
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	quad.material = mat
	mm.mesh = quad
	
	for i in range(mm.instance_count):
		var px := _rng.randf_range(-ground_size * 0.48, ground_size * 0.48)
		var pz := _rng.randf_range(-ground_size * 0.48, ground_size * 0.48)
		
		var dist_to_center = Vector2(px, pz).length()
		if dist_to_center < bulb_radius + 1.0 or (abs(px) < road_half_width + 1.0 and pz > bulb_radius):
			if _rng.randf() < 0.9:
				px = _rng.randf_range(-ground_size * 0.48, ground_size * 0.48)
				pz = _rng.randf_range(-ground_size * 0.48, ground_size * 0.48)
				
		var t := Transform3D()
		t = t.rotated_local(Vector3.UP, _rng.randf_range(0, TAU))
		var s := _rng.randf_range(0.7, 1.4)
		t = t.scaled_local(Vector3(s, s, s))
		t.origin = Vector3(px, quad.size.y * 0.5 * s, pz)
		mm.set_instance_transform(i, t)
		
	mmi.multimesh = mm
	add_child(mmi)

# Dense-ish forest along the grass strips flanking the entry street — cover AND
# a harvestable resource (chop for supplies to build catapults/ramps/siege).
func _scatter_street_trees() -> void:
	var half := ground_size * 0.5
	var planted := 0
	for side in [-1.0, 1.0]:
		var x := 9.0
		while x < 42.0 and planted < 120:
			var z := bulb_radius + 3.0
			while z < half - 8.0 and planted < 120:
				var px: float = side * (x + _rng.randf_range(-2.0, 2.0))
				var pz: float = z + _rng.randf_range(-2.0, 2.0)
				_build_tree(self, Vector3(px, 0, pz), _rng.randf_range(0.8, 1.3))
				planted += 1
				z += _rng.randf_range(6.5, 9.5)
			x += _rng.randf_range(7.0, 10.0)

func _build_ground() -> void:
	var grass := _get_mat("grass", Color(0.36, 0.52, 0.24))
	_solid(self, Vector3(ground_size, 1.0, ground_size), Vector3(0, -0.5, 0), grass, Vector3.ZERO, "Ground")

func _build_streets_and_island() -> void:
	var road := _get_mat("road", Color(0.2, 0.2, 0.22), 1.0)
	var walk := _get_mat("sidewalk", Color(0.62, 0.62, 0.6), 1.0)
	_cylinder(self, bulb_radius + sidewalk_width, 0.05, Vector3(0, 0.025, 0), walk, false, "BulbWalk")
	_cylinder(self, bulb_radius, 0.09, Vector3(0, 0.045, 0), road, false, "Bulb")
	var street_len := ground_size * 0.5 - bulb_radius
	var sz_center := bulb_radius + street_len * 0.5
	_decor_box(self, Vector3(road_half_width * 2.0, 0.08, street_len), Vector3(0, 0.04, sz_center), road)
	for sx in [-1.0, 1.0]:
		_decor_box(self, Vector3(sidewalk_width, 0.05, street_len), Vector3(sx * (road_half_width + sidewalk_width * 0.5), 0.025, sz_center), walk)
	# Central island.
	_cylinder(self, island_radius, 0.25, Vector3(0, 0.12, 0), _get_mat("grass", Color(0.36, 0.52, 0.24)), true, "Island")
	_build_tree(self, Vector3(0, 0.25, 0), 1.3)
	_bench(self, Vector3(island_radius - 1.0, 0.25, 0), deg_to_rad(90.0))
	_bench(self, Vector3(-(island_radius - 1.0), 0.25, 0), deg_to_rad(-90.0))
	# Lamps ring the bulb on the house side only (skip the southern street mouth so
	# none land in the road). +Z (south) is angle 90 deg in this cos/sin convention.
	var rL := bulb_radius + sidewalk_width - 0.4
	for deg in [130.0, 165.0, 200.0, 235.0, 270.0, 305.0, 340.0]:
		var a := deg_to_rad(deg)
		_street_lamp(self, Vector3(cos(a) * rL, 0, sin(a) * rL))
	# A couple of lamps along the street sidewalks (on the walk, never the road).
	var lx := road_half_width + sidewalk_width - 0.3
	_street_lamp(self, Vector3(lx, 0, bulb_radius + 10.0))
	_street_lamp(self, Vector3(-lx, 0, bulb_radius + 22.0))
	_entrance_markers(self, bulb_radius + street_len - 4.0)

func _street_lamp(parent: Node3D, pos: Vector3) -> void:
	var pole := _get_mat("lamp_pole", Color(0.18, 0.18, 0.2), 0.5, 0.6)
	var glow := _get_mat("lamp_glow", Color(1.0, 0.9, 0.6), 0.4, 0.0, Color(0.9, 0.8, 0.4))
	_cylinder(parent, 0.12, 5.0, pos + Vector3(0, 2.5, 0), pole, true, "LampPole")
	_decor_box(parent, Vector3(0.5, 0.4, 0.5), pos + Vector3(0, 5.0, 0), glow)

func _entrance_markers(parent: Node3D, z: float) -> void:
	var brick := _get_mat("brick", Color(0.55, 0.28, 0.22))
	var sign_mat := _get_mat("sign", Color(0.15, 0.25, 0.15), 0.6, 0.0, Color(0.03, 0.06, 0.03))
	for sx in [-1.0, 1.0]:
		var x: float = sx * (road_half_width + sidewalk_width + 0.6)
		_solid(parent, Vector3(1.2, 2.6, 1.2), Vector3(x, 1.3, z), brick, Vector3.ZERO, "EntryPillar")
	_decor_box(parent, Vector3(3.4, 1.0, 0.2), Vector3(0, 2.2, z), sign_mat)

# ============================================================
# HOUSES (explicit H-pattern layout)
# ============================================================

func _build_houses() -> void:
	# Houses RING the cul-de-sac bulb (centered at the origin) and each is rotated
	# to face inward, like a real cul-de-sac. Main sits deepest at the head (north);
	# flanks and fill houses fan around toward the open street mouth (south).
	# Positions verified (OBB overlap check) to leave >=3m alleys between every plot.
	# Ring spacing: 40deg apart over a 160deg arc; main deepest (head), fills near the mouth.
	var center := Vector3.ZERO
	var specs := [
		{"pos": Vector3(0, 0, -52), "W": 20.0, "D": 16.0, "stories": 3, "garage": 0, "main": true},        # head of the cul-de-sac
		{"pos": Vector3(-29.6, 0, -35.2), "W": 16.0, "D": 13.0, "stories": 2, "garage": -1, "main": false}, # NW flank
		{"pos": Vector3(29.6, 0, -35.2), "W": 16.0, "D": 13.0, "stories": 2, "garage": 1, "main": false},   # NE flank
		{"pos": Vector3(-45.3, 0, -8.0), "W": 16.0, "D": 13.0, "stories": 2, "garage": -1, "main": false},  # W fill (near mouth)
		{"pos": Vector3(45.3, 0, -8.0), "W": 16.0, "D": 13.0, "stories": 2, "garage": 1, "main": false},    # E fill (near mouth)
	]
	for i in range(specs.size()):
		var sp = specs[i]
		var pos: Vector3 = sp["pos"]
		var dir := center - pos
		var yaw := atan2(-dir.x, -dir.z)   # front (local -Z / porch / driveway) faces the bulb center
		var house := Node3D.new()
		house.name = "MainHouse" if sp["main"] else "House_%d" % i
		if sp["main"]:
			house.add_to_group("capture_point")
		add_child(house)
		house.position = pos
		house.rotation = Vector3(0, yaw, 0)
		_build_single_house(house, i, sp)
		_house_meta.append({"node": house, "pos": pos, "W": float(sp["W"]), "D": float(sp["D"]), "wall_top": story_height * float(sp["stories"]), "main": sp["main"]})

func _build_single_house(house: Node3D, index: int, sp) -> void:
	var W: float = sp["W"]
	var D: float = sp["D"]
	var n: int = sp["stories"]
	var garage_side: int = sp["garage"]
	var is_main: bool = sp["main"]
	var wall_top: float = story_height * float(n)
	var xh := W * 0.5
	var zh := D * 0.5

	var wall_colors := [Color(0.86, 0.83, 0.75), Color(0.80, 0.78, 0.72), Color(0.90, 0.86, 0.78), Color(0.72, 0.74, 0.72), Color(0.84, 0.80, 0.70)]
	var roof_colors := [Color(0.30, 0.22, 0.20), Color(0.24, 0.26, 0.30), Color(0.36, 0.24, 0.20), Color(0.28, 0.30, 0.28), Color(0.22, 0.20, 0.22)]
	var wall_mat := _get_mat("wall_%d" % index, Color(0.62, 0.5, 0.42) if is_main else wall_colors[index % wall_colors.size()])
	var roof_mat := _get_mat("roof_%d" % index, Color(0.2, 0.18, 0.22) if is_main else roof_colors[index % roof_colors.size()])
	var floor_mat := _get_mat("floor_wood", Color(0.45, 0.33, 0.22))
	var glass := _get_mat("glass", Color(0.4, 0.55, 0.7), 0.15, 0.0, Color(0.10, 0.16, 0.22))

	# Floors (ground + partial upper balconies with ramps + attic w/ hatch).
	_build_floors(house, W, D, n, floor_mat, wall_mat)

	# Exterior walls, full height, with a ground door + windows per floor.
	var front_openings := [{"u0": W * 0.5 - 1.4, "u1": W * 0.5 + 1.4, "v0": 0.0, "v1": 3.0}]
	for f in range(n):
		var vy := float(f) * story_height
		front_openings.append({"u0": 1.5, "u1": 4.0, "v0": vy + 1.0, "v1": vy + 2.6})
		front_openings.append({"u0": W - 4.0, "u1": W - 1.5, "v0": vy + 1.0, "v1": vy + 2.6})
	_wall(house, Vector3(-xh, 0, -zh), Vector3(xh, 0, -zh), wall_top, wall_thick, wall_mat, front_openings)

	var back_openings := [{"u0": 2.0, "u1": 5.0, "v0": 0.0, "v1": 3.0}]
	for f in range(n):
		back_openings.append({"u0": W - 5.0, "u1": W - 2.0, "v0": float(f) * story_height + 1.0, "v1": float(f) * story_height + 2.6})
	_wall(house, Vector3(-xh, 0, zh), Vector3(xh, 0, zh), wall_top, wall_thick, wall_mat, back_openings)

	var side_openings := []
	for f in range(n):
		side_openings.append({"u0": 2.5, "u1": 4.5, "v0": float(f) * story_height + 1.0, "v1": float(f) * story_height + 2.6})
		side_openings.append({"u0": D - 4.5, "u1": D - 2.5, "v0": float(f) * story_height + 1.0, "v1": float(f) * story_height + 2.6})
	_wall(house, Vector3(-xh, 0, -zh), Vector3(-xh, 0, zh), wall_top, wall_thick, wall_mat, side_openings)
	_wall(house, Vector3(xh, 0, -zh), Vector3(xh, 0, zh), wall_top, wall_thick, wall_mat, side_openings)

	# Interior cover on the ground floor.
	_solid(house, Vector3(3.0, 0.9, 1.2), Vector3(-xh + 4.0, 0.45, zh - 3.0), _get_mat("couch", Color(0.3, 0.35, 0.42)), Vector3.ZERO, "Couch")
	_solid(house, Vector3(1.6, 0.8, 1.0), Vector3(xh - 4.0, 0.4, -zh + 4.0), _get_mat("counter", Color(0.5, 0.45, 0.4)), Vector3.ZERO, "Counter")

	# Roof (closed, gabled, skylight) + chimney.
	_build_roof(house, W, D, wall_top, roof_mat, wall_mat, index)

	# Garage (mid-level 4m roof) on the requested side.
	if add_garages and garage_side != 0:
		_build_garage(house, float(garage_side), xh, zh, wall_mat, roof_mat)

	# Roof-access ladder on the side opposite the garage (or -X for the main).
	# Placed just past the (now-small) eave and run tall enough to top out ABOVE the
	# eave so the player can step straight onto the roof instead of being trapped under it.
	var ladder_side: float = -float(garage_side) if garage_side != 0 else -1.0
	_place_ladder(house, Vector3(ladder_side * (xh + 0.55), 0, zh - 2.0), wall_top + 0.8, deg_to_rad(90.0) * ladder_side)
	_ac_unit(house, Vector3(ladder_side * (xh + 0.9), 0, -zh + 3.0))

	_build_porch(house, W, D, wall_mat, roof_mat)
	_build_yard(house, index, W, D, float(garage_side if garage_side != 0 else 1))
	_scatter_traps(house, W, D, n)

func _scatter_traps(house: Node3D, W: float, D: float, stories: int) -> void:
	
	# 1-3 Slip Traps per floor
	for i in range(stories):
		var floor_y = i * story_height
		var traps = randi_range(1, 3)
		for t in range(traps):
			var rx = randf_range(-W*0.4, W*0.4)
			var rz = randf_range(-D*0.4, D*0.4)
			var trap = SLIP_TRAP_SCRIPT.new()
			house.add_child(trap)
			trap.position = Vector3(rx, floor_y + 0.1, rz)
			
			var mi = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(0.4, 0.1, 0.4)
			mi.mesh = bm
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.2, 0.2, 0.8) # Blue marbles
			mi.material_override = mat
			trap.add_child(mi)
			
			var cs = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = Vector3(0.5, 0.2, 0.5)
			cs.shape = shape
			trap.add_child(cs)
			
	# Paint Cans near the ceiling above doors/ramps
	for i in range(stories):
		var floor_y = i * story_height
		if randf() > 0.5: # 50% chance per floor
			var rx = randf_range(-W*0.2, W*0.2)
			var rz = randf_range(-D*0.2, D*0.2)
			var trap = PAINT_TRAP_SCRIPT.new()
			house.add_child(trap)
			trap.position = Vector3(rx, floor_y + story_height - 0.5, rz)

func _build_floors(house: Node3D, W: float, D: float, n: int, floor_mat: StandardMaterial3D, wall_mat: StandardMaterial3D) -> void:
	var xh := W * 0.5
	var zh := D * 0.5
	# Ground floor.
	_solid(house, Vector3(W, 0.2, D), Vector3(0, -0.05, 0), floor_mat, Vector3.ZERO, "GroundFloor")
	# Partial upper balconies (back ~62%) with a railing + a ramp up, alternating sides.
	var cover_d := D * 0.62
	var slab_cz := zh - cover_d * 0.5
	var front_edge_z := zh - cover_d
	for f in range(1, n):
		var y := float(f) * story_height
		_solid(house, Vector3(W, 0.2, cover_d), Vector3(0, y, slab_cz), floor_mat, Vector3.ZERO, "Floor%d" % f)
		_wall(house, Vector3(-xh + 0.4, y + 0.1, front_edge_z), Vector3(xh - 0.4, y + 0.1, front_edge_z), 1.0, 0.15, wall_mat, [])
		var sidex := (-xh + 2.8) if (f % 2 == 1) else (xh - 2.8)
		_ramp(house, 3.0, 5.6, float(f - 1) * story_height, y, Vector3(sidex, 0, slab_cz + 0.4), floor_mat, true)
	# Attic floor with a hatch, and a ladder from the top balcony to it.
	_slab_with_hole(house, Vector3(0, float(n) * story_height, 0), W, D, 0.2, floor_mat, xh - 3.2, xh - 1.0, zh - 3.2, zh - 1.0, "AtticFloor")
	_place_ladder(house, Vector3(xh - 2.1, float(n - 1) * story_height, zh - 2.1), story_height, deg_to_rad(180.0))

func _build_roof(house: Node3D, W: float, D: float, wall_top: float, roof_mat: StandardMaterial3D, wall_mat: StandardMaterial3D, index: int) -> void:
	var pitch := deg_to_rad(roof_pitch_deg)
	var half := W * 0.5
	var eave_over := roof_overhang
	var ridge_y := wall_top + tan(pitch) * half
	var dz := D + eave_over * 2.0
	var apex := Vector3(0, ridge_y, 0)
	var eave_r := Vector3(half + eave_over, wall_top - tan(pitch) * eave_over, 0)
	var eave_l := Vector3(-(half + eave_over), wall_top - tan(pitch) * eave_over, 0)
	var slope_len := apex.distance_to(eave_r)
	var mid_r := (apex + eave_r) * 0.5
	var mid_l := (apex + eave_l) * 0.5
	_roof_slab(house, Vector3(mid_r.x, mid_r.y, 0), slope_len, dz, -pitch, roof_mat, false, "RoofR")
	_roof_slab(house, Vector3(mid_l.x, mid_l.y, 0), slope_len, dz, pitch, roof_mat, true, "RoofL")
	_solid(house, Vector3(0.5, 0.3, dz), Vector3(0, ridge_y + 0.02, 0), roof_mat, Vector3.ZERO, "RidgeCap")
	_gable(house, D * 0.5, W, wall_top, ridge_y, wall_thick, wall_mat)
	_gable(house, -D * 0.5, W, wall_top, ridge_y, wall_thick, wall_mat)
	_build_chimney(house, Vector3(0, wall_top, D * 0.28))

func _roof_slab(house: Node3D, center: Vector3, slope_len: float, z_len: float, rot_z: float, mat: StandardMaterial3D, hole: bool, nm: String) -> void:
	var holder := Node3D.new()
	holder.name = nm + "Holder"
	house.add_child(holder)
	holder.position = center
	holder.rotation = Vector3(0, 0, rot_z)
	if hole:
		_slab_with_hole(holder, Vector3.ZERO, slope_len, z_len, 0.2, mat, -1.1, 1.1, -1.6, 1.6, nm)
	else:
		_solid(holder, Vector3(slope_len, 0.2, z_len), Vector3.ZERO, mat, Vector3.ZERO, nm)

func _gable(house: Node3D, z: float, W: float, wall_top: float, ridge_y: float, thick: float, mat: StandardMaterial3D) -> void:
	var steps := 12
	for i in range(steps):
		var f0 := float(i) / float(steps)
		var f1 := float(i + 1) / float(steps)
		var y0 := lerpf(wall_top, ridge_y, f0)
		var y1 := lerpf(wall_top, ridge_y, f1)
		var wdt := W * (1.0 - f1)
		if wdt < 0.2:
			continue
		_solid(house, Vector3(wdt, (y1 - y0) + 0.05, thick), Vector3(0, (y0 + y1) * 0.5, z), mat, Vector3.ZERO, "Gable")

func _build_chimney(house: Node3D, base: Vector3) -> void:
	var brick := _get_mat("brick", Color(0.55, 0.28, 0.22))
	var h := 2.6
	var s := 1.8
	var t := 0.25
	var off := s * 0.5 - t * 0.5
	_solid(house, Vector3(s, h, t), base + Vector3(0, h * 0.5, -off), brick, Vector3.ZERO, "ChimN")
	_solid(house, Vector3(s, h, t), base + Vector3(0, h * 0.5, off), brick, Vector3.ZERO, "ChimS")
	_solid(house, Vector3(t, h, s - t * 2.0), base + Vector3(-off, h * 0.5, 0), brick, Vector3.ZERO, "ChimW")
	_solid(house, Vector3(t, h, s - t * 2.0), base + Vector3(off, h * 0.5, 0), brick, Vector3.ZERO, "ChimE")

func _build_garage(house: Node3D, side: float, xh: float, zh: float, wall_mat: StandardMaterial3D, roof_mat: StandardMaterial3D) -> void:
	var gw := 6.0
	var gd := 6.5
	var gh := 4.0
	var gx := side * (xh + gw * 0.5)
	var gz := -zh + gd * 0.5
	var gwt := 0.3
	_solid(house, Vector3(gw, 0.2, gd), Vector3(gx, -0.05, gz), _get_mat("floor_conc", Color(0.5, 0.5, 0.52)), Vector3.ZERO, "GarageFloor")
	_wall(house, Vector3(gx - gw * 0.5, 0, -zh), Vector3(gx + gw * 0.5, 0, -zh), gh, gwt, wall_mat, [{"u0": 1.0, "u1": gw - 1.0, "v0": 0.0, "v1": 3.0}])
	_wall(house, Vector3(gx + side * gw * 0.5, 0, -zh), Vector3(gx + side * gw * 0.5, 0, gz + gd * 0.5), gh, gwt, wall_mat, [])
	_wall(house, Vector3(gx - gw * 0.5, 0, gz + gd * 0.5), Vector3(gx + gw * 0.5, 0, gz + gd * 0.5), gh, gwt, wall_mat, [])
	_solid(house, Vector3(gw + 0.4, 0.2, gd + 0.4), Vector3(gx, gh, gz), roof_mat, Vector3.ZERO, "GarageRoof")
	for edge in [Vector3(gw * 0.5, 0, 0), Vector3(-gw * 0.5, 0, 0), Vector3(0, 0, gd * 0.5), Vector3(0, 0, -gd * 0.5)]:
		var is_x := absf(edge.x) > 0.01
		var psize := Vector3(0.2, 0.6, gd + 0.4) if is_x else Vector3(gw + 0.4, 0.6, 0.2)
		_solid(house, psize, Vector3(gx + edge.x, gh + 0.4, gz + edge.z), roof_mat, Vector3.ZERO, "GarageParapet")
	_place_ladder(house, Vector3(gx - side * (gw * 0.5 - 0.4), gh, gz), story_height * 2.0 - gh, deg_to_rad(90.0) * side)

func _build_porch(house: Node3D, W: float, D: float, wall_mat: StandardMaterial3D, roof_mat: StandardMaterial3D) -> void:
	var zh := D * 0.5
	var wood := _get_mat("porch_wood", Color(0.55, 0.42, 0.3))
	var porch_z := -zh - 1.6
	_solid(house, Vector3(7.0, 0.2, 3.2), Vector3(0, 0.1, porch_z), wood, Vector3.ZERO, "PorchDeck")
	_solid(house, Vector3(7.0, 0.15, 0.5), Vector3(0, 0.075, porch_z - 1.7), wood, Vector3.ZERO, "Step1")
	for sx in [-3.0, 3.0]:
		_solid(house, Vector3(0.25, 3.0, 0.25), Vector3(sx, 1.5, porch_z - 1.4), wall_mat, Vector3.ZERO, "PorchPost")
	_solid(house, Vector3(7.6, 0.2, 3.6), Vector3(0, 3.1, porch_z - 0.2), roof_mat, Vector3.ZERO, "PorchRoof")

# ============================================================
# BRIDGES (main roof <-> flanking roofs)
# ============================================================

func _build_bridges() -> void:
	if _house_meta.size() < 3:
		return
	var main = _house_meta[0]
	for idx in [1, 2]:
		var pair := _closest_roof_points(main, _house_meta[idx])
		_build_bridge(pair[0], pair[1], 3.0)

# World-space midpoints of each roof side (works for any house rotation).
func _roof_edge_points(meta) -> Array:
	var n: Node3D = meta["node"]
	var W: float = meta["W"]
	var D: float = meta["D"]
	var wt: float = meta["wall_top"]
	var out := []
	for l in [Vector3(W * 0.5, wt, 0), Vector3(-W * 0.5, wt, 0), Vector3(0, wt, D * 0.5), Vector3(0, wt, -D * 0.5)]:
		out.append(n.to_global(l))
	return out

# The closest facing pair of roof-edge points between two houses (horizontal distance).
func _closest_roof_points(a, b) -> Array:
	var pa := _roof_edge_points(a)
	var pb := _roof_edge_points(b)
	var best_a: Vector3 = pa[0]
	var best_b: Vector3 = pb[0]
	var best_d := 1.0e20
	for p in pa:
		for q in pb:
			var d := Vector2(p.x, p.z).distance_to(Vector2(q.x, q.z))
			if d < best_d:
				best_d = d
				best_a = p
				best_b = q
	return [best_a, best_b]

func _build_bridge(from: Vector3, to: Vector3, width: float) -> void:
	var length := from.distance_to(to)
	if length < 0.5:
		return
	var mid := (from + to) * 0.5
	var wood := _get_mat("bridge", Color(0.5, 0.38, 0.24))
	var body := StaticBody3D.new()
	body.name = "Bridge"
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shp := BoxShape3D.new()
	shp.size = Vector3(width, 0.25, length)
	cs.shape = shp
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, 0.25, length)
	mi.mesh = bm
	mi.material_override = wood
	body.add_child(mi)
	# Side railings (visual).
	for sx in [-1.0, 1.0]:
		var r := MeshInstance3D.new()
		var rbm := BoxMesh.new()
		rbm.size = Vector3(0.12, 0.8, length)
		r.mesh = rbm
		r.material_override = wood
		body.add_child(r)
		r.position = Vector3(sx * (width * 0.5 - 0.06), 0.5, 0)
	add_child(body)
	body.global_position = mid
	body.look_at(to, Vector3.UP)

# ============================================================
# YARDS & PROPS
# ============================================================

func _build_yard(house: Node3D, index: int, W: float, D: float, side: float) -> void:
	var zh := D * 0.5
	var xh := W * 0.5
	var wood := _get_mat("fence", Color(0.72, 0.6, 0.42))
	var drive_mat := _get_mat("drive", Color(0.5, 0.5, 0.52), 1.0)
	var drive_len := drive_length
	var drive_x := side * (xh + 3.0)
	_decor_box(house, Vector3(5.5, 0.1, drive_len), Vector3(drive_x, 0.06, -zh - drive_len * 0.5), drive_mat)
	_build_car(house, Vector3(drive_x, 0.0, -zh - 4.0), index)
	_basketball_hoop(house, Vector3(drive_x + side * 3.2, 0, -zh - 2.5), side)

	var fy := -zh - drive_len - 0.5
	_fence_run(house, Vector3(-xh - 2.0, 0, fy), Vector3(xh + 2.0, 0, fy), wood, [Vector2(drive_x - 3.0, drive_x + 3.0)])
	_fence_run(house, Vector3(-xh - 2.0, 0, fy), Vector3(-xh - 2.0, 0, -zh), wood, [])
	_fence_run(house, Vector3(xh + 2.0, 0, fy), Vector3(xh + 2.0, 0, -zh), wood, [])

	_solid(house, Vector3(5.0, 1.0, 0.9), Vector3(-side * 3.0, 0.5, -zh - 3.4), _get_mat("brick", Color(0.55, 0.28, 0.22)), Vector3.ZERO, "Flowerbed")
	_decor_box(house, Vector3(4.6, 0.4, 0.6), Vector3(-side * 3.0, 1.1, -zh - 3.4), _get_mat("flowers", Color(0.7, 0.3, 0.45), 0.9, 0.0, Color(0.15, 0.03, 0.06)))
	_solid(house, Vector3(0.4, 3.0, 4.0), Vector3(-side * (xh + 1.2), 1.5, 1.0), _get_mat("brick", Color(0.55, 0.28, 0.22)), Vector3.ZERO, "BrickMural")

	_trash_bins(house, Vector3(side * (xh - 1.0), 0, fy + 0.8))
	_fire_hydrant(house, Vector3(-side * (xh + 1.3), 0, fy + 1.0))
	_build_tree(house, Vector3(-side * (xh + 1.0), 0, -zh - 4.0), _rng.randf_range(1.0, 1.3))
	for k in range(3):
		_build_bush(house, Vector3(_rng.randf_range(-xh, xh), 0, _rng.randf_range(-zh - drive_len + 2.0, -zh - 1.0)))
	_build_mailbox(house, Vector3(side * (xh + 1.0), 0, fy + 0.6))
	_build_ornament(house, Vector3(-side * 2.0, 0, -zh - 4.0), index)
	_build_rock_cluster(house, Vector3(-side * (xh + 1.8), 0, -zh - 5.0))

func _fence_run(parent: Node3D, start: Vector3, end: Vector3, mat: StandardMaterial3D, gaps: Array = []) -> void:
	var full := start.distance_to(end)
	if full < 0.2:
		return
	var dir := (end - start) / full
	var yaw := atan2(-dir.z, dir.x)
	var cuts := [0.0, full]
	for g in gaps:
		cuts.append(clampf(_project_u(start, dir, g.x), 0.0, full))
		cuts.append(clampf(_project_u(start, dir, g.y), 0.0, full))
	cuts.sort()
	for i in range(cuts.size() - 1):
		var ua: float = cuts[i]
		var ub: float = cuts[i + 1]
		var seg := ub - ua
		if seg <= 0.05:
			continue
		var u_mid := (ua + ub) * 0.5
		var in_gap := false
		for g in gaps:
			var gu0 = _project_u(start, dir, g.x)
			var gu1 = _project_u(start, dir, g.y)
			if u_mid > minf(gu0, gu1) and u_mid < maxf(gu0, gu1):
				in_gap = true
				break
		if in_gap:
			continue
		var mid := start + dir * u_mid
		_solid(parent, Vector3(seg, fence_height, 0.12), Vector3(mid.x, fence_height * 0.5, mid.z), mat, Vector3(0, yaw, 0), "Fence")

func _project_u(start: Vector3, dir: Vector3, axis_val: float) -> float:
	if absf(dir.x) >= absf(dir.z):
		return (axis_val - start.x) / dir.x if absf(dir.x) > 0.001 else 0.0
	return (axis_val - start.z) / dir.z if absf(dir.z) > 0.001 else 0.0

func _hedgerow(parent: Node3D, start: Vector3, end: Vector3) -> void:
	var green := _get_mat("hedge", Color(0.2, 0.36, 0.2))
	var full := start.distance_to(end)
	if full < 0.2:
		return
	var dir := (end - start) / full
	var yaw := atan2(-dir.z, dir.x)
	var mid := (start + end) * 0.5
	_solid(parent, Vector3(full, 2.5, 0.7), Vector3(mid.x, 1.25, mid.z), green, Vector3(0, yaw, 0), "Hedge")

func _build_car(parent: Node3D, pos: Vector3, index: int) -> void:
	var car_colors := [Color(0.7, 0.15, 0.15), Color(0.15, 0.2, 0.5), Color(0.1, 0.1, 0.12), Color(0.85, 0.85, 0.88), Color(0.2, 0.45, 0.3)]
	var body_mat := _get_mat("car_%d" % index, car_colors[index % car_colors.size()], 0.4, 0.5)
	var glass := _get_mat("car_glass", Color(0.2, 0.25, 0.3), 0.1, 0.3, Color(0.05, 0.07, 0.1))
	var tire := _get_mat("tire", Color(0.06, 0.06, 0.07))
	
	var car = CAR_SCRIPT.new()
	car.name = "Car_%d" % index
	parent.add_child(car)
	car.position = pos
	car.add_to_group("vehicles")
	car.add_to_group("hotwireable")
	
	# Helper to build raw shapes/meshes for the CharacterBody3D
	var build_part = func(size: Vector3, p: Vector3, mat: StandardMaterial3D, is_cyl: bool = false, rot_z: float = 0.0):
		var mi = MeshInstance3D.new()
		var cs = CollisionShape3D.new()
		mi.position = p
		cs.position = p
		
		if is_cyl:
			var cm = CylinderMesh.new()
			cm.top_radius = size.x
			cm.bottom_radius = size.x
			cm.height = size.y
			mi.mesh = cm
			var shp = CylinderShape3D.new()
			shp.radius = size.x
			shp.height = size.y
			cs.shape = shp
			if rot_z != 0:
				mi.rotation_degrees.z = rot_z
				cs.rotation_degrees.z = rot_z
		else:
			var bm = BoxMesh.new()
			bm.size = size
			mi.mesh = bm
			var shp = BoxShape3D.new()
			shp.size = size
			cs.shape = shp
			
		mi.material_override = mat
		car.add_child(mi)
		car.add_child(cs)

	build_part.call(Vector3(2.1, 0.8, 4.6), Vector3(0, 0.7, 0), body_mat, false, 0.0) # Chassis
	build_part.call(Vector3(1.9, 0.7, 2.4), Vector3(0, 1.45, -0.1), glass, false, 0.0) # Cabin
	for wx in [-1.0, 1.0]:
		for wz in [-1.5, 1.5]:
			build_part.call(Vector3(0.45, 0.35, 0.0), Vector3(wx, 0.45, wz), tire, true, 90.0) # Wheel (Cylinder, rot Z 90)

func _ac_unit(parent: Node3D, pos: Vector3) -> void:
	_solid(parent, Vector3(1.0, 1.0, 1.0), pos + Vector3(0, 0.5, 0), _get_mat("ac", Color(0.55, 0.57, 0.58), 0.6, 0.4), Vector3.ZERO, "ACUnit")

func _trash_bins(parent: Node3D, pos: Vector3) -> void:
	_solid(parent, Vector3(0.7, 1.1, 0.7), pos + Vector3(-0.5, 0.55, 0), _get_mat("bin_green", Color(0.2, 0.35, 0.25), 0.7), Vector3.ZERO, "TrashBin")
	_solid(parent, Vector3(0.7, 1.1, 0.7), pos + Vector3(0.5, 0.55, 0), _get_mat("bin_blue", Color(0.2, 0.3, 0.5), 0.7), Vector3.ZERO, "RecycleBin")

func _fire_hydrant(parent: Node3D, pos: Vector3) -> void:
	var red := _get_mat("hydrant", Color(0.75, 0.15, 0.12), 0.5, 0.2)
	_cylinder(parent, 0.18, 0.7, pos + Vector3(0, 0.35, 0), red, true, "HydrantBody")
	_sphere(parent, 0.2, pos + Vector3(0, 0.75, 0), red, false, "HydrantCap")

func _bench(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var wood := _get_mat("bench", Color(0.5, 0.36, 0.24))
	_solid(parent, Vector3(1.8, 0.15, 0.5), pos + Vector3(0, 0.5, 0), wood, Vector3(0, yaw, 0), "BenchSeat")
	_solid(parent, Vector3(1.8, 0.5, 0.12), pos + Vector3(0, 0.75, -0.2).rotated(Vector3.UP, yaw), wood, Vector3(0, yaw, 0), "BenchBack")

func _basketball_hoop(parent: Node3D, pos: Vector3, side: float) -> void:
	var pole := _get_mat("hoop_pole", Color(0.2, 0.2, 0.22), 0.5, 0.5)
	var board := _get_mat("backboard", Color(0.9, 0.9, 0.92), 0.4)
	_cylinder(parent, 0.1, 3.2, pos + Vector3(0, 1.6, 0), pole, true, "HoopPole")
	_decor_box(parent, Vector3(1.6, 1.0, 0.1), pos + Vector3(-side * 0.4, 3.3, 0), board)
	_cylinder(parent, 0.22, 0.05, pos + Vector3(-side * 0.9, 3.0, 0), _get_mat("rim", Color(0.85, 0.4, 0.1), 0.5, 0.4), false, "Rim")

func _build_bush(parent: Node3D, pos: Vector3) -> void:
	var green := _get_mat("bush", Color(0.22, 0.4, 0.2))
	_solid(parent, Vector3(1.4, 0.9, 1.4), pos + Vector3(0, 0.45, 0), green, Vector3.ZERO, "Bush")
	_sphere(parent, 0.9, pos + Vector3(0, 1.0, 0), green, false, "BushTop")

func _build_tree(parent: Node3D, pos: Vector3, scale_f: float = 1.0) -> void:
	# Choppable: felled with the Axe/Chainsaw (or Lumberjack TIMBER insta-fell) for supplies.
	var t = TREE_SCRIPT.new()
	t.scale_factor = scale_f
	parent.add_child(t)
	t.position = pos

func _build_mailbox(parent: Node3D, pos: Vector3) -> void:
	_solid(parent, Vector3(0.12, 1.1, 0.12), pos + Vector3(0, 0.55, 0), _get_mat("bark", Color(0.35, 0.25, 0.16)), Vector3.ZERO, "MailPost")
	_solid(parent, Vector3(0.3, 0.35, 0.6), pos + Vector3(0, 1.2, 0), _get_mat("mailbox", Color(0.3, 0.3, 0.34), 0.6, 0.4), Vector3.ZERO, "MailBox")

func _build_ornament(parent: Node3D, pos: Vector3, index: int) -> void:
	match index % 3:
		0:
			_sphere(parent, 0.25, pos + Vector3(0, 0.3, 0), _get_mat("gnome_body", Color(0.3, 0.5, 0.7)), false, "GnomeBody")
			_sphere(parent, 0.14, pos + Vector3(0, 0.6, 0), _get_mat("gnome_head", Color(0.9, 0.75, 0.6)), false, "GnomeHead")
			_cylinder(parent, 0.16, 0.3, pos + Vector3(0, 0.82, 0), _get_mat("gnome_cap", Color(0.8, 0.15, 0.15)), false, "GnomeCap")
		1:
			_cylinder(parent, 0.04, 1.0, pos + Vector3(0, 0.5, 0), _get_mat("flam_leg", Color(0.9, 0.6, 0.3)), false, "FlamLeg")
			_sphere(parent, 0.22, pos + Vector3(0, 1.1, 0), _get_mat("flamingo", Color(0.95, 0.5, 0.6)), false, "FlamBody")
		2:
			var stone := _get_mat("stone", Color(0.6, 0.6, 0.62))
			_cylinder(parent, 0.2, 1.0, pos + Vector3(0, 0.5, 0), stone, true, "BirdbathStem")
			_cylinder(parent, 0.6, 0.2, pos + Vector3(0, 1.1, 0), stone, true, "BirdbathBowl")

func _build_rock_cluster(parent: Node3D, pos: Vector3) -> void:
	var stone := _get_mat("rock", Color(0.5, 0.5, 0.52))
	_solid(parent, Vector3(1.6, 1.4, 1.4), pos + Vector3(0, 0.7, 0), stone, Vector3(0, _rng.randf_range(0, PI), 0), "Rock")
	_solid(parent, Vector3(1.1, 0.8, 1.0), pos + Vector3(1.2, 0.4, 0.4), stone, Vector3(0, _rng.randf_range(0, PI), 0), "Rock")
	_solid(parent, Vector3(0.9, 1.0, 0.9), pos + Vector3(-0.9, 0.5, -0.6), stone, Vector3(0, _rng.randf_range(0, PI), 0), "Rock")

func _place_ladder(parent: Node3D, base_pos: Vector3, height: float, yaw: float) -> void:
	var lad = LADDER_SCRIPT.new()
	lad.ladder_height = maxf(height, 2.0)
	parent.add_child(lad)
	lad.position = base_pos
	lad.rotation = Vector3(0, yaw, 0)

func _build_perimeter() -> void:
	var hedge := _get_mat("hedge", Color(0.18, 0.34, 0.18))
	var e := ground_size * 0.5 - 1.0
	var h := 6.0
	_solid(self, Vector3(ground_size, h, 1.0), Vector3(0, h * 0.5, -e), hedge, Vector3.ZERO, "HedgeBack")
	_solid(self, Vector3(1.0, h, ground_size), Vector3(-e, h * 0.5, 0), hedge, Vector3.ZERO, "HedgeLeft")
	_solid(self, Vector3(1.0, h, ground_size), Vector3(e, h * 0.5, 0), hedge, Vector3.ZERO, "HedgeRight")
	var side := (ground_size - road_half_width * 2.0) * 0.5
	_solid(self, Vector3(side, h, 1.0), Vector3(-(road_half_width + side * 0.5), h * 0.5, e), hedge, Vector3.ZERO, "HedgeFrontL")
	_solid(self, Vector3(side, h, 1.0), Vector3(road_half_width + side * 0.5, h * 0.5, e), hedge, Vector3.ZERO, "HedgeFrontR")

func _scatter_common_props() -> void:
	# Street trees ringing the bulb (skip the southern street mouth).
	for i in range(7):
		var a := lerpf(deg_to_rad(20.0), deg_to_rad(340.0), float(i) / 6.0)
		var r := bulb_radius + 3.0
		_build_tree(self, Vector3(sin(a) * r, 0, cos(a) * r), _rng.randf_range(0.9, 1.2))
