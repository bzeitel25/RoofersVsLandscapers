class_name BaseProjectile
extends Area3D

@export var speed: float = 20.0
@export var damage: float = 10.0
@export var gravity_scale: float = 1.0

var velocity: Vector3 = Vector3.ZERO
var shooter: Node3D = null

func initialize(start_transform: Transform3D, initial_velocity: Vector3, new_shooter: Node3D) -> void:
	global_transform = start_transform
	velocity = initial_velocity
	shooter = new_shooter
	collision_mask = 3 # Ensure it hits players (Layer 2) and World (Layer 1)
	
	# Rotate to face velocity
	if velocity.length_squared() > 0.001:
		look_at(global_position + velocity, Vector3.UP)

func _physics_process(delta: float) -> void:
	# Apply gravity
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_scale
	velocity.y -= gravity * delta
	
	# Move
	global_position += velocity * delta
	
	# Update rotation to arc with velocity
	if velocity.length_squared() > 0.001:
		look_at(global_position + velocity, Vector3.UP)

func _on_body_entered(body: Node3D) -> void:
	# Ignore the shooter
	if body == shooter:
		return
		
	# TODO: Hardhat and Headshot Hitbox Logic!
	# 1. Update player hitboxes to have a separate head collision shape
	# 2. Check if the hit shape belongs to the head
	# 3. If hit head: check if player has a "hardhat_equipped" flag
	# 4. If hardhat exists -> break hardhat, deal no damage
	# 5. If no hardhat -> apply guaranteed crit (damage * 2.0 or 3.0)

	if body.has_method("take_damage"):
		# We assume multiplayer framework will handle taking damage authoritatively later
		body.take_damage(damage, shooter.owning_peer_id if "owning_peer_id" in shooter else 1)
		
	# Spawn impact effect here
	print("Projectile hit: ", body.name)
	queue_free()
