extends BaseTool

const PROJECTILE_SCRIPT = preload("res://scripts/weapons/ranged/base_projectile.gd")
var projectile_speed = 20.0
var visual_root: Node3D

func _ready() -> void:
	tool_name = "Tar Launcher"
	damage = 15
	cooldown = 0.8
	slot_type = 1 # Ranged
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var body = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.1
	b_mesh.bottom_radius = 0.1
	b_mesh.height = 0.8
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color.DIM_GRAY
	b_mesh.material = b_mat
	body.mesh = b_mesh
	body.rotation_degrees.x = -90
	body.position = Vector3(0, 0, -0.3)
	visual_root.add_child(body)

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
	s_mesh.radius = 0.15
	s_mesh.height = 0.3
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color.WEB_MAROON.darkened(0.5)
	s_mesh.material = p_mat
	p_mesh.mesh = s_mesh
	proj.add_child(p_mesh)
	
	var col = CollisionShape3D.new()
	var c_shape = SphereShape3D.new()
	c_shape.radius = 0.15
	col.shape = c_shape
	proj.add_child(col)
	
	proj.body_entered.connect(proj._on_body_entered)
	var forward = -camera.global_transform.basis.z
	forward.y += 0.2
	var spawn_pos = global_position + (global_transform.basis.z * -0.5)
	proj.initialize(Transform3D(Basis(), spawn_pos), forward * projectile_speed, wielder)
