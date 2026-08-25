class_name ShingleSlingerRanged
extends "res://scripts/weapons/base_tool.gd"

const PROJECTILE_SCRIPT = preload("res://scripts/weapons/ranged/base_projectile.gd")
var projectile_speed = 35.0
var visual_root: Node3D

func _ready() -> void:
	tool_name = "Shingle Tosser"
	damage = 18.0
	cooldown = 0.4
	slot_type = 1 # Ranged
	super._ready()
	
	# Clear auto-generated meshes if any
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var mesh = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.2, 0.05, 0.3)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.DARK_GRAY
	b_mesh.material = mat
	mesh.mesh = b_mesh
	mesh.position = Vector3(0, 0, -0.15)
	visual_root.add_child(mesh)

func primary_action() -> void:
	if not can_use() or not wielder: return
	_start_cooldown()
	_fire_projectile(0.0) # 0 spread

func alt_use_pressed(character: Node3D) -> void:
	# Secondary: Fan of Shingles (Shotgun blast)
	if not can_use() or not wielder: return
	
	# Assume this consumes 3 "ammo" (supplies)
	if wielder.has_method("consume_supplies"):
		wielder.consume_supplies(3)
		
	cooldown = 0.8
	_start_cooldown()
	
	# Fire 5 shingles in a horizontal spread
	var spreads = [-0.15, -0.075, 0.0, 0.075, 0.15]
	for s in spreads:
		_fire_projectile(s)

func _fire_projectile(horizontal_spread: float) -> void:
	var proj = PROJECTILE_SCRIPT.new()
	proj.damage = damage
	wielder.get_tree().current_scene.add_child(proj)
	
	var p_mesh = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(0.2, 0.02, 0.3)
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color.DARK_SLATE_GRAY
	s_mesh.material = p_mat
	p_mesh.mesh = s_mesh
	proj.add_child(p_mesh)
	
	var col = CollisionShape3D.new()
	var c_shape = BoxShape3D.new()
	c_shape.size = Vector3(0.2, 0.02, 0.3)
	col.shape = c_shape
	proj.add_child(col)
	
	proj.body_entered.connect(proj._on_body_entered)
	
	# TPS Aiming
	var target_pos = wielder.get_aim_target() if wielder.has_method("get_aim_target") else (global_position - wielder.camera.global_transform.basis.z * 100.0)
	var spawn_pos = global_position + (global_transform.basis.z * -0.3)
	var forward = (target_pos - spawn_pos).normalized()
	
	# Apply spread
	var right = wielder.camera.global_transform.basis.x
	forward = (forward + (right * horizontal_spread)).normalized()
	
	proj.initialize(Transform3D(Basis(), spawn_pos), forward * projectile_speed, wielder)
