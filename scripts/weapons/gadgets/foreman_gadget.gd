extends "res://scripts/weapons/base_tool.gd"

var visual_root: Node3D

func _init() -> void:
	tool_name = "Blueprint Barrier"
	slot_type = 2
	cooldown = 8.0

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
	
	var space_state = wielder.get_world_3d().direct_space_state
	
	# Get the player's flat forward direction
	var forward = -wielder.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
		
	# Target a position 3 meters in front of the player
	var target_pos = wielder.global_position + (forward * 3.0)
	
	# Raycast straight down from slightly above that point to snap to the floor
	var ray_start = target_pos + Vector3(0, 1.5, 0)
	var ray_end = target_pos + Vector3(0, -5.0, 0)
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [wielder.get_rid()]
	query.collision_mask = 1 # Environment layer
	var result = space_state.intersect_ray(query)
	
	var deploy_pos = target_pos
	if result:
		deploy_pos = result.position
	
	_deploy(deploy_pos, forward)

func _deploy(pos: Vector3, forward: Vector3) -> void:
	var obj = StaticBody3D.new()
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
		obj.look_at(pos + forward, Vector3.UP)
	
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
