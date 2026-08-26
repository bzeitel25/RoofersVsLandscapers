extends Area3D

var active: bool = true

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Players only
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not active: return
	
	if body.has_method("take_damage"):
		# Trap sprung!
		active = false
		print("Leaf Pile Trap Sprung on ", body.name)
		
		# Root them / slow them
		if "velocity" in body:
			body.velocity = Vector3.ZERO
		if "is_tarred" in body:
			body.is_tarred = true
			
		# Deal damage
		body.take_damage(25.0)
		
		# Explode leaves visually
		var particles = CPUParticles3D.new()
		particles.emitting = true
		particles.one_shot = true
		particles.explosiveness = 0.9
		particles.amount = 30
		particles.mesh = BoxMesh.new()
		particles.mesh.size = Vector3(0.1, 0.1, 0.1)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.SADDLE_BROWN
		particles.mesh.material = mat
		particles.direction = Vector3.UP
		particles.initial_velocity_min = 3.0
		particles.initial_velocity_max = 6.0
		add_child(particles)
		
		get_node("Mesh").hide()
		await get_tree().create_timer(1.0).timeout
		queue_free()