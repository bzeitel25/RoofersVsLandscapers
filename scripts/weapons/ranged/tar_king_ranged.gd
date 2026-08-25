class_name TarGun
extends BaseTool

const PROJECTILE_SCRIPT = preload("res://scripts/weapons/ranged/base_projectile.gd")
var projectile_speed = 25.0
var visual_root: Node3D

func _ready() -> void:
	tool_name = "Hot Tar Gun"
	damage = 10.0
	cooldown = 0.5
	slot_type = 1 # Ranged
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var barrel = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.08
	b_mesh.bottom_radius = 0.08
	b_mesh.height = 0.5
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.1)
	b_mesh.material = mat
	barrel.mesh = b_mesh
	barrel.rotation_degrees.x = 90
	barrel.position = Vector3(0, 0, -0.25)
	visual_root.add_child(barrel)

func primary_action() -> void:
	if not can_use() or not wielder: return
	_start_cooldown()
	_fire_projectile("tar", Color(0.05, 0.05, 0.05), 10.0, 25.0)

func alt_use_pressed(character: Node3D) -> void:
	if not can_use() or not wielder: return
	
	cooldown = 1.0 # Longer cooldown for flare
	_start_cooldown()
	_fire_projectile("flare", Color(1.0, 0.3, 0.0), 30.0, 45.0) # Faster, higher damage if hit directly

func _fire_projectile(status: String, p_color: Color, p_damage: float, p_speed: float) -> void:
	var camera = wielder.camera
	if not camera: return
	
	var proj = PROJECTILE_SCRIPT.new()
	proj.damage = p_damage
	proj.status_effect = status # "tar" or "flare"
	
	# Gravity - tar loops, flare goes straight
	if status == "tar":
		proj.gravity_scale = 1.2
	else:
		proj.gravity_scale = 0.1
		
	wielder.get_tree().current_scene.add_child(proj)
	
	var p_mesh = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.1 if status == "tar" else 0.05
	s_mesh.height = 0.2 if status == "tar" else 0.1
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = p_color
	if status == "flare":
		p_mat.emission_enabled = true
		p_mat.emission = p_color
		p_mat.emission_energy_multiplier = 5.0
	s_mesh.material = p_mat
	p_mesh.mesh = s_mesh
	proj.add_child(p_mesh)
	
	var col = CollisionShape3D.new()
	var c_shape = SphereShape3D.new()
	c_shape.radius = s_mesh.radius
	col.shape = c_shape
	proj.add_child(col)
	
	proj.body_entered.connect(proj._on_body_entered)
	
	# TPS Aiming
	var target_pos = wielder.get_aim_target() if wielder.has_method("get_aim_target") else (global_position - camera.global_transform.basis.z * 100.0)
	var spawn_pos = global_position + (global_transform.basis.z * -0.3)
	var forward = (target_pos - spawn_pos).normalized()
	
	proj.initialize(Transform3D(Basis(), spawn_pos), forward * p_speed, wielder)
