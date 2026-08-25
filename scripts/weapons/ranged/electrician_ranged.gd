extends "res://scripts/weapons/base_tool.gd"

const PROJECTILE_SCRIPT = preload("res://scripts/weapons/ranged/base_projectile.gd")
var projectile_speed = 50.0
var visual_root: Node3D

func _ready() -> void:
	tool_name = "Spark Gun"
	damage = 8
	cooldown = 0.3
	slot_type = 1 # Ranged
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var body = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.15, 0.2, 0.4)
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color.YELLOW
	b_mesh.material = b_mat
	body.mesh = b_mesh
	body.position = Vector3(0, 0, -0.1)
	visual_root.add_child(body)
	
	var wires = MeshInstance3D.new()
	var w_mesh = BoxMesh.new()
	w_mesh.size = Vector3(0.05, 0.05, 0.15)
	var w_mat = StandardMaterial3D.new()
	w_mat.albedo_color = Color.BLACK
	w_mesh.material = w_mat
	wires.mesh = w_mesh
	wires.position = Vector3(0, 0.1, -0.3)
	visual_root.add_child(wires)

func primary_action() -> void:
	if not can_use() or not wielder: return
	_start_cooldown()
	_fire_projectile()

func _fire_projectile() -> void:
	var camera = wielder.camera
	if not camera: return
	var proj = PROJECTILE_SCRIPT.new()
	proj.damage = damage
	wielder.get_tree().current_scene.add_child(proj)
	
	var p_mesh = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.05
	s_mesh.height = 0.1
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color.YELLOW
	p_mat.emission_enabled = true
	p_mat.emission = Color.YELLOW
	p_mat.emission_energy_multiplier = 2.0
	s_mesh.material = p_mat
	p_mesh.mesh = s_mesh
	proj.add_child(p_mesh)
	
	var col = CollisionShape3D.new()
	var c_shape = SphereShape3D.new()
	c_shape.radius = 0.05
	col.shape = c_shape
	proj.add_child(col)
	
	proj.body_entered.connect(proj._on_body_entered)
	var forward = -camera.global_transform.basis.z
	var spawn_pos = global_position + (global_transform.basis.z * -0.4)
	proj.initialize(Transform3D(Basis(), spawn_pos), forward * projectile_speed, wielder)
