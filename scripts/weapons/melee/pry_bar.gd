class_name PryBar
extends "res://scripts/weapons/melee/base_melee.gd"

func _ready() -> void:
	tool_name = "Pry Bar"
	damage = 25.0
	cooldown = 0.8
	swing_duration = 0.3
	knockback_multiplier = 2.5
	stun_chance = 0.1
	swing_angle = 90.0
	is_thrust = false # It's a heavy sweeping arc
	
	super._ready()
	
	# Remove default base mesh if any, and build a composite mesh
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.1, 0.1) # Red metal
	mat.metallic = 0.5
	mat.roughness = 0.4
			
	var visual_root = Node3D.new()
	visual_root.rotation_degrees.x = 0 # Angled forward like a heavy swinging tool
	add_child(visual_root)
	
	# Shaft
	var shaft = MeshInstance3D.new()
	var s_mesh = CylinderMesh.new()
	s_mesh.top_radius = 0.03
	s_mesh.bottom_radius = 0.03
	s_mesh.height = 1.05 # 1.5x
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.1, 0.1, 0.1) # Black/Dark grey metal
	s_mat.metallic = 0.7
	s_mat.roughness = 0.4
	s_mesh.material = s_mat
	shaft.mesh = s_mesh
	shaft.position = Vector3(0, 0.525, 0)
	visual_root.add_child(shaft)
	
	# Hook at the top
	var hook = MeshInstance3D.new()
	var h_mesh = BoxMesh.new()
	h_mesh.size = Vector3(0.045, 0.045, 0.225)
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.8, 0.2, 0.2) # Red tip
	h_mat.metallic = 0.5
	h_mesh.material = h_mat
	hook.mesh = h_mesh
	hook.position = Vector3(0, 1.05, 0.075) # Positioned at the top, jutting forward
	hook.rotation_degrees = Vector3(15, 0, 0) # Slight angle
	visual_root.add_child(hook)

func alt_use_pressed(character: Node3D) -> void:
	if not can_use() or not wielder: return
	
	_start_cooldown()
	_play_swing_animation()
	
	# Raycast for the alt-fire (similar to melee strike but shorter/more precise)
	var camera = wielder.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if not camera: return
	
	var space_state = wielder.get_world_3d().direct_space_state
	var forward = -camera.global_transform.basis.z
	var start_pos = wielder.global_position + Vector3(0, 1.5, 0)
	var end_pos = start_pos + (forward * range_dist * 1.2) # Slightly longer reach for the hook
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [wielder.get_rid()]
	query.collision_mask = 3
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		if collider.has_method("take_damage"):
			if collider.has_method("consume_stuck_nails"):
				var nails = collider.consume_stuck_nails()
				if nails > 0:
					# NAIL PULLER SYNERGY!
					var burst = nails * 15.0
					print("Nail Puller! Ripped out ", nails, " nails for ", burst, " bonus damage!")
					collider.take_damage(damage + burst, wielder.owning_peer_id if "owning_peer_id" in wielder else 1)
					
					# Spawn a blood/metal burst effect here in the future
				else:
					# Standard hit if no nails
					collider.take_damage(damage * 0.5, wielder.owning_peer_id if "owning_peer_id" in wielder else 1)
			else:
				# Deconstructor synergy placeholder for gadgets
				collider.take_damage(damage * 3.0, wielder.owning_peer_id if "owning_peer_id" in wielder else 1)
