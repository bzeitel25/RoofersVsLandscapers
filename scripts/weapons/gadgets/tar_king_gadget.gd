extends "res://scripts/weapons/base_tool.gd"

var visual_root: Node3D

func _init() -> void:
	tool_name = "Tar Puddle"
	slot_type = 2
	cooldown = 6.0

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var bucket = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.15
	mesh.bottom_radius = 0.1
	mesh.height = 0.3
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.1)
	mesh.material = mat
	bucket.mesh = mesh
	bucket.position = Vector3(0, 0, -0.2)
	visual_root.add_child(bucket)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	if not wielder:
		return
	var deploy_pos = wielder.global_position
	_deploy(deploy_pos)

func _deploy(pos: Vector3) -> void:
	var obj = Area3D.new()
	var mesh_inst = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 2.0
	cyl.bottom_radius = 2.0
	cyl.height = 0.1
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.05, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cyl.material = mat
	mesh_inst.mesh = cyl
	obj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 2.0
	shape.height = 0.5
	col.shape = shape
	obj.add_child(col)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos + Vector3(0, 0.05, 0)
	
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
