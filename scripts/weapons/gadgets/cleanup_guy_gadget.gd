extends "res://scripts/weapons/base_tool.gd"

var visual_root: Node3D

func _init() -> void:
	tool_name = "Smoke Bomb"
	slot_type = 2
	cooldown = 8.0

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var canister = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.05
	mesh.bottom_radius = 0.05
	mesh.height = 0.15
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.5)
	mesh.material = mat
	canister.mesh = mesh
	canister.position = Vector3(0, 0, -0.2)
	visual_root.add_child(canister)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	if not wielder or not wielder.camera:
		return
	
	var space_state = wielder.get_world_3d().direct_space_state
	var cam_pos = wielder.camera.global_position
	var forward = -wielder.camera.global_transform.basis.z
	var end_pos = cam_pos + forward * 10.0
	
	var query = PhysicsRayQueryParameters3D.create(cam_pos, end_pos)
	query.exclude = [wielder.get_rid()]
	var result = space_state.intersect_ray(query)
	
	var deploy_pos = end_pos
	if result:
		deploy_pos = result.position
	
	_deploy(deploy_pos)

func _deploy(pos: Vector3) -> void:
	var obj = Node3D.new()
	
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 4.0
	sphere.height = 8.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.7, 0.7, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_unshaded = true
	sphere.material = mat
	mesh_inst.mesh = sphere
	obj.add_child(mesh_inst)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
