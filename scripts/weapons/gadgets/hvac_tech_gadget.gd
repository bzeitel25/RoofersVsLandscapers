extends "res://scripts/weapons/base_tool.gd"

var visual_root: Node3D

func _init() -> void:
	tool_name = "Freeze Mine"
	slot_type = 2
	cooldown = 10.0

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var canister = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = 0.08
	mesh.height = 0.15
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.9)
	mesh.material = mat
	canister.mesh = mesh
	canister.position = Vector3(0, 0, -0.2)
	visual_root.add_child(canister)

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
	var sphere = SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.9)
	sphere.material = mat
	mesh_inst.mesh = sphere
	mesh_inst.position = Vector3(0, 0.2, 0)
	obj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 2.0
	col.shape = shape
	col.position = Vector3(0, 0.5, 0)
	obj.add_child(col)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	
	obj.body_entered.connect(func(body): _on_body_entered(body, obj))
	
	var timer = Timer.new()
	timer.wait_time = 30.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()

func _on_body_entered(body: Node3D, mine_obj: Area3D) -> void:
	if body != wielder and (body.has_method("take_damage") or body.has_method("apply_slow")):
		mine_obj.queue_free()
		# Applying visual/effect freeze concept
		if body.has_method("apply_slow"):
			body.apply_slow(0.3, 3.0)
