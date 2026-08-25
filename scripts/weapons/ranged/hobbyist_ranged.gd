extends "res://scripts/weapons/base_tool.gd"

const PROJECTILE_SCRIPT = preload("res://scripts/weapons/ranged/base_projectile.gd")

var visual_root: Node3D
var projectile_speed: float = 15.0

func _ready() -> void:
	super._ready()
	tool_name = "RC Bomber"
	damage = 22
	cooldown = 1.5
	slot_type = 1
	
	_build_visuals()

func _build_visuals() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var rc_box = MeshInstance3D.new()
	var rc_mesh = BoxMesh.new()
	rc_mesh.size = Vector3(0.2, 0.1, 0.15)
	rc_box.mesh = rc_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.1)
	rc_box.material_override = mat
	
	rc_box.position = Vector3(0, 0, -0.1)
	visual_root.add_child(rc_box)

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
	var mesh_shape = BoxMesh.new()
	mesh_shape.size = Vector3(0.1, 0.05, 0.2)
	p_mesh.mesh = mesh_shape
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.9, 0.9, 0.9)
	p_mesh.material_override = p_mat
	proj.add_child(p_mesh)
	
	var p_col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.1, 0.05, 0.2)
	p_col.shape = shape
	proj.add_child(p_col)
	
	proj.body_entered.connect(proj._on_body_entered)
	
	var forward = -camera.global_transform.basis.z
	forward.y += 0.2
	forward = forward.normalized()
	
	var spawn_pos = global_position + (global_transform.basis.z * -0.3)
	proj.initialize(Transform3D(Basis(), spawn_pos), forward * projectile_speed, wielder)
