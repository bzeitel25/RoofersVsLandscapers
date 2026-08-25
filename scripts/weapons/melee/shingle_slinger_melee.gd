extends "res://scripts/weapons/melee/base_melee.gd"

func _init() -> void:
	tool_name = "Shingle Shiv"
	damage = 8
	cooldown = 0.25
	slot_type = 0
	
	swing_duration = 0.12
	bleed_chance = 0.2
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
	
	var shingle_mesh = BoxMesh.new()
	shingle_mesh.size = Vector3(0.15, 0.4, 0.02)
	var shingle = MeshInstance3D.new()
	shingle.mesh = shingle_mesh
	var shingle_mat = StandardMaterial3D.new()
	shingle_mat.albedo_color = Color(0.2, 0.2, 0.2)
	shingle.material_override = shingle_mat
	shingle.position = Vector3(0, 0.2, 0)
	
	# Slight curve using rotation inside the node
	shingle.rotation_degrees.x = 10
	visual_root.add_child(shingle)
