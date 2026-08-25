extends "res://scripts/weapons/base_tool.gd"

func _ready() -> void:
	tool_name = "Healing Flower"
	slot_type = 2
	cooldown = 12.0
	super._ready()
	
	var visual_root = Node3D.new()
	add_child(visual_root)
	visual_root.position = Vector3(0, 0, -0.3)
	
	var pot = MeshInstance3D.new()
	pot.mesh = CylinderMesh.new()
	pot.mesh.top_radius = 0.15
	pot.mesh.bottom_radius = 0.1
	pot.mesh.height = 0.3
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.SADDLE_BROWN
	pot.material_override = mat
	visual_root.add_child(pot)
	
	var flower = MeshInstance3D.new()
	flower.mesh = SphereMesh.new()
	flower.mesh.radius = 0.15
	flower.mesh.height = 0.3
	var fmat = StandardMaterial3D.new()
	fmat.albedo_color = Color.GREEN
	flower.material_override = fmat
	flower.position = Vector3(0, 0.2, 0)
	visual_root.add_child(flower)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	
	if wielder:
		_deploy(wielder.global_position)

func _deploy(pos: Vector3) -> void:
	var obj = Area3D.new()
	obj.set_collision_layer_value(1, false)
	obj.set_collision_mask_value(2, true)
	
	var pot = MeshInstance3D.new()
	pot.mesh = CylinderMesh.new()
	pot.mesh.top_radius = 0.3
	pot.mesh.bottom_radius = 0.2
	pot.mesh.height = 0.6
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.SADDLE_BROWN
	pot.material_override = mat
	pot.position = Vector3(0, 0.3, 0)
	obj.add_child(pot)
	
	var flower = MeshInstance3D.new()
	flower.mesh = SphereMesh.new()
	flower.mesh.radius = 0.4
	flower.mesh.height = 0.8
	var fmat = StandardMaterial3D.new()
	fmat.albedo_color = Color.GREEN
	flower.material_override = fmat
	flower.position = Vector3(0, 0.8, 0)
	obj.add_child(flower)
	
	var col = CollisionShape3D.new()
	col.shape = SphereShape3D.new()
	col.shape.radius = 4.0
	obj.add_child(col)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = pos
	
	var tick_timer = Timer.new()
	tick_timer.wait_time = 1.0
	tick_timer.autostart = true
	tick_timer.timeout.connect(func():
		var bodies = obj.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("heal"):
				body.heal(5)
	)
	obj.add_child(tick_timer)
	
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.timeout.connect(obj.queue_free)
	obj.add_child(timer)
	timer.start()
