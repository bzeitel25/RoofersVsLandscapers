class_name BaseMelee
extends "res://scripts/weapons/base_tool.gd"

@export var swing_duration: float = 0.2
@export var swing_angle: float = 80.0
@export var is_thrust: bool = false

# Weapon Effects
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0
@export var bleed_chance: float = 0.0
@export var bleed_on_crit: bool = false
@export var stun_chance: float = 0.0
@export var root_chance: float = 0.0
@export var burn_chance: float = 0.0
@export var slow_chance: float = 0.0
@export var lifesteal_percent: float = 0.0
@export var knockback_multiplier: float = 1.0

var hitbox_area: Area3D
var hitbox_col: CollisionShape3D
var is_swinging: bool = false
var _rest_position: Vector3 = Vector3.ZERO
var _rest_rotation: Vector3 = Vector3.ZERO
var _hits_this_swing: Array = [] # Track who we hit per swing to avoid double damage

# Combo System
# Each combo step is a Dictionary with:
#   "duration"   - total time for this attack step
#   "poses"      - Array of pose keyframes:
#       {"t": 0.0-1.0, "pos": Vector3, "rot": Vector3}
#       t=0.0 is start, t=1.0 is end.
var combo_sequence: Array[Dictionary] = []
var combo_step: int = 0
var combo_timer: float = 0.0

func _ready() -> void:
	slot_type = 0 # Melee
	super._ready()
	
	# Setup Hitbox Area
	hitbox_area = Area3D.new()
	hitbox_area.collision_layer = 0
	hitbox_area.collision_mask = 3 # Players (Layer 1 or 2)
	add_child(hitbox_area)
	
	hitbox_col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.8, 1.5, 0.8)
	hitbox_col.shape = box
	hitbox_col.position = Vector3(0, 0.5, 0)
	hitbox_col.disabled = true
	hitbox_area.add_child(hitbox_col)
	
	hitbox_area.body_entered.connect(_on_hitbox_body_entered)
	
	# Create a basic visual for the weapon (subclasses override this)
	var mesh_inst = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.2, 0.8, 0.2)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.4)
	mesh.material = mat
	mesh_inst.mesh = mesh
	mesh_inst.position = Vector3(0, 0.5, 0)
	add_child(mesh_inst)

func _process(delta: float) -> void:
	super._process(delta)
	
	# Reset combo if idle for too long
	if not is_swinging and combo_step > 0:
		combo_timer += delta
		if combo_timer > 1.5:
			combo_step = 0

func primary_action() -> void:
	if can_use() and wielder and not is_swinging:
		_perform_attack()
		_start_cooldown()

# --- Combo Generation ---

func _generate_combo() -> void:
	if "whip" in tool_name.to_lower():
		_generate_whip_combo()
	elif _is_heavy_weapon():
		_generate_heavy_combo()
	else:
		_generate_light_combo()

func _is_heavy_weapon() -> bool:
	var heavy_words = ["axe", "hammer", "wrench", "bar", "sledge", "mop", "trimmer", "shovel", "magnet", "pipe", "cable"]
	for word in heavy_words:
		if word in tool_name.to_lower():
			return true
	return swing_duration >= 0.4

func _generate_whip_combo() -> void:
	# Unique 1-hit Whip Combo: massive crack forward
	combo_sequence = [
		{
			"duration": 1.1,
			"poses": [
				{"t": 0.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO},
				# Wind up: pull arm way back and high
				{"t": 0.25, "pos": Vector3(0.5, 0.6, 0.4), "rot": Vector3(70, -20, -10)},
				# WHIP CRACK: arm snaps violently forward, extending reach by 1.8 meters!
				{"t": 0.5, "pos": Vector3(-0.2, -0.4, -1.8), "rot": Vector3(-110, 10, 0)},
				# Hold briefly to signify the crack
				{"t": 0.65, "pos": Vector3(-0.2, -0.4, -1.8), "rot": Vector3(-110, 10, 0)},
				# Recovery: pull back
				{"t": 1.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO}
			]
		}
	]

func _generate_heavy_combo() -> void:
	# Heavy 2-hit: Overhead slam, then full horizontal sweep
	combo_sequence = [
		{
			# Hit 1: Massive overhead slam
			"duration": 0.85,
			"poses": [
				{"t": 0.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO},
				# Wind up: weapon raises high over right shoulder
				{"t": 0.18, "pos": Vector3(0.15, 1.0, 0.3), "rot": Vector3(60, -15, 0)},
				# SLAM: crashes down hard in front of the body
				{"t": 0.45, "pos": Vector3(-0.1, -0.8, -0.9), "rot": Vector3(-120, 5, 0)},
				# Recovery: drag it back up to ready
				{"t": 1.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO}
			]
		},
		{
			# Hit 2: Full wide horizontal sweep left-to-right
			"duration": 0.95,
			"poses": [
				{"t": 0.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO},
				# Wind up: weapon cocks far out to the left
				{"t": 0.18, "pos": Vector3(-0.8, 0.3, 0.15), "rot": Vector3(-15, 60, 25)},
				# SWEEP: weapon arcs fully across from left to far right
				{"t": 0.48, "pos": Vector3(0.9, -0.15, -0.5), "rot": Vector3(-25, -80, -25)},
				# Recovery
				{"t": 1.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO}
			]
		}
	]

func _generate_light_combo() -> void:
	# Light 3-hit: Diagonal slash TR->BL, diagonal slash TL->BR, thrust
	combo_sequence = [
		{
			# Slash 1: Top-Right to Bottom-Left diagonal
			"duration": 0.30,
			"poses": [
				{"t": 0.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO},
				# Snap wind up: weapon flicks to upper right (very fast)
				{"t": 0.08, "pos": Vector3(0.3, 0.35, 0.0), "rot": Vector3(15, -25, -25)},
				# Slash across: sweeps diagonally down-left and forward
				{"t": 0.5,  "pos": Vector3(-0.4, -0.3, -0.4), "rot": Vector3(-60, 40, 30)},
				# Recovery
				{"t": 1.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO}
			]
		},
		{
			# Slash 2: Top-Left to Bottom-Right diagonal (mirror)
			"duration": 0.30,
			"poses": [
				{"t": 0.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO},
				# Snap wind up: weapon flicks to upper left
				{"t": 0.08, "pos": Vector3(-0.3, 0.35, 0.0), "rot": Vector3(15, 25, 25)},
				# Slash across: sweeps diagonally down-right and forward
				{"t": 0.5,  "pos": Vector3(0.4, -0.3, -0.4), "rot": Vector3(-60, -40, -30)},
				# Recovery
				{"t": 1.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO}
			]
		},
		{
			# Thrust: pull back, then lunge forward
			"duration": 0.25,
			"poses": [
				{"t": 0.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO},
				# Snap cock back
				{"t": 0.1,  "pos": Vector3(0.05, 0.1, 0.25), "rot": Vector3(-90, 0, 0)},
				# Lunge: weapon punches straight forward
				{"t": 0.45, "pos": Vector3(0.0, -0.1, -1.0), "rot": Vector3(-90, 0, 0)},
				# Recovery
				{"t": 1.0,  "pos": Vector3.ZERO, "rot": Vector3.ZERO}
			]
		}
	]


# --- Attack Execution ---

func _perform_attack() -> void:
	is_swinging = true
	_hits_this_swing.clear()
	hitbox_col.set_deferred("disabled", false)
	_rest_position = position
	_rest_rotation = rotation_degrees
	combo_timer = 0.0
	
	if combo_sequence.is_empty():
		_generate_combo()
	
	var attack = combo_sequence[combo_step]
	var dur: float = attack["duration"]
	var poses: Array = attack["poses"]
	
	# Sync cooldown so player can click again right when this attack ends
	cooldown = dur
	
	# Build the tween: for each segment, tween position sequentially
	# and tween rotation in parallel with it, so both move together.
	var tween = create_tween()
	
	for i in range(1, poses.size()):
		var prev_pose = poses[i - 1]
		var next_pose = poses[i]
		
		var seg_dur: float = (next_pose["t"] - prev_pose["t"]) * dur
		
		var target_pos: Vector3 = _rest_position + next_pose["pos"]
		var target_rot: Vector3 = _rest_rotation + next_pose["rot"]
		
		# Easing: wind-up is slow-out, strike is fast-in, recovery is slow-out
		var seg_fraction: float = next_pose["t"]
		var ease_type: int
		var trans_type: int
		if seg_fraction <= 0.2:
			# Wind-up segment
			ease_type = Tween.EASE_OUT
			trans_type = Tween.TRANS_SINE
		elif seg_fraction <= 0.6:
			# Strike segment — fast acceleration into it
			ease_type = Tween.EASE_IN
			trans_type = Tween.TRANS_CUBIC
		else:
			# Recovery segment
			ease_type = Tween.EASE_OUT
			trans_type = Tween.TRANS_QUAD
		
		# Position tween chains sequentially after the previous segment
		tween.tween_property(self, "position", target_pos, seg_dur).set_ease(ease_type).set_trans(trans_type)
		# Rotation tween runs in parallel with the position tween above
		tween.parallel().tween_property(self, "rotation_degrees", target_rot, seg_dur).set_ease(ease_type).set_trans(trans_type)
	
	tween.finished.connect(_on_attack_finished)
	
	# Advance combo step
	combo_step += 1
	if combo_step >= combo_sequence.size():
		combo_step = 0


func _on_attack_finished() -> void:
	is_swinging = false
	hitbox_col.set_deferred("disabled", true)
	# Snap cleanly back to rest to avoid floating point drift
	position = _rest_position
	rotation_degrees = _rest_rotation


func _on_hitbox_body_entered(body: Node3D) -> void:
	if not is_swinging or not wielder:
		return
		
	# Don't hit yourself
	if body == wielder:
		return
	
	# Don't hit the same target twice per swing
	if body in _hits_this_swing:
		return
	_hits_this_swing.append(body)
		
	print(tool_name, " hit ", body.name, "!")
	if body.has_method("take_damage"):
		var peer_id = wielder.owning_peer_id if "owning_peer_id" in wielder else 1
		
		# Boss Hammer instantly shatters glass shields
		var final_damage = damage
		if body.is_in_group("foreman_shield") and tool_name == "Boss Hammer":
			final_damage = 999.0
			print("Boss Hammer instantly shattered the glass shield!")
		else:
			# Calculate Standard Critical Hit
			var is_crit = randf() < crit_chance
			if is_crit:
				final_damage *= crit_multiplier
				print("CRITICAL HIT! ", final_damage, " damage!")
		
		body.take_damage(final_damage, peer_id)
		
		# Apply Status Effects (if body supports them)
		if (randf() < bleed_chance or (is_crit and bleed_on_crit)) and body.has_method("apply_bleed"):
			body.apply_bleed(5.0, 3) # 5 damage per tick for 3 ticks
			print("Applied BLEED!")
			
		if randf() < stun_chance and body.has_method("apply_stun"):
			body.apply_stun(1.5) # 1.5 second stun
			print("Applied STUN!")
			
		if randf() < root_chance and body.has_method("apply_slow"):
			body.apply_slow(0.01, 2.0) # 99% slow for 2 seconds acts as a root
			print("Applied ROOT!")
			
		if randf() < burn_chance and body.has_method("apply_burn"):
			body.apply_burn(4.0, 4) # 4 damage for 4 ticks
			print("Applied BURN!")
			
		if randf() < slow_chance and body.has_method("apply_slow"):
			body.apply_slow(0.5, 3.0) # 50% speed for 3 seconds
			print("Applied SLOW!")
			
		if lifesteal_percent > 0.0 and wielder and wielder.has_method("heal"):
			var heal_amount = final_damage * lifesteal_percent
			wielder.heal(heal_amount)
			print("LIFESTEAL! Healed for ", heal_amount)
		
		# Knockback
		if "velocity" in body:
			var knockback_dir = (body.global_position - global_position).normalized()
			knockback_dir.y = 0.5
			var force = 5.0 * knockback_multiplier
			if body.has_method("apply_impulse"):
				body.apply_impulse(knockback_dir * force)
			else:
				body.velocity += knockback_dir * force
