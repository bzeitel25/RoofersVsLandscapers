extends Area3D

var active: bool = true

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Players
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not active: return
	
	if body.has_method("_handle_jump"): # Is a player
		active = false
		print(body.name, " slipped on toys!")
		
		# Apply slip physics
		if "velocity" in body:
			# Random slide direction
			var slip_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
			body.velocity = slip_dir * 15.0
			
		# Disable player movement for 1 second
		if "is_vaulting" in body: # Just using an existing variable to stun
			pass # We might need a better stun. Tar works!
		if "is_tarred" in body:
			body.is_tarred = true
			
		body.take_damage(5.0)
		
		queue_free()