extends "res://scripts/weapons/base_tool.gd"

var visual_root: Node3D

func _init() -> void:
	tool_name = "Spotter Scope"
	slot_type = 2
	cooldown = 10.0

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var camera_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.1, 0.1, 0.2)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.1)
	mesh.material = mat
	camera_mesh.mesh = mesh
	camera_mesh.position = Vector3(0, 0, -0.2)
	visual_root.add_child(camera_mesh)
	
	var lens = MeshInstance3D.new()
	var lens_mesh = CylinderMesh.new()
	lens_mesh.top_radius = 0.04
	lens_mesh.bottom_radius = 0.04
	lens_mesh.height = 0.05
	var lens_mat = StandardMaterial3D.new()
	lens_mat.albedo_color = Color(0.2, 0.8, 1.0)
	lens_mesh.material = lens_mat
	lens.mesh = lens_mesh
	lens.position = Vector3(0, 0, -0.32)
	lens.rotation_degrees = Vector3(90, 0, 0)
	visual_root.add_child(lens)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	if not wielder:
		return
	
	var deploy_pos = wielder.global_position
	var forward = -wielder.global_transform.basis.z
	_deploy(deploy_pos, forward)

func _deploy(pos: Vector3, forward: Vector3) -> void:
	var obj = Node3D.new()
	
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.2, 0.2, 0.4)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.1)
	box.material = mat
	mesh_inst.mesh = box
	mesh_inst.position = Vector3(0, 0.5, 0)
	obj.add_child(mesh_inst)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	var flat_forward = Vector3(forward.x, 0, forward.z).normalized()
	if flat_forward.length_squared() > 0.001:
		obj.look_at(pos + flat_forward, Vector3.UP)
	
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
