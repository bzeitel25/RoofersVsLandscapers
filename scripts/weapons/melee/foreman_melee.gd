extends "res://scripts/weapons/melee/base_melee.gd"

func _init() -> void:
	tool_name = "Boss Hammer"
	damage = 25
	cooldown = 0.8
	slot_type = 0
	stun_chance = 0.15 # 15% chance to stun
	
	swing_duration = 0.35
	swing_angle = 100
	is_thrust = false

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.rotation_degrees.x = 0
	
	# Handle
	var handle_mesh = CylinderMesh.new()
	handle_mesh.top_radius = 0.04
	handle_mesh.bottom_radius = 0.03
	handle_mesh.height = 0.6
	var handle = MeshInstance3D.new()
	handle.mesh = handle_mesh
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.4, 0.2, 0.1)
	handle.material_override = handle_mat
	handle.position = Vector3(0, 0.3, 0)
	visual_root.add_child(handle)
	
	# Head
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.1, 0.1, 0.2)
	var head = MeshInstance3D.new()
	head.mesh = head_mesh
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.3, 0.3, 0.35)
	head_mat.metallic = 0.8
	head.material_override = head_mat
	head.position = Vector3(0, 0.6, 0)
	visual_root.add_child(head)
