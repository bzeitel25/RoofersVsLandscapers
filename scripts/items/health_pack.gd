extends Area3D

@export var heal_amount: float = 50.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Only detect players (Layer 2)
	
	# Visual Box
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.4, 0.4, 0.4)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.2, 0.2) # Red health pack
	box.material = mat
	mesh_inst.mesh = box
	mesh_inst.position = Vector3(0, 0.2, 0)
	add_child(mesh_inst)
	
	# Medical Cross
	var cross1 = MeshInstance3D.new()
	var c_mesh1 = BoxMesh.new()
	c_mesh1.size = Vector3(0.1, 0.2, 0.42)
	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_color = Color.WHITE
	c_mesh1.material = c_mat
	cross1.mesh = c_mesh1
	cross1.position = Vector3(0, 0.2, 0)
	add_child(cross1)
	
	var cross2 = MeshInstance3D.new()
	var c_mesh2 = BoxMesh.new()
	c_mesh2.size = Vector3(0.42, 0.2, 0.1)
	c_mesh2.material = c_mat
	cross2.mesh = c_mesh2
	cross2.position = Vector3(0, 0.2, 0)
	add_child(cross2)
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.6, 0.6, 0.6)
	col.shape = shape
	col.position = Vector3(0, 0.3, 0)
	add_child(col)
	
	body_entered.connect(_on_body_entered)
	
	# Slowly rotate
	var tween = create_tween().set_loops()
	tween.tween_property(self, "rotation_degrees:y", 360.0, 3.0).as_relative()

func _on_body_entered(body: Node3D) -> void:
	if not body.has_method("_is_local_player"):
		return
		
	if body.has_method("heal") and "health" in body and "max_health" in body:
		if body.health < body.max_health:
			body.heal(heal_amount)
			print("Picked up Health Pack!")
			queue_free()
