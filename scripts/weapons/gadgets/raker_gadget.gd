extends "res://scripts/weapons/base_tool.gd"

func _ready() -> void:
	tool_name = "Leaf Pile"
	slot_type = 2
	cooldown = 12.0
	super._ready()
	
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.position = Vector3(0, 0, -0.3)
	
	var sack = MeshInstance3D.new()
	sack.mesh = CylinderMesh.new()
	sack.mesh.top_radius = 0.1
	sack.mesh.bottom_radius = 0.15
	sack.mesh.height = 0.4
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.SADDLE_BROWN
	sack.material_override = mat
	visual_root.add_child(sack)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	
	if wielder:
		_deploy(wielder.global_position)

func _deploy(pos: Vector3) -> void:
	var obj = Node3D.new()
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = SphereMesh.new()
	mesh_inst.mesh.radius = 1.5
	mesh_inst.mesh.height = 1.5
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.3, 0.1) # Brownish
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0, 0.75, 0)
	obj.add_child(mesh_inst)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
