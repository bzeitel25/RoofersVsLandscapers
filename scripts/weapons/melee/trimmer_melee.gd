class_name WeedWacker
extends BaseMelee

var visual_root: Node3D
var _is_revving: bool = false
var _rev_timer: float = 0.0

func _init() -> void:
	tool_name = "Weed Wacker"
	slot_type = 0
	damage = 5.0 # Low damage, but ticks rapidly
	cooldown = 0.1
	swing_duration = 0.1
	is_thrust = true

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	visual_root = Node3D.new()
	visual_root.rotation_degrees.x = -45 # Pointed down/forward
	add_child(visual_root)
	
	# Shaft
	var shaft = MeshInstance3D.new()
	var s_mesh = CylinderMesh.new()
	s_mesh.top_radius = 0.03
	s_mesh.bottom_radius = 0.03
	s_mesh.height = 1.2
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.1, 0.8, 0.2) # Green
	s_mesh.material = s_mat
	shaft.mesh = s_mesh
	shaft.position = Vector3(0, 0.6, 0)
	visual_root.add_child(shaft)
	
	# Head
	var head = MeshInstance3D.new()
	var h_mesh = CylinderMesh.new()
	h_mesh.top_radius = 0.15
	h_mesh.bottom_radius = 0.15
	h_mesh.height = 0.1
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.2, 0.2, 0.2)
	h_mesh.material = h_mat
	head.mesh = h_mesh
	head.position = Vector3(0, 1.2, 0)
	visual_root.add_child(head)

func primary_action() -> void:
	if not can_use() or not wielder: return
	_start_cooldown()
	_play_swing_animation()
	
	# Rapid short-range raycast
	var space_state = wielder.get_world_3d().direct_space_state
	var camera = wielder.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if not camera: return
	var start_pos = wielder.global_position + Vector3(0, 1.5, 0)
	var forward = -camera.global_transform.basis.z
	var end_pos = start_pos + (forward * 2.0)
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [wielder.get_rid()]
	query.collision_mask = 3
	var result = space_state.intersect_ray(query)
	if result and result.collider.has_method("take_damage"):
		result.collider.take_damage(damage, wielder.owning_peer_id if "owning_peer_id" in wielder else 1)

func alt_use_pressed(character: Node3D) -> void:
	if not can_use() or not wielder: return
	
	if wielder.has_method("consume_supplies"):
		wielder.consume_supplies(5) # Costs gas
		
	# Over-rev Dash!
	cooldown = 2.0
	_start_cooldown()
	
	var camera = wielder.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if not camera: return
	var forward = -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	# Launch player
	if wielder.has_method("apply_impulse"):
		wielder.apply_impulse(forward * 25.0)
	elif "velocity" in wielder:
		wielder.velocity = forward * 25.0
		
	# Do a big AoE strike at the end of the dash (simulated here by a large raycast)
	var space_state = wielder.get_world_3d().direct_space_state
	var start_pos = wielder.global_position + Vector3(0, 1.0, 0)
	var end_pos = start_pos + (forward * 3.0)
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [wielder.get_rid()]
	query.collision_mask = 3
	var result = space_state.intersect_ray(query)
	if result and result.collider.has_method("take_damage"):
		result.collider.take_damage(40.0, wielder.owning_peer_id if "owning_peer_id" in wielder else 1)
