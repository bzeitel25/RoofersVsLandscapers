class_name Slingshot
extends "res://scripts/weapons/base_tool.gd"

const PROJECTILE_SCRIPT = preload("res://scripts/weapons/ranged/base_projectile.gd")

@export var projectile_speed: float = 25.0
var band: MeshInstance3D
var is_charging: bool = false
var charge_time: float = 0.0
var max_charge_time: float = 1.0

func _ready() -> void:
	tool_name = "Hunting Slingshot"
	cooldown = 0.4 # Fast reload
	slot_type = 1 # Ranged
	super._ready()
	
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.4, 0.25, 0.1) # Brown wood
	
	var band_mat = StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.2, 0.2, 0.2) # Rubber band
	
	# Main Handle
	var handle = MeshInstance3D.new()
	var h_mesh = BoxMesh.new()
	h_mesh.size = Vector3(0.04, 0.2, 0.04)
	h_mesh.material = wood_mat
	handle.mesh = h_mesh
	handle.position = Vector3(0, -0.1, 0)
	add_child(handle)
	
	# Left Fork
	var left = MeshInstance3D.new()
	var l_mesh = BoxMesh.new()
	l_mesh.size = Vector3(0.03, 0.15, 0.03)
	l_mesh.material = wood_mat
	left.mesh = l_mesh
	left.position = Vector3(-0.06, 0.05, 0)
	left.rotation_degrees = Vector3(0, 0, 30)
	add_child(left)
	
	# Right Fork
	var right = MeshInstance3D.new()
	var r_mesh = BoxMesh.new()
	r_mesh.size = Vector3(0.03, 0.15, 0.03)
	r_mesh.material = wood_mat
	right.mesh = r_mesh
	right.position = Vector3(0.06, 0.05, 0)
	right.rotation_degrees = Vector3(0, 0, -30)
	add_child(right)
	
	# Band
	var band = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.18, 0.01, 0.01)
	b_mesh.material = band_mat
	band.mesh = b_mesh
	band.position = Vector3(0, 0.1, -0.02)
	add_child(band)

func _process(delta: float) -> void:
	super._process(delta)
	if is_charging:
		charge_time += delta
		if charge_time > max_charge_time:
			charge_time = max_charge_time
		
		# Visually pull back the band
		if band:
			var pull = charge_time / max_charge_time
			band.position.z = lerp(0.0, 0.2, pull)
			band.scale.y = lerp(1.0, 1.5, pull)
	else:
		# Reset band smoothly
		if band:
			band.position.z = lerpf(band.position.z, 0.0, delta * 15.0)
			band.scale.y = lerpf(band.scale.y, 1.0, delta * 15.0)

func primary_action_pressed() -> void:
	if not can_use() or not wielder:
		return
	is_charging = true
	charge_time = 0.0

func primary_action_released() -> void:
	if not is_charging:
		return
	
	is_charging = false
	_start_cooldown()
	_fire_projectile()

func _fire_projectile() -> void:
	var camera = wielder.camera
	if not camera: return
	
	# Create pebble projectile
	var proj = PROJECTILE_SCRIPT.new()
	proj.damage = 15.0 # Slingshot damage
	
	# Calculate speed multiplier based on charge (min 0.4, max 1.5)
	var charge_ratio = charge_time / max_charge_time
	var speed_mult = lerp(0.4, 1.5, charge_ratio)
	
	wielder.get_tree().current_scene.add_child(proj)
	
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.4)
	sphere.material = mat
	mesh_inst.mesh = sphere
	proj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.05
	col.shape = shape
	proj.add_child(col)
	
	proj.body_entered.connect(proj._on_body_entered)
	
	# TPS Aiming Logic: Shoot from the weapon towards the crosshair
	var target_pos = wielder.get_aim_target() if wielder.has_method("get_aim_target") else (global_position - camera.global_transform.basis.z * 100.0)
	var spawn_pos = global_position + (global_transform.basis.z * -0.2) + (global_transform.basis.y * 0.1)
	var forward = (target_pos - spawn_pos).normalized()
	
	# Upward arc based on charge (less arc if fully charged)
	forward.y += lerp(0.3, 0.05, charge_ratio)
	forward = forward.normalized()
	
	proj.initialize(Transform3D(Basis(), spawn_pos), forward * (projectile_speed * speed_mult), wielder)
	
	# Recoil effect on the slingshot model
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees:x", 30.0, 0.05)
	tween.tween_property(self, "rotation_degrees:x", 0.0, 0.15)

func alt_use_pressed(character: Node3D) -> void:
	if not can_use():
		return
		
	# Check if we have any special ammo before starting charge
	var ammo_type = _get_best_special_ammo()
	if ammo_type == "":
		print("Slingshot: No special ammo!")
		return
		
	is_charging = true
	charge_time = 0.0

func alt_use_released(character: Node3D) -> void:
	if not is_charging:
		return
		
	is_charging = false
	_start_cooldown()
	
	var ammo_type = _get_best_special_ammo()
	if ammo_type == "":
		return # Lost ammo while charging?
		
	# Consume the ammo
	if wielder.special_ammo.has(ammo_type):
		wielder.special_ammo[ammo_type] -= 1
		print("Fired ", ammo_type, "! Remaining: ", wielder.special_ammo[ammo_type])
		
	_fire_special_projectile(ammo_type)

func _get_best_special_ammo() -> String:
	if not wielder or not "special_ammo" in wielder:
		return ""
	var dict = wielder.special_ammo
	if dict.get("beehive", 0) > 0: return "beehive"
	if dict.get("stinkbomb", 0) > 0: return "stinkbomb"
	if dict.get("rotten_fruit", 0) > 0: return "rotten_fruit"
	return ""

func _fire_special_projectile(ammo_type: String) -> void:
	var camera = wielder.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if not camera: return
	
	var proj = PROJECTILE_SCRIPT.new()
	
	# Modify damage/behavior based on ammo type
	if ammo_type == "beehive":
		proj.damage = 30.0
	elif ammo_type == "stinkbomb":
		proj.damage = 10.0
	elif ammo_type == "rotten_fruit":
		proj.damage = 5.0
	
	var charge_ratio = charge_time / max_charge_time
	var speed_mult = lerp(0.4, 1.5, charge_ratio)
	
	wielder.get_tree().current_scene.add_child(proj)
	
	# Make it look different based on ammo type!
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	var mat = StandardMaterial3D.new()
	
	if ammo_type == "beehive":
		mat.albedo_color = Color(0.8, 0.6, 0.1) # Yellow-orange
	elif ammo_type == "stinkbomb":
		mat.albedo_color = Color(0.2, 0.8, 0.2) # Green
	elif ammo_type == "rotten_fruit":
		mat.albedo_color = Color(0.6, 0.1, 0.1) # Dark red
		
	sphere.material = mat
	mesh_inst.mesh = sphere
	proj.add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.15
	col.shape = shape
	proj.add_child(col)
	
	proj.body_entered.connect(proj._on_body_entered)
	
	var target_pos = wielder.get_aim_target() if wielder.has_method("get_aim_target") else (global_position - camera.global_transform.basis.z * 100.0)
	var spawn_pos = global_position + (global_transform.basis.z * -0.2) + (global_transform.basis.y * 0.1)
	var forward = (target_pos - spawn_pos).normalized()
	
	forward.y += lerp(0.3, 0.05, charge_ratio)
	forward = forward.normalized()
	
	proj.initialize(Transform3D(Basis(), spawn_pos), forward * (projectile_speed * speed_mult), wielder)
	
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees:x", 35.0, 0.05)
	tween.tween_property(self, "rotation_degrees:x", 0.0, 0.2)
