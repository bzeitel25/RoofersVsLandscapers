extends "res://scripts/weapons/melee/base_melee.gd"

var left_half: Node3D
var right_half: Node3D

func _init() -> void:
	tool_name = "Pruning Shears"
	slot_type = 0
	damage = 10.0
	cooldown = 0.3
	crit_chance = 0.25 # 25% crit rate!
	swing_duration = 0.3

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	var visual_root = Node3D.new()
	add_child(visual_root)
	
	var mat_handle = StandardMaterial3D.new()
	mat_handle.albedo_color = Color(0.1, 0.6, 0.1)
	
	var mat_blade = StandardMaterial3D.new()
	mat_blade.albedo_color = Color(0.8, 0.8, 0.8)
	mat_blade.metallic = 0.9
	
	# Create animatable halves with a central pivot
	left_half = _build_shear_half(1, mat_handle, mat_blade)
	right_half = _build_shear_half(-1, mat_handle, mat_blade)
	visual_root.add_child(left_half)
	visual_root.add_child(right_half)

func _build_shear_half(sign_val: float, mat_handle: Material, mat_blade: Material) -> Node3D:
	var half = Node3D.new()
	half.position = Vector3(0, 0.2, 0) # Pivot point in the middle
	
	var handle = MeshInstance3D.new()
	var handle_mesh = CylinderMesh.new()
	handle_mesh.top_radius = 0.03
	handle_mesh.bottom_radius = 0.03
	handle_mesh.height = 0.2
	handle.mesh = handle_mesh
	handle.position = Vector3(0.05 * sign_val, -0.1, 0)
	handle.rotation_degrees.z = 15 * sign_val
	handle.material_override = mat_handle
	half.add_child(handle)
	
	var blade = MeshInstance3D.new()
	var blade_mesh = BoxMesh.new()
	blade_mesh.size = Vector3(0.04, 0.2, 0.01)
	blade.mesh = blade_mesh
	blade.position = Vector3(0.02 * sign_val, 0.1, 0)
	blade.rotation_degrees.z = -10 * sign_val
	blade.material_override = mat_blade
	half.add_child(blade)
	
	return half

func _generate_combo() -> void:
	# Custom 2-hit Snip Combo!
	# Weapon reaches out straight and holds for a split second to CHOP
	combo_sequence = [
		{
			"duration": 0.35,
			"poses": [
				{"t": 0.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO},
				# Reach out fast
				{"t": 0.2,  "pos": Vector3(0, 0, -1.0), "rot": Vector3(-90, 0, 0)},
				# Hold position to snap shut
				{"t": 0.5,  "pos": Vector3(0, 0, -1.0), "rot": Vector3(-90, 0, 0)},
				# Recover
				{"t": 1.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO}
			]
		},
		{
			"duration": 0.35,
			"poses": [
				{"t": 0.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO},
				# Slightly angled reach
				{"t": 0.2,  "pos": Vector3(0.1, 0, -1.1), "rot": Vector3(-90, 0, -20)},
				# Hold
				{"t": 0.5,  "pos": Vector3(0.1, 0, -1.1), "rot": Vector3(-90, 0, -20)},
				{"t": 1.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO}
			]
		}
	]

func _perform_attack() -> void:
	super._perform_attack()
	
	# Animate the shear blades snapping open and closed!
	var dur = combo_sequence[combo_step - 1 if combo_step > 0 else combo_sequence.size() - 1]["duration"]
	var tween = create_tween()
	
	# Default rest rotation is 0
	# Open wide
	tween.tween_property(left_half, "rotation_degrees:z", 25.0, dur * 0.15).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(right_half, "rotation_degrees:z", -25.0, dur * 0.15).set_ease(Tween.EASE_OUT)
	
	# SNAP SHUT
	tween.tween_property(left_half, "rotation_degrees:z", -10.0, dur * 0.1).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(right_half, "rotation_degrees:z", 10.0, dur * 0.1).set_ease(Tween.EASE_IN)
	
	# Hold shut for a moment
	tween.tween_interval(dur * 0.25)
	
	# Relax back to neutral
	tween.tween_property(left_half, "rotation_degrees:z", 0.0, dur * 0.5)
	tween.parallel().tween_property(right_half, "rotation_degrees:z", 0.0, dur * 0.5)
