extends "res://scripts/weapons/base_tool.gd"

func _ready() -> void:
	tool_name = "Wind Boost"
	slot_type = 2
	cooldown = 10.0
	super._ready()
	
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.position = Vector3(0, 0, -0.3)
	
	var fan = MeshInstance3D.new()
	fan.mesh = CylinderMesh.new()
	fan.mesh.top_radius = 0.15
	fan.mesh.bottom_radius = 0.15
	fan.mesh.height = 0.1
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.GRAY
	fan.material_override = mat
	fan.rotation_degrees.x = 90
	visual_root.add_child(fan)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	
	if wielder and "move_speed" in wielder:
		wielder.move_speed *= 1.5
		var timer = wielder.get_tree().create_timer(4.0)
		timer.timeout.connect(func():
			if is_instance_valid(wielder) and "move_speed" in wielder:
				wielder.move_speed /= 1.5
		)
