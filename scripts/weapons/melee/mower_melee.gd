extends "res://scripts/weapons/melee/base_melee.gd"

var visual_root: Node3D

func _init() -> void:
	tool_name = "Mower Blade"
	slot_type = 0
	damage = 20.0
	cooldown = 0.5
	swing_duration = 0.2
	bleed_chance = 0.4
	swing_angle = 100.0
	is_thrust = false

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	visual_root.rotation_degrees.x = 0
	add_child(visual_root)
	
	var blade_mesh = BoxMesh.new()
	blade_mesh.size = Vector3(0.8, 0.1, 0.02)
	var blade = MeshInstance3D.new()
	blade.mesh = blade_mesh
	blade.position = Vector3(0, 0.4, 0)
	blade.rotation_degrees.z = 45
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.4)
	mat.metallic = 0.7
	blade.material_override = mat
	visual_root.add_child(blade)
