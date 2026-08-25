extends "res://scripts/weapons/base_tool.gd"

func _ready() -> void:
	tool_name = "Recon Drone"
	slot_type = 2
	cooldown = 15.0
	super._ready()
	
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.position = Vector3(0, 0, -0.3)
	
	var controller = MeshInstance3D.new()
	controller.mesh = BoxMesh.new()
	controller.mesh.size = Vector3(0.3, 0.1, 0.2)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.BLACK
	controller.material_override = mat
	visual_root.add_child(controller)
	
	var stick = MeshInstance3D.new()
	stick.mesh = CylinderMesh.new()
	stick.mesh.top_radius = 0.02
	stick.mesh.bottom_radius = 0.02
	stick.mesh.height = 0.1
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color.DARK_GRAY
	stick.material_override = smat
	stick.position = Vector3(0.1, 0.05, 0)
	visual_root.add_child(stick)
	
	var stick2 = stick.duplicate()
	stick2.position = Vector3(-0.1, 0.05, 0)
	visual_root.add_child(stick2)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	
	if wielder:
		_deploy(wielder.global_position + Vector3(0, 5, 0))

func _deploy(pos: Vector3) -> void:
	var obj = Area3D.new()
	obj.set_collision_layer_value(1, false)
	obj.set_collision_mask_value(2, true)
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = BoxMesh.new()
	mesh_inst.mesh.size = Vector3(0.5, 0.2, 0.5)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mesh_inst.material_override = mat
	obj.add_child(mesh_inst)
	
	var prop1 = MeshInstance3D.new()
	prop1.mesh = CylinderMesh.new()
	prop1.mesh.top_radius = 0.15
	prop1.mesh.bottom_radius = 0.15
	prop1.mesh.height = 0.02
	var pmat = StandardMaterial3D.new()
	pmat.albedo_color = Color.DARK_GRAY
	prop1.material_override = pmat
	prop1.position = Vector3(0.25, 0.1, 0.25)
	obj.add_child(prop1)
	
	var prop2 = prop1.duplicate()
	prop2.position = Vector3(-0.25, 0.1, 0.25)
	obj.add_child(prop2)
	var prop3 = prop1.duplicate()
	prop3.position = Vector3(0.25, 0.1, -0.25)
	obj.add_child(prop3)
	var prop4 = prop1.duplicate()
	prop4.position = Vector3(-0.25, 0.1, -0.25)
	obj.add_child(prop4)
	
	var col = CollisionShape3D.new()
	col.shape = SphereShape3D.new()
	col.shape.radius = 15.0 # Detection radius
	obj.add_child(col)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	
	var tick_timer = Timer.new()
	tick_timer.wait_time = 1.0
	tick_timer.autostart = true
	tick_timer.timeout.connect(func():
		obj.rotation_degrees.y += 45
		var bodies = obj.get_overlapping_bodies()
		for body in bodies:
			if body != wielder and body.has_method("spot"):
				body.spot()
	)
	obj.add_child(tick_timer)
	
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
