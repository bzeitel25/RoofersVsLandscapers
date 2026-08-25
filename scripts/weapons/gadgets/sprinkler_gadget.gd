extends "res://scripts/weapons/base_tool.gd"

func _ready() -> void:
	tool_name = "Sprinkler System"
	slot_type = 2
	cooldown = 10.0
	super._ready()
	
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.position = Vector3(0, 0, -0.2)
	
	var body = MeshInstance3D.new()
	body.mesh = CylinderMesh.new()
	body.mesh.top_radius = 0.05
	body.mesh.bottom_radius = 0.08
	body.mesh.height = 0.15
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.GREEN
	body.material_override = mat
	visual_root.add_child(body)
	
	var head = MeshInstance3D.new()
	head.mesh = CylinderMesh.new()
	head.mesh.top_radius = 0.06
	head.mesh.bottom_radius = 0.06
	head.mesh.height = 0.05
	var hmat = StandardMaterial3D.new()
	hmat.albedo_color = Color.SILVER
	head.material_override = hmat
	head.position = Vector3(0, 0.1, 0)
	visual_root.add_child(head)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	
	if wielder:
		_deploy(wielder.global_position)

func _deploy(pos: Vector3) -> void:
	var obj = Area3D.new()
	obj.set_collision_layer_value(1, false)
	obj.set_collision_mask_value(2, true)
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = CylinderMesh.new()
	mesh_inst.mesh.top_radius = 0.2
	mesh_inst.mesh.bottom_radius = 0.3
	mesh_inst.mesh.height = 0.4
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.GREEN
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0, 0.2, 0)
	obj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	col.shape = CylinderShape3D.new()
	col.shape.radius = 5.0
	col.shape.height = 2.0
	col.position = Vector3(0, 1.0, 0)
	obj.add_child(col)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	
	var tick_timer = Timer.new()
	tick_timer.wait_time = 1.0
	tick_timer.autostart = true
	tick_timer.timeout.connect(func():
		var bodies = obj.get_overlapping_bodies()
		for body in bodies:
			if body != wielder and body.has_method("take_damage"):
				body.take_damage(3)
				if "move_speed" in body:
					body.move_speed *= 0.8
					wielder.get_tree().create_timer(1.0).timeout.connect(func():
						if is_instance_valid(body) and "move_speed" in body:
							body.move_speed /= 0.8
					)
	)
	obj.add_child(tick_timer)
	
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
