extends "res://scripts/weapons/base_tool.gd"

func _ready() -> void:
	tool_name = "Thorn Wall"
	slot_type = 2
	cooldown = 10.0
	super._ready()
	
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.position = Vector3(0, 0, -0.4)
	visual_root.rotation_degrees.x = -90
	
	var vines = MeshInstance3D.new()
	vines.mesh = CylinderMesh.new()
	vines.mesh.top_radius = 0.1
	vines.mesh.bottom_radius = 0.1
	vines.mesh.height = 0.6
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.OLIVE_DRAB
	vines.material_override = mat
	visual_root.add_child(vines)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	
	if wielder and wielder.camera:
		var cam = wielder.camera
		var space = wielder.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position + (-cam.global_transform.basis.z * 10.0))
		var result = space.intersect_ray(query)
		
		var pos = wielder.global_position + (-wielder.global_transform.basis.z * 3.0)
		pos.y = wielder.global_position.y
		if result:
			pos = result.position
		
		_deploy(pos)

func _deploy(pos: Vector3) -> void:
	var obj = StaticBody3D.new()
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = BoxMesh.new()
	mesh_inst.mesh.size = Vector3(4.0, 2.0, 0.5)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.DARK_GREEN
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0, 1.0, 0)
	obj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(4.0, 2.0, 0.5)
	col.position = Vector3(0, 1.0, 0)
	obj.add_child(col)
	
	var dmg_area = Area3D.new()
	dmg_area.set_collision_layer_value(1, false)
	dmg_area.set_collision_mask_value(2, true)
	var dcol = CollisionShape3D.new()
	dcol.shape = BoxShape3D.new()
	dcol.shape.size = Vector3(4.2, 2.2, 0.7)
	dcol.position = Vector3(0, 1.0, 0)
	dmg_area.add_child(dcol)
	obj.add_child(dmg_area)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	if wielder:
		var dir = wielder.global_position.direction_to(pos)
		dir.y = 0
		if dir.length_squared() > 0.001:
			obj.look_at(pos + dir, Vector3.UP)
	
	var tick_timer = Timer.new()
	tick_timer.wait_time = 1.0
	tick_timer.autostart = true
	tick_timer.timeout.connect(func():
		var bodies = dmg_area.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("take_damage") and body != wielder:
				body.take_damage(5)
	)
	obj.add_child(tick_timer)
	
	var timer = Timer.new()
	timer.wait_time = 8.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
