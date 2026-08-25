extends BaseTool

const PROJECTILE_SCRIPT = preload("res://scripts/weapons/ranged/base_projectile.gd")
var projectile_speed = 80.0
var visual_root: Node3D

func _ready() -> void:
	tool_name = "Gutter Sniper Rifle"
	damage = 40
	cooldown = 2.0
	slot_type = 1 # Ranged
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
			
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var body = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.05
	b_mesh.bottom_radius = 0.05
	b_mesh.height = 1.2
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color.SILVER
	b_mesh.material = b_mat
	body.mesh = b_mesh
	body.rotation_degrees.x = -90
	body.position = Vector3(0, 0, -0.5)
	visual_root.add_child(body)
	
	var scope = MeshInstance3D.new()
	var s_mesh = CylinderMesh.new()
	s_mesh.top_radius = 0.03
	s_mesh.bottom_radius = 0.03
	s_mesh.height = 0.3
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color.BLACK
	s_mesh.material = s_mat
	scope.mesh = s_mesh
	scope.rotation_degrees.x = -90
	scope.position = Vector3(0, 0.08, -0.2)
	visual_root.add_child(scope)

func primary_action() -> void:
	if not can_use() or not wielder: return
	_start_cooldown()
	_fire_projectile()

func _fire_projectile() -> void:
	var camera = wielder.camera
	if not camera: return
	var proj = PROJECTILE_SCRIPT.new()
	proj.damage = damage
	wielder.get_tree().current_scene.add_child(proj)
	
	# A single, large, high-velocity sniper bullet
	var p_mesh = MeshInstance3D.new()
	var m_mesh = SphereMesh.new()
	m_mesh.radius = 0.06 # Much larger bullet
	m_mesh.height = 0.12
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color.WHITE
	m_mesh.material = p_mat
	p_mesh.mesh = m_mesh
	proj.add_child(p_mesh)
	
	var col = CollisionShape3D.new()
	var c_shape = SphereShape3D.new()
	c_shape.radius = 0.06
	col.shape = c_shape
	proj.add_child(col)
	
	proj.body_entered.connect(proj._on_body_entered)
	
	var target_pos = wielder.get_aim_target() if wielder.has_method("get_aim_target") else (global_position - camera.global_transform.basis.z * 100.0)
	var spawn_pos = global_position + (global_transform.basis.z * -1.2)
	var forward = (target_pos - spawn_pos).normalized()
	
	proj.initialize(Transform3D(Basis(), spawn_pos), forward * projectile_speed, wielder)

var _is_zoomed: bool = false
var _original_spring_length: float = 3.0

func alt_use_pressed(character: Node3D) -> void:
	if not character or not "camera" in character: return
	
	var arm = character.get_node_or_null("CameraPivot/SpringArm3D")
	var cam = character.camera
	if arm and cam and not _is_zoomed:
		_is_zoomed = true
		_original_spring_length = arm.spring_length
		# Push to first person and lower FOV to zoom
		var tween = create_tween().set_parallel(true)
		tween.tween_property(arm, "spring_length", 0.0, 0.15)
		tween.tween_property(cam, "fov", 25.0, 0.15)
		if "zoom_speed_mult" in character:
			character.zoom_speed_mult = 0.4

func alt_use_released(character: Node3D) -> void:
	if not character or not "camera" in character: return
	
	var arm = character.get_node_or_null("CameraPivot/SpringArm3D")
	var cam = character.camera
	if arm and cam and _is_zoomed:
		_is_zoomed = false
		# Return to normal third person
		var tween = create_tween().set_parallel(true)
		tween.tween_property(arm, "spring_length", _original_spring_length, 0.15)
		tween.tween_property(cam, "fov", 75.0, 0.15)
		if "zoom_speed_mult" in character:
			character.zoom_speed_mult = 1.0

func unequip() -> void:
	if _is_zoomed and wielder:
		alt_use_released(wielder)
	super.unequip()
