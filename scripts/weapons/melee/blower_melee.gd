extends "res://scripts/weapons/melee/base_melee.gd"

func _init() -> void:
	tool_name = "Vine Whip"
	slot_type = 0
	damage = 12.0
	cooldown = 1.1
	swing_duration = 0.4
	knockback_multiplier = 1.0 # Standard knockback
	root_chance = 0.2 # 20% chance to root targets
	is_thrust = false

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
	handle_mesh.top_radius = 0.04
	handle_mesh.bottom_radius = 0.04
	handle_mesh.height = 0.3
	var handle = MeshInstance3D.new()
	handle.mesh = handle_mesh
	handle.position = Vector3(0, 0.15, 0)
	var mat_handle = StandardMaterial3D.new()
	mat_handle.albedo_color = Color(0.2, 0.1, 0.05) # Dark wood
	handle.material_override = mat_handle
	visual_root.add_child(handle)
	
	# Vine body (long and thin)
	var vine_mesh = CylinderMesh.new()
	vine_mesh.top_radius = 0.015
	vine_mesh.bottom_radius = 0.02
	vine_mesh.height = 1.6 # Very long
	var vine = MeshInstance3D.new()
	vine.mesh = vine_mesh
	vine.position = Vector3(0, 1.1, 0)
	var mat_vine = StandardMaterial3D.new()
	mat_vine.albedo_color = Color(0.1, 0.7, 0.2) # Bright green vine
	vine.material_override = mat_vine
	visual_root.add_child(vine)
