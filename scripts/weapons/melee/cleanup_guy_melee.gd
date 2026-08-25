extends "res://scripts/weapons/melee/base_melee.gd"

func _init() -> void:
	tool_name = "Push Broom"
	damage = 10
	cooldown = 0.4
	slot_type = 0
	
	swing_duration = 0.18
	slow_chance = 0.25
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
	
	var pole_mesh = CylinderMesh.new()
	pole_mesh.top_radius = 0.02
	pole_mesh.bottom_radius = 0.02
	pole_mesh.height = 0.8
	var pole = MeshInstance3D.new()
	pole.mesh = pole_mesh
	var pole_mat = StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.5, 0.3, 0.1)
	pole.material_override = pole_mat
	pole.position = Vector3(0, 0.4, 0)
	visual_root.add_child(pole)
	
	var broom_mesh = BoxMesh.new()
	broom_mesh.size = Vector3(0.5, 0.1, 0.1)
	var broom = MeshInstance3D.new()
	broom.mesh = broom_mesh
	var broom_mat = StandardMaterial3D.new()
	broom_mat.albedo_color = Color(0.4, 0.25, 0.1)
	broom.material_override = broom_mat
	broom.position = Vector3(0, 0.85, 0)
	visual_root.add_child(broom)
