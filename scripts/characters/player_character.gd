# ============================================================
# ROOFERS vs LANDSCAPERS — 3D Character Controller
# ============================================================
# Third-person character controller for both Roofers and
# Landscapers. Handles movement, jumping, sprinting, crouching,
# and camera control.
#
# 3D VS 2D — KEY DIFFERENCES (for your transition):
# ─────────────────────────────────────────────────────
# 2D:  velocity.x = direction * speed
#      Gravity on velocity.y only
#      Camera is fixed (orthogonal or following)
#
# 3D:  Movement on the XZ plane (horizontal), Y is up
#      You need to think about FACING DIRECTION separately
#      Camera orbits around the character (mouse controls)
#      Input direction must be RELATIVE TO CAMERA, not world
#      CharacterBody3D replaces CharacterBody2D
#      move_and_slide() works the same way, just in 3D!
# ─────────────────────────────────────────────────────
#
# MULTIPLAYER NOTE:
# This controller runs on the owning client AND is replicated
# to other clients via MultiplayerSynchronizer. The owning
# client sends inputs; the server validates movement.
# For initial development, we use client-authoritative movement
# (simpler). NetFox upgrades this to server-authoritative later.
extends CharacterBody3D

class_name PlayerCharacter

# --- Exported Properties (tweak in inspector) ---

@export_group("Movement")
@export var move_speed: float = 7.0
@export var sprint_multiplier: float = 1.6
@export var acceleration: float = 20.0
@export var deceleration: float = 25.0
@export var air_control: float = 0.5  ## How much control in the air (0-1)

@export_group("Jumping")
@export var max_jumps: int = 1               ## Allow double/triple jumps!
var _jumps_made: int = 0
@export var jump_force: float = 12.0
@export var gravity_multiplier: float = 1.2  ## Multiplier on default gravity
@export var fall_multiplier: float = 1.5     ## Extra gravity when falling (snappier feel)
@export var coyote_time: float = 0.15        ## Grace period after leaving edge
@export var jump_buffer: float = 0.1         ## Buffer window for jump input

@export_group("Camera")
@export var mouse_sensitivity: float = 0.002
@export var camera_distance: float = 5.0
@export var camera_min_pitch: float = -60.0  ## Look down limit (degrees)
@export var camera_max_pitch: float = 40.0   ## Look up limit (degrees)
@export var camera_shoulder_offset: float = 0.8 ## X offset for over-the-shoulder view

@export_group("Multiplayer")
@export var owning_peer_id: int = 1  ## Which peer controls this character

# --- Node References ---
# These are set up in the scene tree (see player_character.tscn)

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var character_mesh: Node3D = $CharacterMesh
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# --- Internal State ---

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _is_sprinting: bool = false
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = false
var _is_right_shoulder: bool = true

## The input direction relative to the camera (set each frame)
var _input_dir: Vector2 = Vector2.ZERO

## Parkour / Traversal State
var is_vaulting: bool = false
var is_sliding: bool = false
var current_zipline: Node3D = null
var _vault_target: Vector3
var _vault_timer: float = 0.0

## Settings
@export var toggle_ads: bool = false # Menu setting for Hold vs Toggle aiming
var _is_ads_toggled: bool = false

## Current health
var health: float = 100.0
var max_health: float = 100.0
var is_alive: bool = true
var current_vehicle: Node3D = null

## Loadout
var loadout_manager: LoadoutManager = null
var hand_attachment_point: Node3D = null


## Interacting (Pickup)
var interact_ray: RayCast3D = null

## UI Elements
var health_bar: ProgressBar = null
var damage_flash: ColorRect = null
var overhead_hp_bar: ProgressBar = null
var overhead_hp_viewport: SubViewport = null
var wpn_ui_slots: Array = [] # Stores [ColorRect, Label (CD), Label (Key)] dicts for the 3 weapons
var ammo_label: Label = null
var supplies_label: Label = null

func _ready() -> void:
	# Set collision layers: Player is Layer 2, collides with World (1) and Players (2)
	collision_layer = 2
	collision_mask = 3
	
	# Fix camera offset and apply over-the-shoulder view (offset the SpringArm so it doesn't get overridden)
	camera_arm.position = Vector3(camera_shoulder_offset, 0, 0)
	
	# Add a visor to the character mesh so we know which way they are facing
	if not character_mesh.has_node("VisorMesh"):
		_create_placeholder_visor()
	
	# Create hand attachment point if missing
	if not character_mesh.has_node("HandAttachment"):
		hand_attachment_point = Node3D.new()
		hand_attachment_point.name = "HandAttachment"
		character_mesh.add_child(hand_attachment_point)
		
		# Position at the natural "hand" resting position (waist level, slightly forward)
		hand_attachment_point.position = Vector3(0.45, 0.6, -0.4)
	else:
		hand_attachment_point = character_mesh.get_node("HandAttachment")
		hand_attachment_point.position = Vector3(0.45, 0.6, -0.4)
	
	# Create interact raycast if missing
	if not camera.has_node("InteractRay"):
		interact_ray = RayCast3D.new()
		interact_ray.name = "InteractRay"
		interact_ray.target_position = Vector3(0, 0, -3.0)
		interact_ray.collision_mask = 64
		camera.add_child(interact_ray)
	else:
		interact_ray = camera.get_node("InteractRay")
	
	# Set up loadout manager if missing
	if not has_node("LoadoutManager"):
		loadout_manager = LoadoutManager.new()
		loadout_manager.name = "LoadoutManager"
		add_child(loadout_manager)
		loadout_manager.initialize(hand_attachment_point)
	else:
		loadout_manager = get_node("LoadoutManager")
		loadout_manager.initialize(hand_attachment_point)

	# Only the owning player controls their camera and input
	if _is_local_player():
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_create_local_hud()
	else:
		camera.current = false
		set_process_input(false)
		_create_overhead_hud()

func _create_overhead_hud() -> void:
	overhead_hp_viewport = SubViewport.new()
	overhead_hp_viewport.transparent_bg = true
	overhead_hp_viewport.size = Vector2(200, 30)
	add_child(overhead_hp_viewport)
	
	overhead_hp_bar = ProgressBar.new()
	overhead_hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	overhead_hp_bar.max_value = max_health
	overhead_hp_bar.value = health
	overhead_hp_bar.show_percentage = false
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	overhead_hp_bar.add_theme_stylebox_override("background", sb_bg)
	
	var sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color(0.8, 0.1, 0.1)
	overhead_hp_bar.add_theme_stylebox_override("fill", sb_fill)
	
	overhead_hp_viewport.add_child(overhead_hp_bar)
	
	var sprite3d = Sprite3D.new()
	sprite3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite3d.texture = overhead_hp_viewport.get_texture()
	sprite3d.position = Vector3(0, 2.2, 0) # Above head
	add_child(sprite3d)

func _create_placeholder_visor() -> void:
	if not character_mesh: return
	
	# Clear out the default placeholder mesh and visor if any exist
	if "mesh" in character_mesh:
		character_mesh.mesh = null
	
	for child in character_mesh.get_children():
		if child is MeshInstance3D or child is Sprite3D or child.name == "ChibiRig":
			child.queue_free()
	
	# Team color identification
	var team_id = 0
	if "owning_peer_id" in self and owning_peer_id != 1 and GameManager.has_method("get_team"):
		# Quick guess, will default to blue for local, green for dummy
		team_id = GameManager.get_team(owning_peer_id)
	elif owning_peer_id == -1:
		team_id = 1
		
	# Instantiate and inject the procedural chibi rig
	var ChibiRigClass = preload("res://scripts/characters/chibi_rig.gd")
	var rig = ChibiRigClass.new(team_id)
	rig.name = "ChibiRig"
	character_mesh.add_child(rig)

func _create_local_hud() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	# Crosshair
	var crosshair = ColorRect.new()
	crosshair.custom_minimum_size = Vector2(8, 8)
	crosshair.size = Vector2(8, 8)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-4, -4)
	crosshair.color = Color.WHITE
	canvas.add_child(crosshair)
	
	# Weapon Icons (Left of Health)
	var wpn_container = HBoxContainer.new()
	wpn_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	wpn_container.position = Vector2(20, -70)
	canvas.add_child(wpn_container)
	
	var hotkeys = ["1", "2", "3"]
	for i in range(3):
		var bg = ColorRect.new()
		bg.custom_minimum_size = Vector2(50, 50)
		bg.color = Color(0.2, 0.2, 0.2, 0.8)
		wpn_container.add_child(bg)
		
		var hotkey_lbl = Label.new()
		hotkey_lbl.text = hotkeys[i]
		hotkey_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
		hotkey_lbl.position = Vector2(4, 2)
		bg.add_child(hotkey_lbl)
		
		var name_lbl = Label.new()
		name_lbl.text = ""
		name_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		name_lbl.add_theme_font_size_override("font_size", 10)
		bg.add_child(name_lbl)
		
		var cd_lbl = Label.new()
		cd_lbl.text = ""
		cd_lbl.set_anchors_preset(Control.PRESET_CENTER)
		cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_lbl.add_theme_color_override("font_color", Color(1, 1, 0)) # Yellow text
		bg.add_child(cd_lbl)
		
		wpn_ui_slots.append({"bg": bg, "cd": cd_lbl, "name": name_lbl})
	
	# Ammo & Supplies Labels (Above Health)
	var stats_container = HBoxContainer.new()
	stats_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stats_container.position = Vector2(190, -80)
	stats_container.add_theme_constant_override("separation", 20)
	canvas.add_child(stats_container)
	
	ammo_label = Label.new()
	ammo_label.text = "Ammo: --/--"
	stats_container.add_child(ammo_label)
	
	supplies_label = Label.new()
	supplies_label.text = "Supplies: 100"
	supplies_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0)) # Cyan
	stats_container.add_child(supplies_label)
	
	# Health Bar (Shifted right to make room for weapons)
	health_bar = ProgressBar.new()
	health_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	health_bar.position = Vector2(190, -50)
	health_bar.size = Vector2(300, 30)
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = true
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.8, 0.2, 0.2)
	health_bar.add_theme_stylebox_override("fill", sb)
	canvas.add_child(health_bar)
	
	# Damage Flash Screen
	damage_flash = ColorRect.new()
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(1.0, 0.0, 0.0, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(damage_flash)


func _input(event: InputEvent) -> void:
	if not _is_local_player():
		return

	# Mouse look — rotate the camera pivot
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Horizontal rotation (yaw) — rotate the whole pivot
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		# Vertical rotation (pitch) — rotate the spring arm
		camera_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		# Clamp pitch so you can't flip the camera
		camera_arm.rotation.x = clamp(
			camera_arm.rotation.x,
			deg_to_rad(camera_min_pitch),
			deg_to_rad(camera_max_pitch)
		)

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.is_action_pressed("primary_attack"):
			if loadout_manager:
				loadout_manager.use_primary_action_pressed()
		elif event.is_action_released("primary_attack"):
			if loadout_manager:
				loadout_manager.use_primary_action_released()
		elif event.is_action_pressed("secondary_attack"):
			if loadout_manager:
				var active_tool = loadout_manager.get_active_tool()
				if active_tool:
					# If Toggle ADS is enabled, flip a state tracker.
					if toggle_ads:
						_is_ads_toggled = not _is_ads_toggled
						if _is_ads_toggled:
							if active_tool.has_method("alt_use_pressed"): active_tool.alt_use_pressed(self)
							elif active_tool.has_method("alt_use"): active_tool.alt_use(self)
						else:
							if active_tool.has_method("alt_use_released"): active_tool.alt_use_released(self)
					else:
						# Default Hold-to-ADS behavior
						if active_tool.has_method("alt_use_pressed"): active_tool.alt_use_pressed(self)
						elif active_tool.has_method("alt_use"): active_tool.alt_use(self)
						
		elif event.is_action_released("secondary_attack"):
			if loadout_manager and not toggle_ads:
				var active_tool = loadout_manager.get_active_tool()
				if active_tool and active_tool.has_method("alt_use_released"):
					active_tool.alt_use_released(self)
		elif event.is_action_pressed("ability"):
			if loadout_manager:
				loadout_manager.quick_use_gadget()
		elif event.is_action_pressed("interact"):
			if not current_vehicle:
				_try_interact()
		elif event.is_action_pressed("equip_item"):
			if not current_vehicle:
				_try_equip()
			
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_1:
				_is_ads_toggled = false
				if loadout_manager: loadout_manager.set_active_slot(LoadoutManager.Slot.MELEE)
			elif event.physical_keycode == KEY_2:
				_is_ads_toggled = false
				if loadout_manager: loadout_manager.set_active_slot(LoadoutManager.Slot.RANGED)
			elif event.physical_keycode == KEY_3:
				_is_ads_toggled = false
				if loadout_manager: loadout_manager.set_active_slot(LoadoutManager.Slot.GADGET)
			elif event.physical_keycode == KEY_4:
				_use_skill(1)
			elif event.physical_keycode == KEY_5:
				_use_skill(2)
			elif event.physical_keycode == KEY_C:
				print("Input: Pressed C")
				_toggle_shoulder()

func _toggle_shoulder() -> void:
	_is_right_shoulder = not _is_right_shoulder
	var target_x = camera_shoulder_offset if _is_right_shoulder else -camera_shoulder_offset
	var tween = create_tween()
	tween.tween_property(camera_arm, "position:x", target_x, 0.2).set_trans(Tween.TRANS_SINE)

func _try_interact() -> void:
	if interact_ray and interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if not collider is BaseTool:
			# Handle interacting with vans, doors, generators, etc.
			print("Interacted with: ", collider.name)
			if collider.has_method("interact"):
				collider.interact(self)

func _try_equip() -> void:
	if interact_ray and interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is BaseTool:
			# Pick up weapon/gadget
			print("Equipped: ", collider.tool_name)
			loadout_manager.set_tool(collider.slot_type, collider)

func _use_skill(skill_num: int) -> void:
	if skill_cooldowns[skill_num - 1] > 0:
		print("Skill ", skill_num, " is on cooldown! ", snapped(skill_cooldowns[skill_num - 1], 0.1), "s remaining.")
		return
		
	var used = false
	
	if current_team == 1 and current_class_enum == TeamManager.LandscaperClass.BOTANIST:
		if skill_num == 1:
			print("Botanist: Spawned Rotten Fruit!")
			special_ammo["rotten_fruit"] += 1
			skill_cooldowns[0] = 5.0 # 5s cooldown
			used = true
		elif skill_num == 2:
			print("Botanist: Spawned Beehive!")
			special_ammo["beehive"] += 1
			skill_cooldowns[1] = 12.0 # 12s cooldown
			used = true
	
	if used:
		print("Current Special Ammo: ", special_ammo)


func _process(delta: float) -> void:
	if _is_local_player():
		_update_hud()

func _update_hud() -> void:
	if supplies_label:
		supplies_label.text = "Supplies: %d" % supplies
	
	if ammo_label and loadout_manager:
		var active_tool = loadout_manager._slots[loadout_manager._active_slot]
		if active_tool and active_tool.max_ammo > 0:
			ammo_label.text = "Ammo: %d / %d" % [active_tool.current_ammo, active_tool.max_ammo]
		else:
			ammo_label.text = "Ammo: --/--"
			
		for i in range(3):
			if i >= wpn_ui_slots.size(): break
			var slot_data = wpn_ui_slots[i]
			var tool = loadout_manager._slots[i]
			
			# Highlight active weapon
			if i == loadout_manager._active_slot:
				slot_data["bg"].color = Color(0.2, 0.6, 1.0, 0.8) # Active blue
			else:
				slot_data["bg"].color = Color(0.2, 0.2, 0.2, 0.8) # Inactive gray
				
			if tool:
				# Show a tiny abbreviated name (first 6 chars)
				slot_data["name"].text = tool.tool_name.substr(0, 6)
				
				# Cooldown
				if tool._cooldown_timer > 0.0:
					slot_data["cd"].text = "%.1f" % tool._cooldown_timer
				else:
					slot_data["cd"].text = ""
			else:
				slot_data["name"].text = ""
				slot_data["cd"].text = ""

func _physics_process(delta: float) -> void:
	if skill_cooldowns[0] > 0: skill_cooldowns[0] -= delta
	if skill_cooldowns[1] > 0: skill_cooldowns[1] -= delta
	
	if _stuck_nail_timer > 0.0:
		_stuck_nail_timer -= delta
		if _stuck_nail_timer <= 0.0:
			stuck_nails = 0
			print(name, "'s stuck nails fell out.")
			
	if is_tarred:
		_tar_timer -= delta
		if _tar_timer <= 0.0:
			is_tarred = false
			
	if is_ignited:
		_ignite_timer -= delta
		_ignite_tick += delta
		if _ignite_tick >= 0.5: # Tick damage every 0.5 seconds
			_ignite_tick -= 0.5
			take_damage(8.0, -1) # 16 DPS
		if _ignite_timer <= 0.0:
			is_ignited = false
	
	if not is_alive:
		return

	if owning_peer_id == -1:
		# Dummy NPC logic: apply gravity and slide so they don't float
		_handle_gravity(delta)
		
		# Decelerate horizontal momentum so they don't slide forever from knockback
		var decel = deceleration
		if not is_on_floor():
			decel *= air_control
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
		velocity.z = move_toward(velocity.z, 0.0, decel * delta)
		
		var dummy_rig = character_mesh.get_node_or_null("ChibiRig")
		if dummy_rig:
			var active_tool = loadout_manager.get_active_tool() if loadout_manager else null
			dummy_rig.update_animation(velocity, is_on_floor(), delta, active_tool)
			
		move_and_slide()
		return
		
	if not _is_local_player():
		return

	if current_vehicle:
		# Lock player to vehicle seat and skip regular physics
		global_position = current_vehicle.global_position + Vector3(0, 1.0, 0)
		
		# Allow jumping out
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
			exit_vehicle(false)
		return

	if not _handle_parkour(delta):
		_handle_gravity(delta)
		_handle_jump(delta)
		_handle_movement(delta)
	
	_rotate_character_mesh(delta)

	var rig = character_mesh.get_node_or_null("ChibiRig")
	if rig:
		var active_tool = loadout_manager.get_active_tool() if loadout_manager else null
		rig.update_animation(velocity, is_on_floor(), delta, active_tool)

	move_and_slide()

	# Track floor state for coyote time
	if is_on_floor():
		_coyote_timer = coyote_time
	elif _was_on_floor:
		# Just left the floor — start coyote timer
		pass
	_was_on_floor = is_on_floor()


# ================================================================
# MOVEMENT — The Big 3D Shift
# ================================================================
# In 2D, input maps directly: press Right → move right.
# In 3D, input is RELATIVE TO THE CAMERA:
#   Press W → move in the direction the CAMERA is facing
#   Press A → move to the LEFT of the camera
# This is what makes 3D movement feel natural.

func _handle_movement(delta: float) -> void:
	# Get raw input as a 2D vector (same as your 2D game!)
	_input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	# Convert 2D input to 3D direction RELATIVE TO CAMERA
	# This is the key 3D concept: we use the camera's forward/right
	# vectors projected onto the XZ plane (ignoring Y/vertical)
	var camera_basis := camera_pivot.global_transform.basis
	var forward := -camera_basis.z  # Camera looks along -Z
	var right := camera_basis.x

	# Project onto XZ plane (horizontal only) and normalize
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	# Build the 3D movement direction
	# NOTE: get_vector's Y is screen-space (up = negative), so we negate it
	# to align with camera forward (away from camera = positive)
	var direction := (forward * -_input_dir.y + right * _input_dir.x).normalized()

	# Calculate target speed
	_is_sprinting = Input.is_action_pressed("sprint") and _input_dir.length() > 0.1
	# If we are zoomed in, sprinting is disabled and speed is slowed
	var sprint_mult = sprint_multiplier if (_is_sprinting and zoom_speed_mult >= 1.0) else 1.0
	var target_speed: float = (move_speed * sprint_mult) * zoom_speed_mult
	
	if is_tarred:
		target_speed *= 0.4 # 60% slow from tar
	
	if _is_on_ladder and _current_ladder:
		# Vertical movement on ladder
		var climb_dir = -_input_dir.y # W is up, S is down
		
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force
			exit_ladder()
			return
			
		var climb_speed = _current_ladder.climb_speed if _current_ladder and "climb_speed" in _current_ladder else 4.0
		var ladder_up = _current_ladder.global_transform.basis.y.normalized()
		var ladder_right = _current_ladder.global_transform.basis.x.normalized()
		
		var target_vel = ladder_up * (climb_dir * climb_speed)
		# Allow minor horizontal movement to center on ladder or move off
		target_vel += ladder_right * (_input_dir.x * target_speed * 0.3)
		
		var accel = acceleration
		velocity.x = move_toward(velocity.x, target_vel.x, accel * delta)
		velocity.y = move_toward(velocity.y, target_vel.y, accel * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, accel * delta)
		return

	# Smooth acceleration/deceleration (same concept as 2D!)
	var accel := acceleration if direction.length() > 0.1 else deceleration
	if not is_on_floor():
		accel *= air_control  # Less control in the air

	# Apply horizontal movement (XZ only — Y is handled by gravity/jump)
	var target_velocity := direction * target_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)


## Ladder state
var _current_ladder: Node3D = null
var _is_on_ladder: bool = false

func enter_ladder(ladder: Node3D) -> void:
	_current_ladder = ladder
	_is_on_ladder = true
	velocity.y = 0.0 # Stop falling

func exit_ladder() -> void:
	_current_ladder = null
	_is_on_ladder = false

func _handle_gravity(delta: float) -> void:
	if _is_on_ladder:
		return # No gravity on ladders
		
	if not is_on_floor():
		# Apply gravity with fall multiplier for snappier feel
		var grav := _gravity * gravity_multiplier
		if velocity.y < 0:
			grav *= fall_multiplier  # Fall faster than you rise
		velocity.y -= grav * delta

		# Coyote time countdown
		_coyote_timer -= delta


func _handle_jump(delta: float) -> void:
	if _is_on_ladder:
		return
		
	# Jump buffer: remember that the player pressed jump recently
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer

	_jump_buffer_timer -= delta

	# Can jump if on floor, coyote time, OR we have air jumps left
	var is_grounded = is_on_floor() or _coyote_timer > 0.0
	var can_jump = is_grounded or (_jumps_made < max_jumps)
	
	if can_jump and _jump_buffer_timer > 0.0:
		velocity.y = jump_force
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		
		if not is_grounded:
			_jumps_made += 1 # Mid-air jump
		else:
			_jumps_made = 1 # Ground jump counts as first jump
			
	if is_on_floor():
		_jumps_made = 0


func _rotate_character_mesh(delta: float) -> void:
	# In a 3rd Person Shooter, we want the character to face where we are aiming
	if character_mesh:
		var camera_forward = -camera_pivot.global_transform.basis.z
		camera_forward.y = 0
		if camera_forward.length_squared() > 0.01:
			var target_basis = Basis.looking_at(camera_forward.normalized(), Vector3.UP)
			character_mesh.global_transform.basis = character_mesh.global_transform.basis.slerp(target_basis, 15.0 * delta)
			
	# Also pitch the weapon arm up and down to match camera pitch
	if hand_attachment_point:
		hand_attachment_point.rotation.x = camera_pivot.rotation.x

## Returns the true 3D position the crosshair is looking at (Warframe style aiming)
func get_aim_target() -> Vector3:
	if not camera:
		return global_position + -global_transform.basis.z * 100.0
		
	var space_state = get_world_3d().direct_space_state
	
	# Raycast from camera center
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	var from = camera.project_ray_origin(screen_center)
	var to = from + camera.project_ray_normal(screen_center) * 1000.0
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self.get_rid()]
	# Only hit world/environment for aiming, or hit players? Hit everything except us
	query.collision_mask = 1 | 2 | 4 | 8 
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position
	return to


# ================================================================
# ================================================================
# PARKOUR & TRAVERSAL
# ================================================================

func mount_zipline(z_obj: Node3D) -> void:
	current_zipline = z_obj
	# Snap player onto the line (roughly)
	var start = z_obj.start_pos
	var end = z_obj.end_pos
	var line_dir = (end - start).normalized()
	var to_player = global_position - start
	var t = clamp(to_player.dot(line_dir), 0.0, start.distance_to(end))
	var closest_point = start + line_dir * t
	global_position = closest_point - Vector3(0, 1.5, 0) # Hang below it
	velocity = Vector3.ZERO
	_jumps_made = 0 # reset double jumps

## Returns true if a parkour move is actively overriding normal movement
func _handle_parkour(delta: float) -> bool:
	if current_zipline:
		if Input.is_action_just_pressed("jump"):
			# Detach and jump off
			velocity.y = jump_force
			current_zipline = null
			return false
			
		var start = current_zipline.start_pos
		var end = current_zipline.end_pos
		var line_dir = (end - start).normalized()
		
		# Move along zipline based on where we are looking (Forward/W key)
		if Input.is_action_pressed("move_forward"):
			var look_dir = -camera_pivot.global_transform.basis.z
			# Dot product to see which way along the wire we want to go
			var move_dir = line_dir if look_dir.dot(line_dir) > 0 else -line_dir
			velocity = move_dir * 15.0 # Zipline speed
		else:
			# Decelerate
			velocity = velocity.move_toward(Vector3.ZERO, 30.0 * delta)
			
		# Fall off if we reach the ends
		var to_player = global_position - start
		var t = to_player.dot(line_dir)
		if t < 0.0 or t > start.distance_to(end):
			current_zipline = null
			
		return true

	if is_vaulting:
		_vault_timer += delta * 5.0 # Speed of vault
		if _vault_timer >= 1.0:
			is_vaulting = false
			global_position = _vault_target
			# Boost slightly forward after vault
			velocity = -character_mesh.global_transform.basis.z * move_speed * 1.5
		else:
			# Tween position
			var current = global_position
			var up_target = Vector3(current.x, _vault_target.y, current.z)
			# Go up first, then forward
			if _vault_timer < 0.5:
				global_position = current.lerp(up_target, _vault_timer * 2.0)
			else:
				global_position = current.lerp(_vault_target, (_vault_timer - 0.5) * 2.0)
		return true

	# Attempt Ledge Grab / Vault
	if not is_on_floor() and velocity.y < 0.0:
		var space = get_world_3d().direct_space_state
		var forward = -character_mesh.global_transform.basis.z
		
		# Ray 1: Chest height (Detect wall)
		var chest_pos = global_position + Vector3(0, 1.0, 0)
		var q_chest = PhysicsRayQueryParameters3D.create(chest_pos, chest_pos + forward * 0.8)
		q_chest.collision_mask = 1
		
		if space.intersect_ray(q_chest):
			# Ray 2: Head height (Check space above wall)
			var head_pos = global_position + Vector3(0, 2.0, 0)
			var q_head = PhysicsRayQueryParameters3D.create(head_pos, head_pos + forward * 0.8)
			q_head.collision_mask = 1
			
			if not space.intersect_ray(q_head):
				# Ray 3: Downward from above wall (Find exact top surface)
				var down_start = head_pos + forward * 0.8
				var q_down = PhysicsRayQueryParameters3D.create(down_start, down_start + Vector3(0, -1.0, 0))
				q_down.collision_mask = 1
				var hit = space.intersect_ray(q_down)
				
				if hit and Input.is_action_pressed("jump"): # Must hold jump to vault
					is_vaulting = true
					_vault_timer = 0.0
					_vault_target = hit.position
					velocity = Vector3.ZERO
					print("Vaulting!")
					return true
					
	# Roof Sliding
	if is_on_floor():
		var floor_n = get_floor_normal()
		var angle = rad_to_deg(acos(floor_n.dot(Vector3.UP)))
		
		# If on a slant, and we press crouch (or slide action)
		if angle > 5.0 and Input.is_action_pressed("crouch"): # Note: Need to map 'crouch' in Godot InputMap
			is_sliding = true
			var slide_dir = Vector3(floor_n.x, 0, floor_n.z).normalized()
			# Accelerate down the roof
			velocity.x += slide_dir.x * 20.0 * delta
			velocity.z += slide_dir.z * 20.0 * delta
		else:
			is_sliding = false
			
	return false

# ================================================================
# HEALTH & DAMAGE (Server-Authoritative)
# ================================================================
# VEHICLES
# ================================================================
func enter_vehicle(vehicle: Node3D) -> void:
	current_vehicle = vehicle
	character_mesh.visible = false
	if loadout_manager:
		var active = loadout_manager.get_active_tool()
		if active:
			active.visible = false
			
	collision_layer = 0
	collision_mask = 0

func exit_vehicle(ejected: bool = false) -> void:
	if not current_vehicle: return
	
	if current_vehicle and "driver" in current_vehicle:
		current_vehicle.driver = null
		
	current_vehicle = null
	character_mesh.visible = true
	
	if loadout_manager:
		var active = loadout_manager.get_active_tool()
		if active:
			active.visible = true
			
	collision_layer = 2
	collision_mask = 1 | 4 | 8
	
	# Pop out!
	global_position += Vector3(0, 1.5, 0)
	
	if ejected:
		print("Player Ejected!")
		velocity = Vector3(0, 15.0, 0) - camera_pivot.basis.z * 10.0
	else:
		velocity = Vector3(0, 5.0, 0)

# ================================================================

## Called by the server when this character takes confirmed damage
func take_damage(amount: float, from_peer_id: int = 1) -> void:
	if not is_alive:
		return

	health -= amount
	health = max(health, 0.0)
	
	if health_bar:
		health_bar.value = health
	if overhead_hp_bar:
		overhead_hp_bar.value = health
		
	if damage_flash:
		damage_flash.color.a = 0.5
		var tween = create_tween()
		tween.tween_property(damage_flash, "color:a", 0.0, 0.3)

	if health <= 0.0:
		_die(from_peer_id)

var stuck_nails: int = 0
var _stuck_nail_timer: float = 0.0

var is_tarred: bool = false
var _tar_timer: float = 0.0
var is_ignited: bool = false
var _ignite_timer: float = 0.0
var _ignite_tick: float = 0.0

func add_stuck_nail() -> void:
	stuck_nails += 1
	_stuck_nail_timer = 5.0 # Nails fall out after 5 seconds
	print(name, " has ", stuck_nails, " nails stuck in them!")

func consume_stuck_nails() -> int:
	var count = stuck_nails
	stuck_nails = 0
	return count

func apply_tar() -> void:
	is_tarred = true
	_tar_timer = 4.0
	print(name, " is covered in TAR!")

func ignite() -> void:
	if is_tarred:
		is_ignited = true
		_ignite_timer = 3.0 # Burn for 3 seconds
		is_tarred = false # Tar is consumed by the fire
		print(name, " has IGNITED!")
	else:
		# Mini burn if not tarred
		take_damage(5.0, -1)
func heal(amount: float) -> void:
	if not is_alive: return
	health += amount
	health = min(health, max_health)
	
	if health_bar:
		health_bar.value = health
	if overhead_hp_bar:
		overhead_hp_bar.value = health
	print("Healed for ", amount, ". Current health: ", health)

## Called when health reaches zero
func _die(killer_peer_id: int) -> void:
	is_alive = false
	if loadout_manager:
		loadout_manager.drop_all()
	
	# Rotate them over to look "dead"
	rotation_degrees.x = 90
	
	if overhead_hp_bar:
		overhead_hp_bar.hide()
	
	print("[Player %d] KO'd by Player %d!" % [owning_peer_id, killer_peer_id])
	
	# If this is a dummy NPC, auto-respawn after 2 seconds
	if owning_peer_id == -1:
		await get_tree().create_timer(2.0).timeout
		rotation_degrees.x = 0
		respawn(global_position + Vector3(0, 2, 0))


## Respawn the character at a given position
func respawn(spawn_position: Vector3) -> void:
	health = max_health
	is_alive = true
	global_position = spawn_position
	velocity = Vector3.ZERO
	
	if health_bar:
		health_bar.value = health
	if overhead_hp_bar:
		overhead_hp_bar.show()
		overhead_hp_bar.value = health
		
	# Re-equip default class if we have a team manager setup later.
	# For now, rely on setup_class being called again.

# Team and Class
var current_team: int = -1
var current_class_enum: int = -1

# Inventory and Skills
var supplies: int = 100
var max_supplies: int = 100
var special_ammo: Dictionary = {
	"rotten_fruit": 0,
	"beehive": 0,
	"stinkbomb": 0
}
var skill_cooldowns: Array[float] = [0.0, 0.0]

var zoom_speed_mult: float = 1.0 # Modified by weapons when aiming

func _apply_class_stats() -> void:
	# Default (Medium Class)
	max_jumps = 1
	move_speed = 6.0
	jump_force = 9.0
	sprint_multiplier = 1.4
	
	# Group classes by weight for easier baseline stats
	var is_light = false
	var is_heavy = false
	
	if current_team == 0: # ROOFERS
		if current_class_enum in [TeamManager.RooferClass.APPRENTICE, TeamManager.RooferClass.SHINGLE_SLINGER]:
			is_light = true
		elif current_class_enum in [TeamManager.RooferClass.TAR_KING, TeamManager.RooferClass.HVAC_TECH, TeamManager.RooferClass.MAG_SWEEP]:
			is_heavy = true
			
	elif current_team == 1: # LANDSCAPERS
		if current_class_enum in [TeamManager.LandscaperClass.CLIMBER, TeamManager.LandscaperClass.TRIMMER]:
			is_light = true
		elif current_class_enum in [TeamManager.LandscaperClass.LUMBERJACK, TeamManager.LandscaperClass.MOWER, TeamManager.LandscaperClass.SPRINKLER]:
			is_heavy = true

	# Apply archetype base stats
	if is_light:
		max_jumps = 2           # Double jump for all light classes
		move_speed = 6.5        # Faster base speed
		sprint_multiplier = 1.8 # Much faster sprint
		jump_force = 9.5
	elif is_heavy:
		max_jumps = 1
		move_speed = 5.0
		sprint_multiplier = 1.3 # Sluggish sprint
		jump_force = 8.5
		
	# Specific Class Overrides
	if current_team == 1 and current_class_enum == TeamManager.LandscaperClass.CLIMBER:
		max_jumps = 3 # Climber gets TRIPLE jump!
		jump_force = 10.0
		move_speed = 6.8
		sprint_multiplier = 1.85

## Set up the initial class loadout
func setup_class(team: int, class_enum: int) -> void:
	current_team = team
	current_class_enum = class_enum
	_apply_class_stats()
	
	if not loadout_manager:
		await ready
		
	loadout_manager.drop_all()
	
	if team == 0: # Roofers
		if class_enum == TeamManager.RooferClass.NAILER:
			var pry_bar = load("res://scripts/weapons/melee/pry_bar.gd").new()
			var nailgun = load("res://scripts/weapons/ranged/nailgun.gd").new()
			var ladder = load("res://scripts/weapons/gadgets/extension_ladder_tool.gd").new()
			
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, pry_bar)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, nailgun)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, ladder)
		elif class_enum == TeamManager.RooferClass.FOREMAN:
			var m = load("res://scripts/weapons/melee/foreman_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/foreman_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/foreman_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.RooferClass.TAR_KING:
			var m = load("res://scripts/weapons/melee/tar_king_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/tar_king_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/tar_king_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.RooferClass.SHINGLE_SLINGER:
			var m = load("res://scripts/weapons/melee/shingle_slinger_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/shingle_slinger_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/shingle_slinger_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.RooferClass.GUTTER_SNIPER:
			var m = load("res://scripts/weapons/melee/gutter_sniper_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/gutter_sniper_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/gutter_sniper_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.RooferClass.CLEANUP_GUY:
			var m = load("res://scripts/weapons/melee/cleanup_guy_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/cleanup_guy_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/cleanup_guy_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.RooferClass.APPRENTICE:
			var m = load("res://scripts/weapons/melee/apprentice_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/apprentice_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/apprentice_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.RooferClass.MAG_SWEEP:
			var m = load("res://scripts/weapons/melee/mag_sweep_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/mag_sweep_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/mag_sweep_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.RooferClass.ELECTRICIAN:
			var m = load("res://scripts/weapons/melee/electrician_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/electrician_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/electrician_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.RooferClass.HVAC_TECH:
			var m = load("res://scripts/weapons/melee/hvac_tech_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/hvac_tech_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/hvac_tech_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
	
	elif team == 1: # Landscapers
		if class_enum == TeamManager.LandscaperClass.GARDENER:
			var knife = load("res://scripts/weapons/melee/pocket_knife.gd").new()
			var slingshot = load("res://scripts/weapons/ranged/slingshot.gd").new()
			var ladder = load("res://scripts/weapons/gadgets/extension_ladder_tool.gd").new()
			
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, knife)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, slingshot)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, ladder)
		elif class_enum == TeamManager.LandscaperClass.LUMBERJACK:
			var m = load("res://scripts/weapons/melee/lumberjack_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/lumberjack_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/lumberjack_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.LandscaperClass.BOTANIST:
			var m = load("res://scripts/weapons/melee/botanist_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/botanist_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/botanist_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.LandscaperClass.MOWER:
			var m = load("res://scripts/weapons/melee/mower_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/mower_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/mower_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.LandscaperClass.TRIMMER:
			var m = load("res://scripts/weapons/melee/trimmer_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/trimmer_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/trimmer_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.LandscaperClass.BLOWER:
			var m = load("res://scripts/weapons/melee/blower_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/blower_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/blower_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.LandscaperClass.RAKER:
			var m = load("res://scripts/weapons/melee/raker_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/raker_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/raker_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.LandscaperClass.SPRINKLER:
			var m = load("res://scripts/weapons/melee/sprinkler_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/sprinkler_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/sprinkler_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.LandscaperClass.CLIMBER:
			var m = load("res://scripts/weapons/melee/climber_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/climber_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/climber_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
		elif class_enum == TeamManager.LandscaperClass.HOBBYIST:
			var m = load("res://scripts/weapons/melee/hobbyist_melee.gd").new()
			var r = load("res://scripts/weapons/ranged/hobbyist_ranged.gd").new()
			var g = load("res://scripts/weapons/gadgets/hobbyist_gadget.gd").new()
			loadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
			loadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
			loadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)

func _is_local_player() -> bool:
	return owning_peer_id == multiplayer.get_unique_id()
