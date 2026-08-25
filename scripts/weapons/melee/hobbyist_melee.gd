extends BaseMelee

func _init() -> void:
	tool_name = "Screwdriver"
	slot_type = 0
	damage = 8.0
	cooldown = 0.2
	swing_duration = 0.15
	crit_chance = 0.3
	bleed_on_crit = true
	knockback_multiplier = 0.0 # No knockback on stab
	is_thrust = true

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	var visual_root = Node3D.new()
	visual_root.rotation_degrees.x = 0
	add_child(visual_root)
	
	# Handle
	var handle_mesh = CylinderMesh.new()
	handle_mesh.top_radius = 0.03
	handle_mesh.bottom_radius = 0.03
	handle_mesh.height = 0.15
	var handle = MeshInstance3D.new()
	handle.mesh = handle_mesh
	handle.position = Vector3(0, 0.075, 0)
	var mat_handle = StandardMaterial3D.new()
	mat_handle.albedo_color = Color(0.9, 0.6, 0.1) # Yellow handle
	handle.material_override = mat_handle
	visual_root.add_child(handle)
	
	# Shaft
	var shaft_mesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.005
	shaft_mesh.bottom_radius = 0.005
	shaft_mesh.height = 0.25
	var shaft = MeshInstance3D.new()
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0, 0.275, 0)
	var mat_shaft = StandardMaterial3D.new()
	mat_shaft.albedo_color = Color(0.8, 0.8, 0.8)
	mat_shaft.metallic = 0.9
	shaft.material_override = mat_shaft
	visual_root.add_child(shaft)
