extends "res://scripts/weapons/base_tool.gd"

func _ready() -> void:
	tool_name = "Grapple Point"
	slot_type = 2
	cooldown = 8.0
	super._ready()
	
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.position = Vector3(0, 0, -0.3)
	
	var hook = MeshInstance3D.new()
	hook.mesh = CylinderMesh.new()
	hook.mesh.top_radius = 0.05
	hook.mesh.bottom_radius = 0.05
	hook.mesh.height = 0.2
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.SILVER
	hook.material_override = mat
	hook.rotation_degrees.x = 90
	visual_root.add_child(hook)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	
	if wielder and wielder.camera:
		var cam = wielder.camera
		var space = wielder.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position + (-cam.global_transform.basis.z * 15.0))
		var result = space.intersect_ray(query)
		
		if result:
			_deploy(result.position, result.normal)

func _deploy(pos: Vector3, normal: Vector3) -> void:
	var obj = StaticBody3D.new()
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = CylinderMesh.new()
	mesh_inst.mesh.top_radius = 0.2
	mesh_inst.mesh.bottom_radius = 0.2
	mesh_inst.mesh.height = 0.4
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.SILVER
	mesh_inst.material_override = mat
	mesh_inst.rotation_degrees.x = 90
	obj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	col.shape = CylinderShape3D.new()
	col.shape.radius = 0.2
	col.shape.height = 0.4
	col.rotation_degrees.x = 90
	obj.add_child(col)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	if normal != Vector3.UP and normal != Vector3.DOWN:
		obj.look_at(pos + normal, Vector3.UP)
	
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
