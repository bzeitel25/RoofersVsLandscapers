extends "res://scripts/weapons/base_tool.gd"

var visual_root: Node3D

func _init() -> void:
	tool_name = "Shingle Shield"
	slot_type = 2
	cooldown = 5.0

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var stack = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.3, 0.2, 0.3)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	mesh.material = mat
	stack.mesh = mesh
	stack.position = Vector3(0, 0, -0.2)
	visual_root.add_child(stack)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	if not wielder:
		return
	
	var forward = -wielder.global_transform.basis.z
	var deploy_pos = wielder.global_position + forward * 1.5
	_deploy(deploy_pos, forward)

func _deploy(pos: Vector3, forward: Vector3) -> void:
	var obj = StaticBody3D.new()
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 1.5, 0.3)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	box.material = mat
	mesh_inst.mesh = box
	mesh_inst.position = Vector3(0, 0.75, 0)
	obj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	col.position = Vector3(0, 0.75, 0)
	obj.add_child(col)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	var flat_forward = Vector3(forward.x, 0, forward.z).normalized()
	if flat_forward.length_squared() > 0.001:
		obj.look_at(pos + flat_forward, Vector3.UP)
	
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
