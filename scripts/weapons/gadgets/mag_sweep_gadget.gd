extends "res://scripts/weapons/base_tool.gd"

var visual_root: Node3D
var _active_plates: Array[StaticBody3D] = []

func _init() -> void:
	tool_name = "Mag-Plates"
	slot_type = 2 # Gadget
	cooldown = 4.0 # Faster cooldown so he can build paths
	supply_cost = 10

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	add_child(visual_root)
	
	# Gadget held in hand (looks like a remote or a stack of plates)
	var box = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.2, 0.05, 0.3)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.6, 0.7)
	mat.metallic = 0.8
	mesh.material = mat
	box.mesh = mesh
	box.position = Vector3(0, 0, -0.2)
	visual_root.add_child(box)

func primary_action() -> void:
	if not can_use(): return
	if not wielder: return
	
	# Deploy the platform
	_deploy_platform()
	_start_cooldown()

func alt_use(character: Node3D) -> void:
	# Instantly destroy all active platforms to drop enemies
	if _active_plates.size() > 0:
		print("Detonating Mag-Plates!")
		for plate in _active_plates:
			if is_instance_valid(plate):
				plate.queue_free()
		_active_plates.clear()

func _deploy_platform() -> void:
	var camera = wielder.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	var deploy_pos = wielder.global_position
	
	if camera:
		var space_state = wielder.get_world_3d().direct_space_state
		var forward = -camera.global_transform.basis.z
		var start = camera.global_position
		var end = start + forward * 4.0 # Max deploy distance
		
		var query = PhysicsRayQueryParameters3D.create(start, end)
		query.exclude = [wielder.get_rid()]
		var result = space_state.intersect_ray(query)
		
		if result:
			deploy_pos = result.position
		else:
			deploy_pos = end
	else:
		deploy_pos += Vector3(0, -0.5, -2.0) # Fallback if no camera
	
	var obj = StaticBody3D.new()
	# Layer 1 (World) so players can collide and walk on it
	obj.collision_layer = 1
	obj.collision_mask = 0
	
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.5, 0.1, 2.5) # Large enough to stand on comfortably
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.25) # Dark metal
	mat.metallic = 1.0
	box.material = mat
	mesh_inst.mesh = box
	obj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	obj.add_child(col)
	
	wielder.get_tree().current_scene.add_child(obj)
	obj.global_position = deploy_pos
	
	# Flatten it to the world XZ plane, regardless of look angle
	obj.rotation_degrees = Vector3.ZERO
	
	# Optional: Give it a slight pulse or light? Just keeping it solid for now.
	
	_active_plates.append(obj)
	
	# Auto-destroy after 15 seconds if not manually destroyed
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.one_shot = true
	timer.timeout.connect(func():
		if is_instance_valid(obj):
			_active_plates.erase(obj)
			obj.queue_free()
	)
	obj.add_child(timer)
	timer.start()

func drop() -> void:
	# Destroy plates if dropped or unequipped? 
	# Let's let them persist until timeout or alt-fire.
	super.drop()
