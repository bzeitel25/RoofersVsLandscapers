extends CharacterBody3D

@export var max_health: float = 300.0
var health: float = 300.0
var driver: Node3D = null

var drive_speed: float = 20.0 # Fast! Rocket mower!
var turn_speed: float = 4.0

var visual_root: Node3D

func _ready() -> void:
	health = max_health
	
	# Let's set collision layers
	collision_layer = 1 | 8 | 64 # Layer 1 (World) + Layer 4 (Vehicles) + Layer 7 (Interactable)
	collision_mask = 1 | 2 # Collide with World and Players
	
	_build_mesh()

func _build_mesh() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	
	# Main Chassis (Red box)
	var chassis = MeshInstance3D.new()
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(1.2, 0.6, 1.8)
	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_color = Color(0.8, 0.1, 0.1) # Bright red
	c_mesh.material = c_mat
	chassis.mesh = c_mesh
	chassis.position = Vector3(0, 0.5, 0)
	visual_root.add_child(chassis)
	
	# Rocket Engine on back
	var engine = MeshInstance3D.new()
	var e_mesh = CylinderMesh.new()
	e_mesh.top_radius = 0.2
	e_mesh.bottom_radius = 0.4
	e_mesh.height = 0.6
	var e_mat = StandardMaterial3D.new()
	e_mat.albedo_color = Color(0.2, 0.2, 0.2)
	e_mesh.material = e_mat
	engine.mesh = e_mesh
	engine.rotation_degrees.x = 90
	engine.position = Vector3(0, 0.6, 1.0)
	visual_root.add_child(engine)
	
	# Seat
	var seat = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(0.6, 0.1, 0.6)
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color.BLACK
	s_mesh.material = s_mat
	seat.mesh = s_mesh
	seat.position = Vector3(0, 0.85, 0.2)
	visual_root.add_child(seat)
	
	# Wheels
	var w_mesh = CylinderMesh.new()
	w_mesh.top_radius = 0.3
	w_mesh.bottom_radius = 0.3
	w_mesh.height = 0.2
	for pos in [Vector3(0.7, 0.3, -0.6), Vector3(-0.7, 0.3, -0.6), Vector3(0.7, 0.3, 0.6), Vector3(-0.7, 0.3, 0.6)]:
		var wheel = MeshInstance3D.new()
		wheel.mesh = w_mesh
		wheel.material_override = s_mat
		wheel.rotation_degrees.z = 90
		wheel.position = pos
		visual_root.add_child(wheel)
		
	# Collision
	var col = CollisionShape3D.new()
	var col_shape = BoxShape3D.new()
	col_shape.size = Vector3(1.4, 0.8, 2.0)
	col.shape = col_shape
	col.position = Vector3(0, 0.5, 0)
	add_child(col)

func interact(player: Node3D) -> void:
	if driver != null:
		return # Already occupied
		
	driver = player
	if player.has_method("enter_vehicle"):
		player.enter_vehicle(self)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta # Gravity
		
	var speed_mult = 1.0
	
	if driver and driver.has_method("_is_local_player") and driver._is_local_player():
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		
		# Zero-turn style steering
		if input_dir.y < 0: # Moving forward
			rotate_y(-input_dir.x * turn_speed * delta)
		elif input_dir.y > 0: # Reversing
			rotate_y(input_dir.x * turn_speed * delta)
		else:
			rotate_y(-input_dir.x * turn_speed * delta)
			
		# Rocket Boost on Sprint (Shift)
		if Input.is_action_pressed("sprint"):
			speed_mult = 2.0
			
		var forward = -transform.basis.z
		velocity.x = forward.x * -input_dir.y * drive_speed * speed_mult
		velocity.z = forward.z * -input_dir.y * drive_speed * speed_mult
		
		# Run over people logic
		if velocity.length() > 5.0:
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				var body = collision.get_collider()
				if body and body != driver and body.has_method("take_damage"):
					body.take_damage(30.0 * delta * speed_mult, driver.owning_peer_id if "owning_peer_id" in driver else 1)
					
	else:
		# Decelerate if empty
		velocity.x = move_toward(velocity.x, 0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 10.0 * delta)
		
	move_and_slide()

func take_damage(amount: float, from_peer_id: int = 1) -> void:
	health -= amount
	print("Mower took damage! HP: ", health)
	if health <= 0:
		explode()

func explode() -> void:
	print("ROCKET MOWER EXPLODED!")
	
	if driver and driver.has_method("exit_vehicle"):
		driver.exit_vehicle(true) # True = ejected
		
	# Deal 25% max HP damage to nearby entities
	var blast_radius = Area3D.new()
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 6.0
	col.shape = shape
	blast_radius.add_child(col)
	get_tree().current_scene.add_child(blast_radius)
	blast_radius.global_position = global_position
	
	# Wait for physics update to get overlaps
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var bodies = blast_radius.get_overlapping_bodies()
	for b in bodies:
		if b.has_method("take_damage") and "max_health" in b:
			print("Caught in explosion: ", b.name)
			b.take_damage(b.max_health * 0.25, 1)
			
	blast_radius.queue_free()
	
	# Spawn a visual explosion sphere
	var vis = MeshInstance3D.new()
	var v_mesh = SphereMesh.new()
	v_mesh.radius = 6.0
	v_mesh.height = 12.0
	var v_mat = StandardMaterial3D.new()
	v_mat.albedo_color = Color(1.0, 0.3, 0.0, 0.5)
	v_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	v_mesh.material = v_mat
	vis.mesh = v_mesh
	get_tree().current_scene.add_child(vis)
	vis.global_position = global_position
	
	var tween = get_tree().create_tween()
	tween.tween_property(vis, "scale", Vector3(1.5, 1.5, 1.5), 0.2)
	tween.tween_property(vis, "transparency", 1.0, 0.2)
	tween.tween_callback(vis.queue_free)
	
	queue_free()
