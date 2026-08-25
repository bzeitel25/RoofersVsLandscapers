extends "res://scripts/weapons/base_tool.gd"

var visual_root: Node3D
var active_traps: Array = []

func _init() -> void:
	tool_name = "Tesla Coil"
	slot_type = 2
	cooldown = 10.0
	damage = 10.0

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var coil = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = 0.1
	mesh.height = 0.3
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.8, 0.1)
	mesh.material = mat
	coil.mesh = mesh
	coil.position = Vector3(0, 0, -0.2)
	visual_root.add_child(coil)
	
	var stripe = MeshInstance3D.new()
	var stripe_mesh = CylinderMesh.new()
	stripe_mesh.top_radius = 0.085
	stripe_mesh.bottom_radius = 0.105
	stripe_mesh.height = 0.05
	var stripe_mat = StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.1, 0.1, 0.1)
	stripe_mesh.material = stripe_mat
	stripe.mesh = stripe_mesh
	coil.add_child(stripe)

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
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.2
	mesh.bottom_radius = 0.3
	mesh.height = 1.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.8, 0.1)
	mesh.material = mat
	mesh_inst.mesh = mesh
	mesh_inst.position = Vector3(0, 0.5, 0)
	obj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 3.0
	shape.height = 2.0
	col.shape = shape
	col.position = Vector3(0, 1.0, 0)
	obj.add_child(col)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	
	var zap_timer = Timer.new()
	zap_timer.wait_time = 1.0
	zap_timer.autostart = true
	zap_timer.timeout.connect(func(): _zap_enemies(obj))
	obj.add_child(zap_timer)
	
	var life_timer = Timer.new()
	life_timer.wait_time = 8.0
	life_timer.one_shot = true
	life_timer.timeout.connect(obj.queue_free)
	obj.add_child(life_timer)
	life_timer.start()

func _zap_enemies(trap_area: Area3D) -> void:
	for body in trap_area.get_overlapping_bodies():
		if body != wielder and body.has_method("take_damage"):
			body.take_damage(damage)
