class_name LoadoutManager
extends Node

# Emitted when a weapon slot changes, useful for updating the HUD
signal slot_changed(slot_index: int, tool: BaseTool)

enum Slot {
	MELEE = 0,
	RANGED = 1,
	GADGET = 2
}

var _slots: Array[BaseTool] = [null, null, null]
var _active_slot: int = Slot.RANGED

# Reference to the node where the actual weapon visuals/hitboxes will be attached
var _hand_attachment_point: Node3D

func initialize(hand_attachment: Node3D) -> void:
	_hand_attachment_point = hand_attachment

func set_tool(slot: int, new_tool: BaseTool) -> void:
	if slot < 0 or slot >= _slots.size():
		return
		
	# Drop existing droppable tool if replacing
	if _slots[slot] != null:
		_slots[slot].drop()
		
	_slots[slot] = new_tool
	
	if new_tool != null:
		# Reparent the tool to the hand attachment point
		if new_tool.get_parent():
			new_tool.get_parent().remove_child(new_tool)
		_hand_attachment_point.add_child(new_tool)
		new_tool.position = Vector3.ZERO
		new_tool.rotation = Vector3.ZERO
		
		# Immediately freeze it so unequipped items don't fall to the floor
		if new_tool.has_method("_set_physical_state"):
			new_tool._set_physical_state(false)
		
		# If this is the active slot, equip it, otherwise hide it
		if slot == _active_slot:
			new_tool.equip(get_parent())
		else:
			new_tool.unequip()
			
	slot_changed.emit(slot, new_tool)

func get_active_tool() -> BaseTool:
	var tool = _slots[_active_slot]
	if tool != null and not is_instance_valid(tool):
		_slots[_active_slot] = null
		tool = null
		# Automatically fall back to melee
		set_active_slot(0)
		return _slots[0]
	return tool

func use_primary_action_pressed() -> void:
	var tool = get_active_tool()
	if tool:
		tool.primary_action_pressed()

func use_primary_action_released() -> void:
	var tool = get_active_tool()
	if tool:
		tool.primary_action_released()

func use_secondary_action() -> void:
	var tool = get_active_tool()
	if tool:
		tool.secondary_action()

func set_active_slot(slot: int) -> void:
	print("LoadoutManager: Requesting slot swap to ", slot)
	if slot < 0 or slot >= _slots.size() or slot == _active_slot:
		print("LoadoutManager: Swap rejected (invalid or already active).")
		return
		
	# Hide old
	if _slots[_active_slot]:
		print("LoadoutManager: Unequipping old tool: ", _slots[_active_slot].tool_name)
		_slots[_active_slot].unequip()
		
	_active_slot = slot
	
	# Show new
	if _slots[_active_slot]:
		print("LoadoutManager: Equipping new tool: ", _slots[_active_slot].tool_name)
		_slots[_active_slot].equip(get_parent())
	else:
		print("LoadoutManager: No tool in slot ", slot)

# In the Rule of 3, Melee and Gadget might have dedicated keys instead of just scrolling to them
func quick_use_melee() -> void:
	if _slots[Slot.MELEE]:
		set_active_slot(Slot.MELEE)
		_slots[Slot.MELEE].primary_action()

func quick_use_gadget() -> void:
	if _slots[Slot.GADGET]:
		set_active_slot(Slot.GADGET)
		_slots[Slot.GADGET].primary_action()

# Drop all droppable items (called on death)
func drop_all() -> void:
	for i in range(_slots.size()):
		if _slots[i] != null and _slots[i].is_droppable:
			_slots[i].drop()
			_slots[i] = null
			slot_changed.emit(i, null)
