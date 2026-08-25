extends "res://scripts/weapons/melee/base_melee.gd"

func _init() -> void:
	tool_name = "Tar Spreader"
	damage = 18
	cooldown = 0.5
	slot_type = 0
	
	swing_duration = 0.25
	slow_chance = 0.3
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
	pole_mesh.top_radius = 0.03
	pole_mesh.bottom_radius = 0.03
	pole_mesh.height = 1.0
	var pole = MeshInstance3D.new()
	pole.mesh = pole_mesh
	var pole_mat = StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.6, 0.4, 0.2)
	pole.material_override = pole_mat
	pole.position = Vector3(0, 0.5, 0)
	visual_root.add_child(pole)
	
	var mop_mesh = BoxMesh.new()
	mop_mesh.size = Vector3(0.4, 0.1, 0.15)
	var mop = MeshInstance3D.new()
	mop.mesh = mop_mesh
	var mop_mat = StandardMaterial3D.new()
	mop_mat.albedo_color = Color(0.1, 0.1, 0.1)
	mop.material_override = mop_mat
	mop.position = Vector3(0, 1.0, 0)
	visual_root.add_child(mop)
