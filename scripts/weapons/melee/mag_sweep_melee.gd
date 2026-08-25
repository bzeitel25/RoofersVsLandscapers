extends "res://scripts/weapons/melee/base_melee.gd"

func _init() -> void:
	tool_name = "Magnetic Sweeper"
	damage = 15
	cooldown = 0.6
	slot_type = 0
	
	swing_duration = 0.3
	knockback_multiplier = 3.0
	stun_chance = 0.15
	swing_angle = 90
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
	pole_mesh.height = 0.9
	var pole = MeshInstance3D.new()
	pole.mesh = pole_mesh
	var pole_mat = StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.7, 0.7, 0.7)
	pole.material_override = pole_mat
	pole.position = Vector3(0, 0.45, 0)
	visual_root.add_child(pole)
	
	var magnet_mesh = BoxMesh.new()
	magnet_mesh.size = Vector3(0.6, 0.1, 0.1)
	var magnet = MeshInstance3D.new()
	magnet.mesh = magnet_mesh
	var magnet_mat = StandardMaterial3D.new()
	magnet_mat.albedo_color = Color(0.2, 0.2, 0.2)
	magnet_mat.metallic = 0.9
	magnet.material_override = magnet_mat
	magnet.position = Vector3(0, 0.95, 0)
	visual_root.add_child(magnet)
