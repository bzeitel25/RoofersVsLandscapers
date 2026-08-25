extends BaseTool

const PROJECTILE_SCRIPT = preload("res://scripts/weapons/ranged/base_projectile.gd")
var projectile_speed = 20.0
var visual_root: Node3D

func _ready() -> void:
	tool_name = "Freon Cannon"
	damage = 15
	cooldown = 0.7
	slot_type = 1 # Ranged
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var body = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.12
	b_mesh.bottom_radius = 0.12
	b_mesh.height = 0.5
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color.WHITE
	b_mesh.material = b_mat
	body.mesh = b_mesh
	body.rotation_degrees.x = -90
	body.position = Vector3(0, 0, -0.1)
	visual_root.add_child(body)
	
	var band = MeshInstance3D.new()
	var bd_mesh = CylinderMesh.new()
	bd_mesh.top_radius = 0.125
	bd_mesh.bottom_radius = 0.125
	bd_mesh.height = 0.1
	var bd_mat = StandardMaterial3D.new()
	bd_mat.albedo_color = Color.CORNFLOWER_BLUE
	bd_mesh.material = bd_mat
	band.mesh = bd_mesh
	band.rotation_degrees.x = -90
	band.position = Vector3(0, 0, -0.1)
	visual_root.add_child(band)

	var nozzle = MeshInstance3D.new()
	var n_mesh = CylinderMesh.new()
	n_mesh.top_radius = 0.03
	n_mesh.bottom_radius = 0.08
	n_mesh.height = 0.2
	var n_mat = StandardMaterial3D.new()
	n_mat.albedo_color = Color.SILVER
	n_mesh.material = n_mat
	nozzle.mesh = n_mesh
	nozzle.rotation_degrees.x = -90
	nozzle.position = Vector3(0, 0, -0.45)
	visual_root.add_child(nozzle)

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
	s_mesh.radius = 0.1
	s_mesh.height = 0.2
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color.LIGHT_BLUE
	s_mesh.material = p_mat
	p_mesh.mesh = s_mesh
	proj.add_child(p_mesh)
	
	var col = CollisionShape3D.new()
	var c_shape = SphereShape3D.new()
	c_shape.radius = 0.1
	col.shape = c_shape
	proj.add_child(col)
	
	proj.body_entered.connect(proj._on_body_entered)
	var forward = -camera.global_transform.basis.z
	forward.y += 0.15 # Arcing
	forward = forward.normalized()
	var spawn_pos = global_position + (global_transform.basis.z * -0.6)
	proj.initialize(Transform3D(Basis(), spawn_pos), forward * projectile_speed, wielder)
