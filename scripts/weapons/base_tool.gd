class_name BaseTool
extends RigidBody3D

@export var tool_name: String = "Base Tool"
@export var damage: float = 10.0
@export var cooldown: float = 0.5
@export var is_droppable: bool = true
@export var supply_cost: int = 0
@export var max_ammo: int = -1 # -1 means infinite/doesn't use ammo
@export var slot_type: int = 1 # 0: Melee, 1: Ranged, 2: Gadget

var current_ammo: int = -1
var _cooldown_timer: float = 0.0
var wielder: Node3D = null

func _ready() -> void:
	if current_ammo == -1:
		current_ammo = max_ammo
		
	# Tools are Layer 7 (64) so they can be picked up, and only collide with World (1)
	collision_layer = 64
	collision_mask = 1
	
	# Add a default physics collision shape so dropped tools don't fall through the floor
	var base_col = CollisionShape3D.new()
	var base_shape = BoxShape3D.new()
	base_shape.size = Vector3(0.6, 0.6, 0.6)
	base_col.shape = base_shape
	base_col.name = "BaseCollision"
	add_child(base_col)
	
	# Default to physical if not held
	if not get_parent() or not get_parent().name == "HandAttachment":
		_set_physical_state(true)

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

func primary_action() -> void:
	# Virtual method to be overridden by subclasses (legacy, called on pressed)
	pass

func primary_action_pressed() -> void:
	# Called when button goes down
	primary_action() # Fallback for tools that don't implement press/release

func primary_action_released() -> void:
	# Called when button goes up
	pass

func secondary_action() -> void:
	pass

func can_use() -> bool:
	if _cooldown_timer > 0.0:
		return false
	if max_ammo > 0 and current_ammo <= 0:
		return false
	if supply_cost > 0 and wielder and "supplies" in wielder:
		if wielder.supplies < supply_cost:
			print("Not enough supplies! Need ", supply_cost, " have ", wielder.supplies)
			return false
	return true

func consume_supplies() -> void:
	if supply_cost > 0 and wielder and "supplies" in wielder:
		wielder.supplies -= supply_cost
		print("Consumed ", supply_cost, " supplies. Remaining: ", wielder.supplies)

func consume_ammo(amount: int = 1) -> void:
	if max_ammo > 0:
		current_ammo -= amount
		current_ammo = max(0, current_ammo)
		print(tool_name, " Ammo: ", current_ammo, "/", max_ammo)

func _start_cooldown() -> void:
	_cooldown_timer = cooldown
	consume_supplies()
	consume_ammo(1)

func stop_use(character: Node3D) -> void:
	pass

func alt_use(character: Node3D) -> void:
	pass

# Called when an item is picked up
func equip(new_wielder: Node3D) -> void:
	wielder = new_wielder
	_set_physical_state(false)
	show()

func unequip() -> void:
	hide()
	
func drop() -> void:
	if not is_droppable:
		return
	
	print(tool_name, " dropped!")
	wielder = null
	
	# Reparent to the main level/world
	var world = get_tree().current_scene
	get_parent().remove_child(self)
	world.add_child(self)
	
	_set_physical_state(true)
	
	# Apply a small pop-out impulse
	var random_dir = Vector3(randf_range(-1, 1), 1.0, randf_range(-1, 1)).normalized()
	apply_impulse(random_dir * 3.0)

func _set_physical_state(is_physical: bool) -> void:
	# When held, freeze physics (kinematic mode) and disable collision
	freeze = not is_physical
	if freeze:
		freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	else:
		freeze_mode = RigidBody3D.FREEZE_MODE_STATIC # Revert to default when dropped, though freeze is false anyway
	
	# Find all collision shapes and toggle them
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = not is_physical
