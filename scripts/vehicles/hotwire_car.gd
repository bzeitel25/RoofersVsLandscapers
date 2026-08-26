extends CharacterBody3D

var is_hotwired: bool = false
var seats: Array[Node3D] = [null, null, null, null] # 0 = Driver, 1-3 = Passengers

var drive_speed: float = 20.0
var turn_speed: float = 2.0
var gravity: float = 20.0

func _ready() -> void:
	collision_layer = 1 | 64 # World + Interactable
	collision_mask = 1 | 2 # World + Players

func interact(player: Node3D) -> void:
	if not is_hotwired:
		if "can_hotwire" in player and player.can_hotwire:
			is_hotwired = true
			print("Car hotwired by ", player.name)
		else:
			print("You don't know how to hotwire this vehicle!")
			return
			
	# Find an empty seat
	for i in range(seats.size()):
		if seats[i] == null:
			seats[i] = player
			if player.has_method("enter_vehicle"):
				player.enter_vehicle(self)
			return
			
	print("Car is full!")

func remove_passenger(player: Node3D) -> void:
	for i in range(seats.size()):
		if seats[i] == player:
			seats[i] = null
			break

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if not is_hotwired:
		# Parked
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
		
	var driver = seats[0]
	if driver and driver.has_method("_is_local_player") and driver._is_local_player():
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		
		var speed_mult = 1.0
		if Input.is_action_pressed("sprint"):
			speed_mult = 1.5
			
		var forward_speed = -input_dir.y * drive_speed * speed_mult
		
		# Only turn if moving
		if abs(forward_speed) > 0.1:
			var turn_dir = -input_dir.x if forward_speed > 0 else input_dir.x
			rotate_y(turn_dir * turn_speed * delta)
			
		var forward = -transform.basis.z
		velocity.x = forward.x * forward_speed
		velocity.z = forward.z * forward_speed
		
		# Run over logic
		if velocity.length() > 5.0:
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				var body = collision.get_collider()
				if body and not body in seats and body.has_method("take_damage"):
					body.take_damage(50.0 * delta * speed_mult, driver.owning_peer_id if "owning_peer_id" in driver else 1)
					
	else:
		velocity.x = move_toward(velocity.x, 0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 15.0 * delta)
		
	move_and_slide()
	
	# Update passenger positions
	for i in range(seats.size()):
		var p = seats[i]
		if p:
			var pos_offset = Vector3.ZERO
			if i == 0: pos_offset = Vector3(0.5, 0.5, 0)
			elif i == 1: pos_offset = Vector3(-0.5, 0.5, 0)
			elif i == 2: pos_offset = Vector3(0.5, 0.5, 1.0)
			elif i == 3: pos_offset = Vector3(-0.5, 0.5, 1.0)
			
			p.global_position = global_position + transform.basis * pos_offset
