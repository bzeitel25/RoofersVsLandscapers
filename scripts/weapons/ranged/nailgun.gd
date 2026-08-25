class_name Nailgun
extends "res://scripts/weapons/base_tool.gd"

const PROJECTILE_SCRIPT = preload("res://scripts/weapons/ranged/base_projectile.gd")

@export var burst_count: int = 3
@export var burst_delay: float = 0.1
@export var projectile_speed: float = 40.0

var _is_bursting: bool = false
var _bursts_fired: int = 0
var _burst_timer: float = 0.0

func _ready() -> void:
	tool_name = "Nail Gun"
	cooldown = 0.8
	slot_type = 1 # Ranged
	super._ready()
	
	# Build composite mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.6, 0.6) # Silver metal
	mat.metallic = 0.7
	
	var black_mat = StandardMaterial3D.new()
	black_mat.albedo_color = Color(0.1, 0.1, 0.1) # Black plastic
	
	var yellow_mat = StandardMaterial3D.new()
	yellow_mat.albedo_color = Color(0.9, 0.8, 0.1) # Yellow magazine
	
	# Barrel/Body
	var barrel = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.08, 0.12, 0.3)
	b_mesh.material = mat
	barrel.mesh = b_mesh
	barrel.position = Vector3(0, 0, -0.05)
	add_child(barrel)
	
	# Handle
	var handle = MeshInstance3D.new()
	var h_mesh = BoxMesh.new()
	h_mesh.size = Vector3(0.06, 0.15, 0.08)
	h_mesh.material = black_mat
	handle.mesh = h_mesh
	handle.position = Vector3(0, -0.1, 0.05)
	handle.rotation_degrees = Vector3(10, 0, 0)
	add_child(handle)
	
	# Magazine
	var mag = MeshInstance3D.new()
	var m_mesh = BoxMesh.new()
	m_mesh.size = Vector3(0.04, 0.15, 0.08)
	m_mesh.material = yellow_mat
	mag.mesh = m_mesh
	mag.position = Vector3(0, -0.1, -0.15)
	mag.rotation_degrees = Vector3(-15, 0, 0)
	add_child(mag)

func _process(delta: float) -> void:
	super._process(delta)
	
	if _is_bursting:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_fire_nail()
			_bursts_fired += 1
			_burst_timer = burst_delay
			
			if _bursts_fired >= burst_count:
				_is_bursting = false

func primary_action() -> void:
	if can_use() and not _is_bursting:
		_is_bursting = true
		_bursts_fired = 0
		_burst_timer = 0.0
		_start_cooldown()

func _fire_nail() -> void:
	if not wielder:
		return
		
	var camera = wielder.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if not camera:
		return
		
	# Create projectile
	var proj = Area3D.new()
	proj.set_script(PROJECTILE_SCRIPT)
	proj.status_effect = "nail"
	wielder.get_tree().current_scene.add_child(proj)
	
	# Add simple visual
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.05, 0.05, 0.2)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.8, 0.9) # Silver/metal
	box.material = mat
	mesh_inst.mesh = box
	proj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = box.size
	col.shape = col_box
	proj.add_child(col)
	
	# Connect signal
	proj.body_entered.connect(proj._on_body_entered)
	
	# TPS Aiming Logic: Shoot from the weapon towards the crosshair
	var target_pos = wielder.get_aim_target() if wielder.has_method("get_aim_target") else (global_position - camera.global_transform.basis.z * 100.0)
	
	# Start at the weapon's barrel position
	var spawn_pos = global_position + (global_transform.basis.z * -0.3)
	
	var forward = (target_pos - spawn_pos).normalized()
	
	# Add some recoil spread to the forward vector
	var spread = 0.005 if _is_aiming else 0.02
	forward.x += randf_range(-spread, spread)
	forward.y += randf_range(-spread, spread)
	forward = forward.normalized()
	
	proj.initialize(Transform3D(Basis(), spawn_pos), forward * projectile_speed, wielder)
	
	# Add physical recoil to the player
	if wielder.has_method("apply_impulse"):
		wielder.apply_impulse(-forward * 2.0)
	elif "velocity" in wielder:
		wielder.velocity -= forward * 2.0
		
	print("Nail fired!")

var _is_aiming: bool = false
var _original_spring_length: float = 5.0

func alt_use_pressed(character: Node3D) -> void:
	var arm = character.get_node_or_null("CameraPivot/SpringArm3D")
	var cam = character.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if arm and cam and not _is_aiming:
		_is_aiming = true
		_original_spring_length = arm.spring_length
		
		# Slight zoom, keeping 3rd person
		var tween = create_tween().set_parallel(true)
		tween.tween_property(arm, "spring_length", 3.0, 0.15)
		tween.tween_property(cam, "fov", 55.0, 0.15)
		if "zoom_speed_mult" in character:
			character.zoom_speed_mult = 0.65

func alt_use_released(character: Node3D) -> void:
	if not character: return
	
	var arm = character.get_node_or_null("CameraPivot/SpringArm3D")
	var cam = character.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if arm and cam and _is_aiming:
		_is_aiming = false
		
		# Return to normal third person
		var tween = create_tween().set_parallel(true)
		tween.tween_property(arm, "spring_length", _original_spring_length, 0.15)
		tween.tween_property(cam, "fov", 75.0, 0.15)
		if "zoom_speed_mult" in character:
			character.zoom_speed_mult = 1.0

func unequip() -> void:
	if _is_aiming and wielder:
		alt_use_released(wielder)
	super.unequip()
