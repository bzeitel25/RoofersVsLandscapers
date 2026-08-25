extends BaseMelee

var visual_root: Node3D

func _init() -> void:
	tool_name = "Felling Axe"
	slot_type = 0
	damage = 30.0
	cooldown = 1.0
	bleed_chance = 0.25 # 25% chance to bleed
	swing_duration = 0.4
	swing_angle = 120.0
	is_thrust = false

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	visual_root.rotation_degrees.x = 0
	add_child(visual_root)
	
	var handle_mesh = CylinderMesh.new()
	handle_mesh.top_radius = 0.05
	handle_mesh.bottom_radius = 0.05
	handle_mesh.height = 1.2
	var handle = MeshInstance3D.new()
	handle.mesh = handle_mesh
	handle.position = Vector3(0, 0.6, 0)
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.4, 0.2, 0.1)
	handle.material_override = handle_mat
	visual_root.add_child(handle)
	
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.4, 0.3, 0.1)
	var head = MeshInstance3D.new()
	head.mesh = head_mesh
	head.position = Vector3(0.15, 1.1, 0)
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.2, 0.2, 0.2)
	head_mat.metallic = 0.8
	head.material_override = head_mat
	visual_root.add_child(head)

func alt_use_pressed(character: Node3D) -> void:
	if not can_use() or not wielder: return
	
	cooldown = 2.5
	_start_cooldown()
	
	# Rotate visually for an overhead slam
	visual_root.rotation_degrees.z = -45
	var tween = create_tween()
	tween.tween_property(visual_root, "rotation_degrees:x", 90.0, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_callback(_apply_timber_slam)
	tween.tween_property(visual_root, "rotation_degrees", Vector3.ZERO, 0.3)
	
func _apply_timber_slam() -> void:
	if not wielder: return
	var space_state = wielder.get_world_3d().direct_space_state
	var camera = wielder.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if not camera: return
	
	var start_pos = wielder.global_position + Vector3(0, 1.5, 0)
	var forward = -camera.global_transform.basis.z
	var end_pos = start_pos + (forward * 2.5) # Heavy reach
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [wielder.get_rid()]
	query.collision_mask = 3
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		if collider.has_method("take_damage"):
			# If it's a player, deal heavy damage
			if collider.is_in_group("players") or collider.name == "Player":
				collider.take_damage(damage * 1.5, wielder.owning_peer_id if "owning_peer_id" in wielder else 1)
			else:
				# Timber! Instantly shatter gadgets (like the Prybar Deconstructor)
				collider.take_damage(999.0, wielder.owning_peer_id if "owning_peer_id" in wielder else 1)
		print("TIMBER! Slammed ", collider.name)
