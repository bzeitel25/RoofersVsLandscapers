extends BaseMelee

var visual_root: Node3D

func _init() -> void:
	tool_name = "Felling Axe"
	slot_type = 0
	damage = 30.0
	cooldown = 1.0
	bleed_chance = 0.25 # 25% chance to bleed
	swing_duration = 0.4
	swing_angle = 120.0
	is_thrust = false

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	visual_root.rotation_degrees.x = 0
	add_child(visual_root)
	
	var handle_mesh = CylinderMesh.new()
	handle_mesh.top_radius = 0.05
	handle_mesh.bottom_radius = 0.05
	handle_mesh.height = 1.2
	var handle = MeshInstance3D.new()
	handle.mesh = handle_mesh
	handle.position = Vector3(0, 0.6, 0)
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.4, 0.2, 0.1)
	handle.material_override = handle_mat
	visual_root.add_child(handle)
	
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.4, 0.3, 0.1)
	var head = MeshInstance3D.new()
	head.mesh = head_mesh
	head.position = Vector3(0.15, 1.1, 0)
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.2, 0.2, 0.2)
	head_mat.metallic = 0.8
	head.material_override = head_mat
	visual_root.add_child(head)
