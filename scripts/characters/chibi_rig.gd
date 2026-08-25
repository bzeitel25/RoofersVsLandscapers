extends Node3D
class_name ChibiRig

var head: Node3D
var torso: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D

var _anim_time: float = 0.0

func _init(team_id: int = 0) -> void:
	# Define team colors
	var primary_color = Color(0.2, 0.4, 0.8) if team_id == 0 else Color(0.3, 0.6, 0.2)
	var skin_color = Color(0.9, 0.75, 0.6)
	var pants_color = Color(0.2, 0.2, 0.2)
	var hat_color = Color(0.9, 0.8, 0.1) if team_id == 0 else Color(0.1, 0.1, 0.1)
	
	var mat_primary = StandardMaterial3D.new()
	mat_primary.albedo_color = primary_color
	
	var mat_skin = StandardMaterial3D.new()
	mat_skin.albedo_color = skin_color
	
	var mat_pants = StandardMaterial3D.new()
	mat_pants.albedo_color = pants_color
	
	var mat_hat = StandardMaterial3D.new()
	mat_hat.albedo_color = hat_color
	
	# --- Torso (Stout box) ---
	torso = Node3D.new()
	torso.position = Vector3(0, 0.6, 0)
	add_child(torso)
	
	var torso_mesh = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.6, 0.7, 0.4)
	torso_mesh.mesh = t_box
	torso_mesh.material_override = mat_primary
	torso_mesh.position = Vector3(0, 0.35, 0)
	torso.add_child(torso_mesh)
	
	# --- Head ---
	head = Node3D.new()
	head.position = Vector3(0, 0.7, 0) # Pivot at neck
	torso.add_child(head)
	
	var head_mesh = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.35, 0.35, 0.35) # Smaller head
	head_mesh.mesh = h_box
	head_mesh.material_override = mat_skin
	head_mesh.position = Vector3(0, 0.175, 0)
	head.add_child(head_mesh)
	
	var hat_mesh = MeshInstance3D.new()
	var hat_cyl = CylinderMesh.new()
	hat_cyl.top_radius = 0.24
	hat_cyl.bottom_radius = 0.24
	hat_cyl.height = 0.15
	hat_mesh.mesh = hat_cyl
	hat_mesh.material_override = mat_hat
	hat_mesh.position = Vector3(0, 0.425, 0)
	head.add_child(hat_mesh)
	
	var brim_mesh = MeshInstance3D.new()
	var brim_cyl = CylinderMesh.new()
	brim_cyl.top_radius = 0.32
	brim_cyl.bottom_radius = 0.32
	brim_cyl.height = 0.05
	brim_mesh.mesh = brim_cyl
	brim_mesh.material_override = mat_hat
	brim_mesh.position = Vector3(0, 0.35, -0.1)
	head.add_child(brim_mesh)
	
	# --- Limbs ---
	left_arm = _create_limb(Vector3(-0.45, 0.6, 0), mat_primary, mat_skin)
	torso.add_child(left_arm)
	
	right_arm = _create_limb(Vector3(0.45, 0.6, 0), mat_primary, mat_skin)
	torso.add_child(right_arm)
	
	left_leg = _create_limb(Vector3(-0.18, 0.6, 0), mat_pants, mat_pants)
	add_child(left_leg)
	
	right_leg = _create_limb(Vector3(0.18, 0.6, 0), mat_pants, mat_pants)
	add_child(right_leg)
	
	# Arms point straight down (Roblox/Minecraft style)
	left_arm.rotation_degrees.z = 0
	right_arm.rotation_degrees.z = 0

func _create_limb(pos: Vector3, upper_mat: Material, lower_mat: Material) -> Node3D:
	var pivot = Node3D.new()
	pivot.position = pos
	
	var limb_mesh = MeshInstance3D.new()
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.12
	l_cyl.bottom_radius = 0.1
	l_cyl.height = 0.6
	limb_mesh.mesh = l_cyl
	limb_mesh.material_override = upper_mat
	limb_mesh.position = Vector3(0, -0.3, 0)
	pivot.add_child(limb_mesh)
	
	return pivot

func update_animation(velocity: Vector3, is_grounded: bool, delta: float, weapon_target: Node3D = null) -> void:
	# Local planar speed
	var speed = Vector2(velocity.x, velocity.z).length()
	
	if not is_grounded:
		# Jumping/Falling pose
		left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, -20.0, 10.0 * delta)
		right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 10.0, 10.0 * delta)
		left_arm.rotation_degrees.x = lerp(left_arm.rotation_degrees.x, -30.0, 10.0 * delta)
		if not weapon_target:
			right_arm.rotation_degrees.x = lerp(right_arm.rotation_degrees.x, 30.0, 10.0 * delta)
	elif speed > 0.5:
		# Walk/Run cycle
		_anim_time += speed * delta * 2.0
		var swing = sin(_anim_time) * 45.0 # 45 degree swing amplitude
		
		left_leg.rotation_degrees.x = swing
		right_leg.rotation_degrees.x = -swing
		left_arm.rotation_degrees.x = -swing
		if not weapon_target:
			right_arm.rotation_degrees.x = lerp(right_arm.rotation_degrees.x, swing, 10.0 * delta)
	else:
		# Idle
		_anim_time = 0.0
		left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, 0.0, 10.0 * delta)
		right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 0.0, 10.0 * delta)
		left_arm.rotation_degrees.x = lerp(left_arm.rotation_degrees.x, 0.0, 10.0 * delta)
		if not weapon_target:
			right_arm.rotation_degrees.x = lerp(right_arm.rotation_degrees.x, 0.0, 10.0 * delta)

	# --- Procedural IK for the Right Arm to hold the weapon ---
	if is_instance_valid(weapon_target) and weapon_target.is_inside_tree():
		# Point the arm at the weapon's global position
		var target_pos = weapon_target.global_position
		
		# Prevent errors if weapon is exactly at shoulder
		var dir = (target_pos - right_arm.global_position).normalized()
		if right_arm.global_position.distance_squared_to(target_pos) > 0.001:
			var up_vec = Vector3.UP
			if abs(dir.dot(Vector3.UP)) > 0.99:
				up_vec = Vector3.FORWARD
				
			# look_at points the -Z axis towards the target
			right_arm.look_at(target_pos, up_vec, true)
			# Our arm cylinder is built pointing down (-Y). 
			# To align -Y with -Z, we pitch up by 90 degrees.
			right_arm.rotation_degrees.x -= 90.0
			
			# Stretch the arm to reach the weapon exactly
			var dist = right_arm.global_position.distance_to(target_pos)
			var arm_mesh = right_arm.get_child(0) as MeshInstance3D
			if arm_mesh:
				# Base cylinder height is 0.6
				arm_mesh.scale.y = dist / 0.6
				# The pivot is at the top, so we shift it down by half the new height
				arm_mesh.position.y = -dist / 2.0
	else:
		# Reset arm scale/position if no weapon
		var arm_mesh = right_arm.get_child(0) as MeshInstance3D
		if arm_mesh:
			arm_mesh.scale.y = lerp(arm_mesh.scale.y, 1.0, 15.0 * delta)
			arm_mesh.position.y = lerp(arm_mesh.position.y, -0.3, 15.0 * delta)
