extends BaseTool

@export var push_force: float = 8.0
@export var puff_force: float = 25.0
@export var alt_fire_cooldown: float = 5.0

var _is_blowing: bool = false
var _last_puff_time: float = 0.0

var wind_box: Area3D
var wind_col: CollisionShape3D

func _init() -> void:
	tool_name = "Leaf Blower"
	slot_type = 1 # Ranged
	cooldown = 0.1 # Very fast tick rate for primary
	max_ammo = 150 # Large fuel tank

func _ready() -> void:
	super._ready()
	
	# Build the physical leaf blower (placeholder)
	var visual_root = Node3D.new()
	add_child(visual_root)
	
	var body_mesh = CylinderMesh.new()
	body_mesh.top_radius = 0.15
	body_mesh.bottom_radius = 0.15
	body_mesh.height = 0.5
	var body = MeshInstance3D.new()
	body.mesh = body_mesh
	body.rotation_degrees.x = 90
	var mat_body = StandardMaterial3D.new()
	mat_body.albedo_color = Color(1.0, 0.4, 0.0)
	body.material_override = mat_body
	visual_root.add_child(body)
	
	var tube_mesh = CylinderMesh.new()
	tube_mesh.top_radius = 0.08
	tube_mesh.bottom_radius = 0.1
	tube_mesh.height = 0.8
	var tube = MeshInstance3D.new()
	tube.mesh = tube_mesh
	tube.position = Vector3(0, 0, -0.6)
	tube.rotation_degrees.x = 90
	var mat_tube = StandardMaterial3D.new()
	mat_tube.albedo_color = Color(0.1, 0.1, 0.1)
	tube.material_override = mat_tube
	visual_root.add_child(tube)
	
	# Build the Wind Box (Area3D)
	wind_box = Area3D.new()
	wind_box.collision_layer = 0
	wind_box.collision_mask = 7 # Detects everything (Players, Projectiles, World)
	add_child(wind_box)
	
	wind_col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.5, 1.5, 4.0)
	wind_col.shape = shape
	wind_col.position = Vector3(0, 0, -2.5) # Extends 4 meters forward
	wind_box.add_child(wind_col)
	
	# Start disabled
	wind_col.disabled = true

func primary_action_pressed() -> void:
	if not can_use(): return
	_is_blowing = true
	wind_col.disabled = false

func primary_action_released() -> void:
	_is_blowing = false
	wind_col.disabled = true

func alt_use(character: Node3D) -> void:
	if current_ammo < 15:
		print("Leafblower: Not enough ammo for Alt Fire!")
		return
		
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_puff_time >= alt_fire_cooldown:
		_last_puff_time = current_time
		consume_ammo(15)
		print("Leafblower: ALT FIRE PUFF!")
		
		# Temporarily increase the box size for the puff
		var original_size = wind_col.shape.size
		wind_col.shape.size = Vector3(2.5, 2.5, 6.0)
		wind_col.position = Vector3(0, 0, -3.5)
		
		# Force physics update to catch everything instantly
		await get_tree().physics_frame
		await get_tree().physics_frame
		
		var bodies = wind_box.get_overlapping_bodies()
		for body in bodies:
			if body == character:
				continue
				
			var push_dir = (body.global_position - global_position).normalized()
			push_dir.y = 0.5 # Slight upward angle
			
			if body.has_method("apply_impulse"):
				body.apply_impulse(push_dir * puff_force)
			elif "velocity" in body:
				body.velocity += push_dir * puff_force
				
			if body.has_method("take_damage"):
				body.take_damage(15.0, character.owning_peer_id if "owning_peer_id" in character else 1)
				
		var areas = wind_box.get_overlapping_areas()
		for area in areas:
			if area.has_method("set_velocity") or "velocity" in area: # Assuming it's a projectile
				var push_dir = (area.global_position - global_position).normalized()
				if "velocity" in area:
					area.velocity = push_dir * area.velocity.length() * 1.5 # Reflect faster
					if "owning_peer_id" in area and "owning_peer_id" in character:
						area.owning_peer_id = character.owning_peer_id # Take ownership
						
		# Restore size
		wind_col.shape.size = original_size
		wind_col.position = Vector3(0, 0, -2.5)

var _ammo_tick_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if _is_blowing and not wind_col.disabled:
		if current_ammo <= 0:
			primary_action_released()
			return
			
		_ammo_tick_timer += delta
		if _ammo_tick_timer >= 0.1:
			_ammo_tick_timer -= 0.1
			consume_ammo(1)
			
		var bodies = wind_box.get_overlapping_bodies()
		for body in bodies:
			if wielder and body == wielder:
				continue
				
			# Continuous low damage (approx 10 DPS)
			if body.has_method("take_damage"):
				var peer_id = wielder.owning_peer_id if "owning_peer_id" in wielder else 1
				body.take_damage(10.0 * delta, peer_id)
				
			# Continuous pushback
			var push_dir = -global_transform.basis.z.normalized()
			push_dir.y = 0.2
			if body.has_method("apply_impulse"):
				body.apply_impulse(push_dir * push_force * delta * 50.0)
			elif "velocity" in body:
				# Gently resist movement towards the blower, push away
				body.velocity += push_dir * push_force * delta * 5.0
