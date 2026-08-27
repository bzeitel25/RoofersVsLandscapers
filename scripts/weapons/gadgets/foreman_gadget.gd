extends "res://scripts/weapons/base_tool.gd"

var visual_root: Node3D
const SHIELD_SCRIPT = preload("res://scripts/weapons/gadgets/foreman_shield.gd")

func _init() -> void:
	tool_name = "Blueprint Barrier"
	slot_type = 2
	cooldown = 1.5
	max_ammo = 3 # 3 Charges
	supply_cost = 33 # Consumes ~1/3 of max supplies (100) per charge

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var tube = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.05
	mesh.bottom_radius = 0.05
	mesh.height = 0.4
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.8)
	mesh.material = mat
	tube.mesh = mesh
	tube.position = Vector3(0, 0, -0.2)
	tube.rotation_degrees = Vector3(90, 0, 0)
	visual_root.add_child(tube)

func primary_action() -> void:
	if not can_use(): return
	if not wielder: return
	
	_start_cooldown()
	print("Placed Glass Shield. Charges left: ", current_ammo)
	
	var space_state = wielder.get_world_3d().direct_space_state
	
	# Flat forward for placement logic based on CAMERA direction
	var forward = -wielder.camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
		
	# First, raycast straight from the camera to see if we are looking AT a shield to stack on
	var cam_pos = wielder.camera.global_position
	var cam_forward = -wielder.camera.global_transform.basis.z
	var query_cam = PhysicsRayQueryParameters3D.create(cam_pos, cam_pos + cam_forward * 6.0)
	query_cam.exclude = [wielder.get_rid()]
	query_cam.collision_mask = 1 | 2 | 4 | 8
	var cam_result = space_state.intersect_ray(query_cam)
	
	var deploy_pos = wielder.global_position + (forward * 3.0)
	var face_direction = forward
	
	if cam_result and cam_result.collider.is_in_group("foreman_shield"):
		# Stack exactly on top of the targeted shield!
		deploy_pos = cam_result.collider.global_position + Vector3(0, 2.0, 0)
		face_direction = -cam_result.collider.global_transform.basis.z # Match its rotation
	else:
		# Did not hit a shield, standard floor snap placement
		var ray_start = deploy_pos + Vector3(0, 1.5, 0)
		var ray_end = deploy_pos + Vector3(0, -5.0, 0)
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		query.exclude = [wielder.get_rid()]
		query.collision_mask = 1 # Environment layer
		var result = space_state.intersect_ray(query)
		if result:
			deploy_pos = result.position
	
	_deploy(deploy_pos, face_direction)

func _deploy(pos: Vector3, forward: Vector3) -> void:
	var obj = SHIELD_SCRIPT.new()
	obj.add_to_group("foreman_shield")
	
	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(3.0, 2.0, 0.2)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.8, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box_mesh.material = mat
	mesh_inst.mesh = box_mesh
	mesh_inst.position = Vector3(0, 1.0, 0) # Offset so bottom is at 'pos'
	obj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = box_mesh.size
	col.shape = shape
	col.position = Vector3(0, 1.0, 0)
	obj.add_child(col)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	
	# Face the barrier perpendicular to the forward vector
	if forward.length_squared() > 0.001:
		var target_look = pos + forward
		target_look.y = pos.y # Prevent pitching up/down
		obj.look_at(target_look, Vector3.UP)
	
	var timer = Timer.new()
	timer.wait_time = 30.0 # Lasts 30 seconds
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
