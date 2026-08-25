extends "res://scripts/weapons/melee/base_melee.gd"

var visual_root: Node3D

func _init() -> void:
	tool_name = "Pipe Wrench"
	slot_type = 0
	damage = 22.0
	cooldown = 0.6
	swing_duration = 0.3
	crit_chance = 0.15
	swing_angle = 90.0
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
	handle_mesh.top_radius = 0.04
	handle_mesh.bottom_radius = 0.04
	handle_mesh.height = 0.8
	var handle = MeshInstance3D.new()
	handle.mesh = handle_mesh
	handle.position = Vector3(0, 0.4, 0)
	var mat_handle = StandardMaterial3D.new()
	mat_handle.albedo_color = Color(0.8, 0.1, 0.1)
	handle.material_override = mat_handle
	visual_root.add_child(handle)
	
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.2, 0.2, 0.08)
	var head = MeshInstance3D.new()
	head.mesh = head_mesh
	head.position = Vector3(0.05, 0.8, 0)
	var mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.7, 0.7, 0.7)
	mat_metal.metallic = 0.9
	head.material_override = mat_metal
	visual_root.add_child(head)
