extends "res://scripts/weapons/base_tool.gd"

func _ready() -> void:
	tool_name = "Bear Trap"
	slot_type = 2
	cooldown = 10.0
	super._ready()
	
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.position = Vector3(0, 0, -0.3)
	
	var base_mesh = MeshInstance3D.new()
	base_mesh.mesh = BoxMesh.new()
	base_mesh.mesh.size = Vector3(0.4, 0.05, 0.4)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.DARK_GRAY
	base_mesh.material_override = mat
	visual_root.add_child(base_mesh)
	
	var teeth = MeshInstance3D.new()
	teeth.mesh = BoxMesh.new()
	teeth.mesh.size = Vector3(0.3, 0.1, 0.3)
	var mat2 = StandardMaterial3D.new()
	mat2.albedo_color = Color.LIGHT_GRAY
	teeth.material_override = mat2
	teeth.position = Vector3(0, 0.05, 0)
	visual_root.add_child(teeth)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	
	if wielder:
		_deploy(wielder.global_position)

func _deploy(pos: Vector3) -> void:
	var obj = Area3D.new()
	obj.set_collision_layer_value(1, false)
	obj.set_collision_layer_value(3, true)
	obj.set_collision_mask_value(2, true)
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = BoxMesh.new()
	mesh_inst.mesh.size = Vector3(1.0, 0.2, 1.0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.DARK_GRAY
	mesh_inst.material_override = mat
	obj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(1.0, 0.2, 1.0)
	obj.add_child(col)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	
	obj.body_entered.connect(func(body: Node3D):
		if body.has_method("take_damage") and body != wielder:
			body.take_damage(20)
			if "velocity" in body:
				body.velocity = Vector3.ZERO
			obj.queue_free()
	)
