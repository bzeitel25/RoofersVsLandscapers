extends "res://scripts/weapons/base_tool.gd"

func _ready() -> void:
	tool_name = "Oil Slick"
	slot_type = 2
	cooldown = 8.0
	super._ready()
	
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.position = Vector3(0, 0, -0.3)
	
	var can_mesh = MeshInstance3D.new()
	can_mesh.mesh = CylinderMesh.new()
	can_mesh.mesh.top_radius = 0.1
	can_mesh.mesh.bottom_radius = 0.1
	can_mesh.mesh.height = 0.3
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.DARK_SLATE_GRAY
	can_mesh.material_override = mat
	visual_root.add_child(can_mesh)
	
	var spout = MeshInstance3D.new()
	spout.mesh = CylinderMesh.new()
	spout.mesh.top_radius = 0.02
	spout.mesh.bottom_radius = 0.02
	spout.mesh.height = 0.2
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color.SILVER
	spout.material_override = smat
	spout.position = Vector3(0, 0.15, -0.1)
	spout.rotation_degrees.x = -45
	visual_root.add_child(spout)

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
	mesh_inst.mesh.top_radius = 2.0
	mesh_inst.mesh.bottom_radius = 2.0
	mesh_inst.mesh.height = 0.05
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.BLACK
	mesh_inst.material_override = mat
	obj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	col.shape = CylinderShape3D.new()
	col.shape.radius = 2.0
	col.shape.height = 0.5
	col.position = Vector3(0, 0.25, 0)
	obj.add_child(col)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos + Vector3(0, 0.025, 0)
	
	obj.body_entered.connect(func(body: Node3D):
		if body != wielder and "velocity" in body:
			body.velocity *= 1.5
	)
	
	var timer = Timer.new()
	timer.wait_time = 8.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
