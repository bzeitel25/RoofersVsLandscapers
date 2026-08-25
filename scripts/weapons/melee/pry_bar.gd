class_name PryBar
extends BaseMelee

func _ready() -> void:
	tool_name = "Pry Bar"
	damage = 25.0
	cooldown = 0.8
	swing_duration = 0.3
	knockback_multiplier = 2.5
	stun_chance = 0.1
	swing_angle = 90.0
	is_thrust = false # It's a heavy sweeping arc
	
	super._ready()
	
	# Remove default base mesh if any, and build a composite mesh
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.1, 0.1) # Red metal
	mat.metallic = 0.5
	mat.roughness = 0.4
			
	var visual_root = Node3D.new()
	visual_root.rotation_degrees.x = 0 # Angled forward like a heavy swinging tool
	add_child(visual_root)
	
	# Shaft
	var shaft = MeshInstance3D.new()
	var s_mesh = CylinderMesh.new()
	s_mesh.top_radius = 0.03
	s_mesh.bottom_radius = 0.03
	s_mesh.height = 1.05 # 1.5x
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.1, 0.1, 0.1) # Black/Dark grey metal
	s_mat.metallic = 0.7
	s_mat.roughness = 0.4
	s_mesh.material = s_mat
	shaft.mesh = s_mesh
	shaft.position = Vector3(0, 0.525, 0)
	visual_root.add_child(shaft)
	
	# Hook at the top
	var hook = MeshInstance3D.new()
	var h_mesh = BoxMesh.new()
	h_mesh.size = Vector3(0.045, 0.045, 0.225)
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.8, 0.2, 0.2) # Red tip
	h_mat.metallic = 0.5
	h_mesh.material = h_mat
	hook.mesh = h_mesh
	hook.position = Vector3(0, 1.05, 0.075) # Positioned at the top, jutting forward
	hook.rotation_degrees = Vector3(15, 0, 0) # Slight angle
	visual_root.add_child(hook)
