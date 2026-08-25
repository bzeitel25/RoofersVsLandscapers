extends BaseMelee

var visual_root: Node3D

func _init() -> void:
	tool_name = "War Rake"
	slot_type = 0
	damage = 10.0
	cooldown = 0.4
	swing_duration = 0.2
	knockback_multiplier = 1.5
	slow_chance = 0.15
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
	handle_mesh.top_radius = 0.03
	handle_mesh.bottom_radius = 0.03
	handle_mesh.height = 1.4
	var handle = MeshInstance3D.new()
	handle.mesh = handle_mesh
	handle.position = Vector3(0, 0.7, 0)
	var mat_handle = StandardMaterial3D.new()
	mat_handle.albedo_color = Color(0.6, 0.4, 0.2)
	handle.material_override = mat_handle
	visual_root.add_child(handle)
	
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.5, 0.05, 0.05)
	var head = MeshInstance3D.new()
	head.mesh = head_mesh
	head.position = Vector3(0, 1.4, 0)
	var mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.5, 0.5, 0.5)
	mat_metal.metallic = 0.8
	head.material_override = mat_metal
	visual_root.add_child(head)
	
	for i in range(5):
		var tine_mesh = CylinderMesh.new()
		tine_mesh.top_radius = 0.01
		tine_mesh.bottom_radius = 0.01
		tine_mesh.height = 0.15
		var tine = MeshInstance3D.new()
		tine.mesh = tine_mesh
		tine.position = Vector3(-0.2 + i * 0.1, 1.4, 0.075)
		tine.rotation_degrees.x = 90
		tine.material_override = mat_metal
		visual_root.add_child(tine)
