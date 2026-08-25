extends "res://scripts/weapons/melee/base_melee.gd"

func _init() -> void:
	tool_name = "Wire Strippers"
	damage = 12
	cooldown = 0.3
	slot_type = 0
	
	swing_duration = 0.12
	stun_chance = 0.25
	swing_angle = 40
	is_thrust = true

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.rotation_degrees.x = 0
	
	var handle_mesh = BoxMesh.new()
	handle_mesh.size = Vector3(0.1, 0.2, 0.05)
	var handle = MeshInstance3D.new()
	handle.mesh = handle_mesh
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.8, 0.1, 0.1)
	handle.material_override = handle_mat
	handle.position = Vector3(0, 0.1, 0)
	visual_root.add_child(handle)
	
	var jaws_mesh = BoxMesh.new()
	jaws_mesh.size = Vector3(0.08, 0.15, 0.04)
	var jaws = MeshInstance3D.new()
	jaws.mesh = jaws_mesh
	var jaws_mat = StandardMaterial3D.new()
	jaws_mat.albedo_color = Color(0.7, 0.7, 0.75)
	jaws_mat.metallic = 0.8
	jaws.material_override = jaws_mat
	jaws.position = Vector3(0, 0.275, 0)
	visual_root.add_child(jaws)
