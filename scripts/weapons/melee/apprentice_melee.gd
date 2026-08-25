extends "res://scripts/weapons/melee/base_melee.gd"

func _init() -> void:
	tool_name = "Tape Measure Whip"
	damage = 6
	cooldown = 0.2
	slot_type = 0
	
	swing_duration = 0.1
	bleed_chance = 0.1
	lifesteal_percent = 0.1
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
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.1, 0.1, 0.1)
	var box = MeshInstance3D.new()
	box.mesh = box_mesh
	var box_mat = StandardMaterial3D.new()
	box_mat.albedo_color = Color(0.9, 0.9, 0.1)
	box.material_override = box_mat
	box.position = Vector3(0, 0.05, 0)
	visual_root.add_child(box)
	
	var tape_mesh = BoxMesh.new()
	tape_mesh.size = Vector3(0.02, 1.2, 0.005)
	var tape = MeshInstance3D.new()
	tape.mesh = tape_mesh
	var tape_mat = StandardMaterial3D.new()
	tape_mat.albedo_color = Color(0.9, 0.9, 0.1)
	tape.material_override = tape_mat
	tape.position = Vector3(0, 0.7, 0)
	visual_root.add_child(tape)
