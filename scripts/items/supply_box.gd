extends Area3D

@export var ammo_restored_percent: float = 1.0 # 100% by default
@export var supplies_restored: int = 50

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Only detect players (Layer 2)
	
	# Visual Box
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.5, 0.4, 0.5)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 0.2) # Green ammo box
	box.material = mat
	mesh_inst.mesh = box
	mesh_inst.position = Vector3(0, 0.2, 0)
	add_child(mesh_inst)
	
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
		
	var used = false
	
	# Restore Ammo to all ranged weapons in inventory
	if "loadout_manager" in body and body.loadout_manager:
		for tool in body.loadout_manager._slots:
			if tool and tool.max_ammo > 0:
				if tool.current_ammo < tool.max_ammo:
					tool.current_ammo = tool.max_ammo # Refill to max
					print("Refilled Ammo for ", tool.tool_name)
					used = true
	
	# Restore utility supplies
	if "supplies" in body and "max_supplies" in body:
		if body.supplies < body.max_supplies:
			body.supplies = min(body.max_supplies, body.supplies + supplies_restored)
			print("Refilled Supplies! Now at: ", body.supplies)
			used = true
			
	if used:
		# Play a sound here eventually
		print("Picked up Universal Supply Box!")
		queue_free()
