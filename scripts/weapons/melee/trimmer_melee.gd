extends BaseMelee

var visual_root: Node3D

func _init() -> void:
	tool_name = "Hedge Clippers"
	slot_type = 0
	damage = 12.0
	cooldown = 0.35
	swing_duration = 0.15
	bleed_chance = 0.15
	is_thrust = true

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	visual_root.rotation_degrees.x = 0
	add_child(visual_root)
	
	var mat_handle = StandardMaterial3D.new()
	mat_handle.albedo_color = Color(1.0, 0.5, 0.0)
	
	var mat_blade = StandardMaterial3D.new()
	mat_blade.albedo_color = Color(0.8, 0.8, 0.8)
	mat_blade.metallic = 0.9
	
	for i in range(2):
		var sign_val = 1 if i == 0 else -1
		
		var handle_mesh = CylinderMesh.new()
		handle_mesh.top_radius = 0.04
		handle_mesh.bottom_radius = 0.04
		handle_mesh.height = 0.4
		var handle = MeshInstance3D.new()
		handle.mesh = handle_mesh
		handle.position = Vector3(0.1 * sign_val, 0.2, 0)
		handle.rotation_degrees.z = 10 * sign_val
		handle.material_override = mat_handle
		visual_root.add_child(handle)
		
		var blade_mesh = BoxMesh.new()
		blade_mesh.size = Vector3(0.06, 0.6, 0.02)
		var blade = MeshInstance3D.new()
		blade.mesh = blade_mesh
		blade.position = Vector3(0.03 * sign_val, 0.7, 0)
		blade.rotation_degrees.z = -5 * sign_val
		blade.material_override = mat_blade
		visual_root.add_child(blade)
