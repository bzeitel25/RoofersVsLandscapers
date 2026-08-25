extends BaseTool

const PROJECTILE_SCRIPT = preload("res://scripts/weapons/ranged/base_projectile.gd")

var visual_root: Node3D
var projectile_speed: float = 22.0

func _ready() -> void:
	super._ready()
	tool_name = "Throwing Axes"
	damage = 20
	cooldown = 1.0
	slot_type = 1
	
	_build_visuals()

func _build_visuals() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	
	# Handle
	var handle = MeshInstance3D.new()
	var h_mesh = CylinderMesh.new()
	h_mesh.top_radius = 0.03
	h_mesh.bottom_radius = 0.03
	h_mesh.height = 0.4
	handle.mesh = h_mesh
	
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.5, 0.3, 0.1)
	handle.material_override = h_mat
	
	handle.position = Vector3(0, 0, 0)
	handle.rotation_degrees.x = 90
	visual_root.add_child(handle)
	
	# Axe head
	var head = MeshInstance3D.new()
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.02, 0.15, 0.15)
	head.mesh = head_mesh
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.7, 0.7, 0.7)
	head_mat.metallic = 0.8
	head.material_override = head_mat
	
	head.position = Vector3(0, 0.05, -0.15)
	visual_root.add_child(head)

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
	mesh_shape.size = Vector3(0.05, 0.2, 0.2)
	p_mesh.mesh = mesh_shape
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.7, 0.7, 0.7)
	p_mesh.material_override = p_mat
	proj.add_child(p_mesh)
	
	var p_col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.05, 0.2, 0.2)
	p_col.shape = shape
	proj.add_child(p_col)
	
	proj.body_entered.connect(proj._on_body_entered)
	
	var forward = -camera.global_transform.basis.z
	forward.y += 0.15
	forward = forward.normalized()
	
	var spawn_pos = global_position + (global_transform.basis.z * -0.3)
	proj.initialize(Transform3D(Basis(), spawn_pos), forward * projectile_speed, wielder)
