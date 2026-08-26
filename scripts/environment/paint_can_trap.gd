extends Area3D

var dropped: bool = false
var paint_can: Node3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Players
	body_entered.connect(_on_body_entered)
	
	paint_can = Node3D.new()
	add_child(paint_can)
	
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.radius = 0.15
	cm.height = 0.35
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.1, 0.1) # Red paint can
	mi.mesh = cm
	mi.material_override = mat
	paint_can.add_child(mi)
	
	# The trigger area is a tall box below it
	var cs = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(1.5, 4.0, 1.5)
	cs.shape = bs
	cs.position = Vector3(0, -2.0, 0)
	add_child(cs)

func _process(delta: float) -> void:
	if dropped and paint_can:
		paint_can.position.y -= 15.0 * delta
		if paint_can.position.y < -4.0:
			queue_free()

func _on_body_entered(body: Node3D) -> void:
	if dropped: return
	if body.has_method("take_damage"):
		dropped = true
		print("Paint can dropped on ", body.name)
		body.take_damage(40.0)
		
		# Knockback
		if "velocity" in body:
			body.velocity = Vector3(0, -5.0, 0) # Slam down