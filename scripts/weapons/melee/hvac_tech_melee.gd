extends "res://scripts/weapons/melee/base_melee.gd"

func _init() -> void:
	tool_name = "Duct Wrench"
	damage = 30
	cooldown = 1.0
	slot_type = 0
	
	swing_duration = 0.4
	stun_chance = 0.2
	swing_angle = 120
	is_thrust = false

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.rotation_degrees.x = 0
	
	var handle_mesh = BoxMesh.new()
	handle_mesh.size = Vector3(0.08, 0.7, 0.08)
	var handle = MeshInstance3D.new()
	handle.mesh = handle_mesh
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.9, 0.3, 0.1)
	handle.material_override = handle_mat
	handle.position = Vector3(0, 0.35, 0)
	visual_root.add_child(handle)
	
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.25, 0.2, 0.1)
	var head = MeshInstance3D.new()
	head.mesh = head_mesh
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.8, 0.8, 0.8)
	head_mat.metallic = 0.9
	head.material_override = head_mat
	head.position = Vector3(0.08, 0.8, 0)
	visual_root.add_child(head)
