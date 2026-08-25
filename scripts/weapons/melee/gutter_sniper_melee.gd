extends "res://scripts/weapons/melee/base_melee.gd"

func _init() -> void:
	tool_name = "Gutter Pipe"
	damage = 15
	cooldown = 0.4
	slot_type = 0
	
	swing_duration = 0.2
	crit_chance = 0.35
	crit_multiplier = 2.5
	swing_angle = 80
	is_thrust = false

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.rotation_degrees.x = 0
	
	var gutter_mesh = BoxMesh.new()
	gutter_mesh.size = Vector3(0.1, 0.8, 0.1)
	var gutter = MeshInstance3D.new()
	gutter.mesh = gutter_mesh
	var gutter_mat = StandardMaterial3D.new()
	gutter_mat.albedo_color = Color(0.8, 0.8, 0.85)
	gutter_mat.metallic = 0.5
	gutter.material_override = gutter_mat
	gutter.position = Vector3(0, 0.4, 0)
	visual_root.add_child(gutter)
