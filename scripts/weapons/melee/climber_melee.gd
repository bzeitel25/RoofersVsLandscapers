extends BaseMelee

var visual_root: Node3D

func _init() -> void:
	tool_name = "Tree Spikes"
	slot_type = 0
	damage = 5.0
	cooldown = 0.15
	swing_duration = 0.08
	bleed_chance = 0.2
	stun_chance = 0.1
	is_thrust = true

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	visual_root.rotation_degrees.x = 0
	add_child(visual_root)
	
	var glove_mesh = CylinderMesh.new()
	glove_mesh.top_radius = 0.08
	glove_mesh.bottom_radius = 0.06
	glove_mesh.height = 0.25
	var glove = MeshInstance3D.new()
	glove.mesh = glove_mesh
	glove.position = Vector3(0, 0.125, 0)
	var mat_glove = StandardMaterial3D.new()
	mat_glove.albedo_color = Color(0.2, 0.2, 0.2)
	glove.material_override = mat_glove
	visual_root.add_child(glove)
	
	var mat_spike = StandardMaterial3D.new()
	mat_spike.albedo_color = Color(0.8, 0.8, 0.8)
	mat_spike.metallic = 1.0
	
	for i in range(3):
		var spike_mesh = CylinderMesh.new()
		spike_mesh.top_radius = 0.0
		spike_mesh.bottom_radius = 0.02
		spike_mesh.height = 0.15
		var spike = MeshInstance3D.new()
		spike.mesh = spike_mesh
		spike.position = Vector3(-0.06 + i * 0.06, 0.25, 0)
		spike.material_override = mat_spike
		visual_root.add_child(spike)
