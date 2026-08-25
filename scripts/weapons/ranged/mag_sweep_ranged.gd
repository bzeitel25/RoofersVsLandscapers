extends BaseTool

const PROJECTILE_SCRIPT = preload("res://scripts/weapons/ranged/base_projectile.gd")
var projectile_speed = 35.0
var visual_root: Node3D

func _ready() -> void:
	tool_name = "Nail Magnet"
	damage = 12
	cooldown = 0.6
	slot_type = 1 # Ranged
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var body = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.2, 0.2, 0.4)
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color.DARK_SLATE_GRAY
	b_mesh.material = b_mat
	body.mesh = b_mesh
	body.position = Vector3(0, 0, -0.1)
	visual_root.add_child(body)
	
	var mag = MeshInstance3D.new()
	var m_mesh = CylinderMesh.new()
	m_mesh.top_radius = 0.15
	m_mesh.bottom_radius = 0.15
	m_mesh.height = 0.1
	var m_mat = StandardMaterial3D.new()
	m_mat.albedo_color = Color.RED
	m_mesh.material = m_mat
	mag.mesh = m_mesh
	mag.rotation_degrees.x = -90
	mag.position = Vector3(0, 0, -0.35)
	visual_root.add_child(mag)

func primary_action() -> void:
	if not can_use() or not wielder: return
	_start_cooldown()
	_fire_projectile()

func _fire_projectile() -> void:
	var camera = wielder.camera
	if not camera: return
	
	for i in range(3):
		var proj = PROJECTILE_SCRIPT.new()
		proj.damage = damage
		wielder.get_tree().current_scene.add_child(proj)
		
		var p_mesh = MeshInstance3D.new()
		var s_mesh = CylinderMesh.new()
		s_mesh.top_radius = 0.01
		s_mesh.bottom_radius = 0.01
		s_mesh.height = 0.1
		var p_mat = StandardMaterial3D.new()
		p_mat.albedo_color = Color.SILVER
		s_mesh.material = p_mat
		p_mesh.mesh = s_mesh
		p_mesh.rotation_degrees.x = 90
		proj.add_child(p_mesh)
		
		var col = CollisionShape3D.new()
		var c_shape = SphereShape3D.new()
		c_shape.radius = 0.02
		col.shape = c_shape
		proj.add_child(col)
		
		proj.body_entered.connect(proj._on_body_entered)
		var forward = -camera.global_transform.basis.z
		
		if i == 1:
			forward.x += 0.05
		elif i == 2:
			forward.x -= 0.05
		forward = forward.normalized()
			
		var spawn_pos = global_position + (global_transform.basis.z * -0.4)
		proj.initialize(Transform3D(Basis(), spawn_pos), forward * projectile_speed, wielder)
