extends "res://scripts/weapons/base_tool.gd"

const PROJECTILE_SCRIPT = preload("res://scripts/weapons/ranged/base_projectile.gd")

var visual_root: Node3D
var projectile_speed: float = 18.0

func _ready() -> void:
	super._ready()
	tool_name = "Compost Bomb"
	damage = 18
	cooldown = 1.2
	slot_type = 1
	
	_build_visuals()

func _build_visuals() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var bag = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.2, 0.25, 0.2)
	bag.mesh = b_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.3, 0.2)
	bag.material_override = mat
	
	bag.position = Vector3(0, 0, -0.15)
	visual_root.add_child(bag)

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
	var mesh_shape = SphereMesh.new()
	mesh_shape.radius = 0.12
	mesh_shape.height = 0.24
	p_mesh.mesh = mesh_shape
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.3, 0.2, 0.1)
	p_mesh.material_override = p_mat
	proj.add_child(p_mesh)
	
	var p_col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.12
	p_col.shape = shape
	proj.add_child(p_col)
	
	proj.body_entered.connect(proj._on_body_entered)
	
	var forward = -camera.global_transform.basis.z
	forward.y += 0.3
	forward = forward.normalized()
	
	var spawn_pos = global_position + (global_transform.basis.z * -0.3)
	proj.initialize(Transform3D(Basis(), spawn_pos), forward * projectile_speed, wielder)
