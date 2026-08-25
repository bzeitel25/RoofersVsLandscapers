class_name PocketKnife
extends BaseMelee

func _ready() -> void:
	tool_name = "Pocket Knife"
	damage = 10.0
	cooldown = 0.3
	swing_duration = 0.15
	crit_chance = 0.15
	is_thrust = true # Fast stabbing motion
	
	super._ready()
	
	# Remove default base mesh if any, and build a composite mesh
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	var visual_root = Node3D.new()
	visual_root.rotation_degrees.x = 0 # Point forward (-Z) instead of Up (+Y)
	add_child(visual_root)
	
	# Handle
	var handle = MeshInstance3D.new()
	var h_mesh = BoxMesh.new()
	h_mesh.size = Vector3(0.1, 0.375, 0.15) # Scaled up 2.5x
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.2, 0.2, 0.2) # Dark plastic/wood handle
	h_mesh.material = h_mat
	handle.mesh = h_mesh
	handle.position = Vector3(0, 0.187, 0)
	visual_root.add_child(handle)
	
	# Blade
	var blade = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.025, 0.375, 0.125) # Scaled up 2.5x
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.8, 0.8, 0.8) # Silver blade
	b_mat.metallic = 0.8
	b_mat.roughness = 0.2
	b_mesh.material = b_mat
	blade.mesh = b_mesh
	blade.position = Vector3(0, 0.562, 0) # Positioned above handle
	visual_root.add_child(blade)
