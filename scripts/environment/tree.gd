extends StaticBody3D
# ============================================================
# ROOFERS vs LANDSCAPERS — Choppable Tree
# ============================================================
# A tree that doubles as cover AND a harvestable resource.
# It is a StaticBody3D on the WORLD collision layer (1) with a
# `take_damage()` method, so it plugs straight into the existing
# damage pipeline: any weapon that calls `body.take_damage()`
# (base_melee hitbox, projectiles, gadgets) chips it down.
#
#   * Axe / Chainsaw / any melee: normal swings deal chip damage
#     -> a few hits to fell (health / per-hit damage).
#   * Lumberjack Felling Axe alt-fire "TIMBER" deals 999 to
#     non-players on a ~2.5s cooldown -> INSTANT fell (the
#     Lumberjack's insta-cut ability, already on a brief cooldown).
#   * Any single hit >= `insta_threshold` also insta-fells.
#
# On fell it topples, leaves a stump, and drops a wood pickup that
# grants `supply_reward` supplies to whoever collects it (for
# building catapults / ramps / siege and fuelling gadgets).
# ============================================================

const WORLD_LAYER := 1

@export var max_health: float = 90.0
@export var supply_reward: int = 25
@export var scale_factor: float = 1.0
@export var insta_threshold: float = 100.0   # a single hit this big fells instantly (e.g. TIMBER's 999)

var health: float
var _felled := false
var _topple_yaw := 0.0

func _ready() -> void:
	collision_layer = WORLD_LAYER
	collision_mask = 0
	health = max_health
	add_to_group("choppable_tree")
	_build_visual()

func _build_visual() -> void:
	var bark := StandardMaterial3D.new()
	bark.albedo_texture = load("res://assets/textures/environment/wood.jpg")
	bark.albedo_color = Color(0.35, 0.25, 0.16)
	bark.roughness = 0.95
	bark.uv1_triplanar = true
	bark.uv1_world_triplanar = true
	bark.uv1_scale = Vector3(0.2, 0.2, 0.2)
	bark.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	var leaf := StandardMaterial3D.new()
	leaf.albedo_texture = load("res://assets/textures/environment/leaves.jpg")
	leaf.albedo_color = Color(0.2, 0.42, 0.2)
	leaf.roughness = 0.95
	leaf.uv1_triplanar = true
	leaf.uv1_world_triplanar = true
	leaf.uv1_scale = Vector3(0.15, 0.15, 0.15)
	leaf.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Make canopy semi-transparent when the camera is inside it
	leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	leaf.distance_fade_min_distance = 2.0 # Transparent when < 2.0m
	leaf.distance_fade_max_distance = 5.0 # Opaque when > 5.0m
	
	var trunk_h := 4.0 * scale_factor

	# Trunk collision lives on THIS body (so melee/projectile hits register on the tree).
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.35 * scale_factor
	cyl.height = trunk_h
	cs.shape = cyl
	cs.position = Vector3(0, trunk_h * 0.5, 0)
	add_child(cs)

	var tm := CylinderMesh.new()
	tm.top_radius = 0.32 * scale_factor
	tm.bottom_radius = 0.42 * scale_factor
	tm.height = trunk_h
	var trunk := MeshInstance3D.new()
	trunk.mesh = tm
	trunk.material_override = bark
	trunk.position = Vector3(0, trunk_h * 0.5, 0)
	add_child(trunk)
	
	# Physical Branch (to perch/stand on inside the canopy)
	var branch_body := StaticBody3D.new()
	branch_body.collision_layer = 1 # Layer 1 (World) ONLY
	
	var branch_cs := CollisionShape3D.new()
	var branch_cyl := CylinderShape3D.new()
	branch_cyl.radius = 0.15 * scale_factor
	branch_cyl.height = 1.6 * scale_factor # Shorter stick-out
	branch_cs.shape = branch_cyl
	
	branch_body.rotation = Vector3(deg_to_rad(90), 0, randf_range(0, PI)) # Random horizontal angle
	branch_body.position = Vector3(0, trunk_h * 0.95, 0) # Higher into the canopy
	branch_body.position += branch_body.transform.basis.y * (0.6 * scale_factor) # Shift out slightly
	branch_body.add_child(branch_cs)
	
	# Massive forgiving interaction zone
	var interact_area := Area3D.new()
	interact_area.collision_layer = 64 # Layer 7 (Interactable)
	interact_area.collision_mask = 0
	interact_area.set_script(load("res://scripts/environment/tree_branch.gd"))
	var interact_cs := CollisionShape3D.new()
	var interact_sphere := SphereShape3D.new()
	interact_sphere.radius = 2.0 * scale_factor
	interact_cs.shape = interact_sphere
	interact_area.add_child(interact_cs)
	branch_body.add_child(interact_area)
	
	var branch_mesh := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.12 * scale_factor
	bm.bottom_radius = 0.18 * scale_factor
	bm.height = 1.6 * scale_factor
	branch_mesh.mesh = bm
	branch_mesh.material_override = bark
	branch_body.add_child(branch_mesh)
	
	add_child(branch_body)

	# Canopy (visual only) — all children topple together when we rotate this body.
	var c1 := MeshInstance3D.new()
	var s1 := SphereMesh.new()
	s1.radius = 2.2 * scale_factor
	s1.height = 4.4 * scale_factor
	c1.mesh = s1
	c1.material_override = leaf
	c1.position = Vector3(0, trunk_h + 1.2 * scale_factor, 0)
	add_child(c1)
	var c2 := MeshInstance3D.new()
	var s2 := SphereMesh.new()
	s2.radius = 1.6 * scale_factor
	s2.height = 3.2 * scale_factor
	c2.mesh = s2
	c2.material_override = leaf
	c2.position = Vector3(1.0 * scale_factor, trunk_h + 0.4 * scale_factor, 0.6 * scale_factor)
	add_child(c2)

## Damage entry point — matches the project-wide take_damage(amount, from_peer) signature.
func take_damage(amount: float, _from_peer: int = 1) -> void:
	if _felled:
		return
	health -= amount
	if amount >= insta_threshold or health <= 0.0:
		fell(_from_peer)

## Public: fell the tree immediately (used by insta-cut / TIMBER, or when health hits 0).
func fell(_from_peer: int = 1) -> void:
	if _felled:
		return
	_felled = true
	collision_layer = 0   # stop blocking movement and stop re-registering hits mid-topple

	var trunk_h := 4.0 * scale_factor
	var base_pos := global_position

	# Leave a stump at the base.
	var stump := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.42 * scale_factor
	sm.bottom_radius = 0.44 * scale_factor
	sm.height = 0.5
	stump.mesh = sm
	var stump_mat := StandardMaterial3D.new()
	stump_mat.albedo_texture = load("res://assets/textures/environment/wood.jpg")
	stump_mat.albedo_color = Color(0.3, 0.22, 0.14)
	stump_mat.uv1_triplanar = true
	stump_mat.uv1_world_triplanar = true
	stump_mat.uv1_scale = Vector3(0.2, 0.2, 0.2)
	stump_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	stump.material_override = stump_mat
	var host := get_parent()
	if host:
		host.add_child(stump)
		stump.global_position = base_pos + Vector3(0, 0.25, 0)

	# Topple over, then drop wood and remove the standing tree.
	_topple_yaw = _pseudo_random_yaw(base_pos)
	var tw := create_tween()
	tw.tween_method(_topple_step, 0.0, 1.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_finish_fell.bind(base_pos + Vector3(0, 0.4, 0), trunk_h))

func _topple_step(t: float) -> void:
	rotation = Vector3(deg_to_rad(88.0) * t, _topple_yaw, 0.0)

func _finish_fell(drop_pos: Vector3, _trunk_h: float) -> void:
	var host := get_parent()
	if host:
		_spawn_wood_pickup(host, drop_pos)
	queue_free()

func _spawn_wood_pickup(host: Node, pos: Vector3) -> void:
	var reward := supply_reward
	var area := Area3D.new()
	area.name = "WoodPickup"
	area.collision_layer = 0
	area.collision_mask = 3   # detect players (layers 1/2)
	var acs := CollisionShape3D.new()
	var abox := BoxShape3D.new()
	abox.size = Vector3(1.8, 1.2, 1.8)
	acs.shape = abox
	area.add_child(acs)
	# Visual: a couple of stacked logs.
	var bark := StandardMaterial3D.new()
	bark.albedo_texture = load("res://assets/textures/environment/wood.jpg")
	bark.albedo_color = Color(0.4, 0.28, 0.16)
	bark.uv1_triplanar = true
	bark.uv1_world_triplanar = true
	bark.uv1_scale = Vector3(0.2, 0.2, 0.2)
	bark.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for i in range(2):
		var log := MeshInstance3D.new()
		var lm := CylinderMesh.new()
		lm.top_radius = 0.22
		lm.bottom_radius = 0.22
		lm.height = 1.6
		log.mesh = lm
		log.material_override = bark
		log.rotation = Vector3(0, 0, deg_to_rad(90.0))
		log.position = Vector3(0.0, 0.22 + 0.34 * float(i), -0.2 + 0.4 * float(i))
		area.add_child(log)
	area.add_to_group("wood_pickup")
	area.body_entered.connect(func(body: Node) -> void:
		if body != null and "supplies" in body and "max_supplies" in body:
			body.supplies = min(body.supplies + reward, body.max_supplies)
			if body.has_method("update_hud"):
				body.update_hud()
			area.queue_free()
	)
	host.add_child(area)
	area.global_position = pos

func _pseudo_random_yaw(seedpos: Vector3) -> float:
	# Deterministic per-position spin (avoids Math.random-style nondeterminism).
	return fmod(absf(seedpos.x * 12.9898 + seedpos.z * 78.233), TAU)
