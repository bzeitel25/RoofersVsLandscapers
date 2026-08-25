extends Node3D

@onready var player: CharacterBody3D = $Player

# UI Elements
var player_class_dropdown: OptionButton
var npc_class_dropdown: OptionButton
var item_dropdown: OptionButton

# Data mapping for dropdowns
var class_options = [] # Array of dicts {team: int, class_enum: int, name: String}
var item_options = [
	{"name": "Big Tony's Rocket Mower", "path": "res://scripts/vehicles/rocket_mower.gd"},
	{"name": "Pry Bar (Melee)", "path": "res://scripts/weapons/melee/pry_bar.gd"},
	{"name": "Pocket Knife (Melee)", "path": "res://scripts/weapons/melee/pocket_knife.gd"},
	{"name": "Nailgun (Ranged)", "path": "res://scripts/weapons/ranged/nailgun.gd"},
	{"name": "Slingshot (Ranged)", "path": "res://scripts/weapons/ranged/slingshot.gd"},
	{"name": "Extension Ladder (Gadget)", "path": "res://scripts/weapons/gadgets/extension_ladder_tool.gd"},
	{"name": "[Supply] Universal Ammo Box", "path": "res://scripts/items/supply_box.gd"},
	{"name": "[Supply] Health Pack", "path": "res://scripts/items/health_pack.gd"},
	{"name": "[R] Foreman Melee", "path": "res://scripts/weapons/melee/foreman_melee.gd"},
	{"name": "[R] Foreman Ranged", "path": "res://scripts/weapons/ranged/foreman_ranged.gd"},
	{"name": "[R] Foreman Gadget", "path": "res://scripts/weapons/gadgets/foreman_gadget.gd"},
	{"name": "[R] Tar King Melee", "path": "res://scripts/weapons/melee/tar_king_melee.gd"},
	{"name": "[R] Tar King Ranged", "path": "res://scripts/weapons/ranged/tar_king_ranged.gd"},
	{"name": "[R] Tar King Gadget", "path": "res://scripts/weapons/gadgets/tar_king_gadget.gd"},
	{"name": "[R] Shingle Slinger Melee", "path": "res://scripts/weapons/melee/shingle_slinger_melee.gd"},
	{"name": "[R] Shingle Slinger Ranged", "path": "res://scripts/weapons/ranged/shingle_slinger_ranged.gd"},
	{"name": "[R] Shingle Slinger Gadget", "path": "res://scripts/weapons/gadgets/shingle_slinger_gadget.gd"},
	{"name": "[R] Gutter Sniper Melee", "path": "res://scripts/weapons/melee/gutter_sniper_melee.gd"},
	{"name": "[R] Gutter Sniper Ranged", "path": "res://scripts/weapons/ranged/gutter_sniper_ranged.gd"},
	{"name": "[R] Gutter Sniper Gadget", "path": "res://scripts/weapons/gadgets/gutter_sniper_gadget.gd"},
	{"name": "[R] Cleanup Guy Melee", "path": "res://scripts/weapons/melee/cleanup_guy_melee.gd"},
	{"name": "[R] Cleanup Guy Ranged", "path": "res://scripts/weapons/ranged/cleanup_guy_ranged.gd"},
	{"name": "[R] Cleanup Guy Gadget", "path": "res://scripts/weapons/gadgets/cleanup_guy_gadget.gd"},
	{"name": "[R] Apprentice Melee", "path": "res://scripts/weapons/melee/apprentice_melee.gd"},
	{"name": "[R] Apprentice Ranged", "path": "res://scripts/weapons/ranged/apprentice_ranged.gd"},
	{"name": "[R] Apprentice Gadget", "path": "res://scripts/weapons/gadgets/apprentice_gadget.gd"},
	{"name": "[R] Mag Sweep Melee", "path": "res://scripts/weapons/melee/mag_sweep_melee.gd"},
	{"name": "[R] Mag Sweep Ranged", "path": "res://scripts/weapons/ranged/mag_sweep_ranged.gd"},
	{"name": "[R] Mag Sweep Gadget", "path": "res://scripts/weapons/gadgets/mag_sweep_gadget.gd"},
	{"name": "[R] Electrician Melee", "path": "res://scripts/weapons/melee/electrician_melee.gd"},
	{"name": "[R] Electrician Ranged", "path": "res://scripts/weapons/ranged/electrician_ranged.gd"},
	{"name": "[R] Electrician Gadget", "path": "res://scripts/weapons/gadgets/electrician_gadget.gd"},
	{"name": "[R] Hvac Tech Melee", "path": "res://scripts/weapons/melee/hvac_tech_melee.gd"},
	{"name": "[R] Hvac Tech Ranged", "path": "res://scripts/weapons/ranged/hvac_tech_ranged.gd"},
	{"name": "[R] Hvac Tech Gadget", "path": "res://scripts/weapons/gadgets/hvac_tech_gadget.gd"},
	{"name": "[L] Lumberjack Melee", "path": "res://scripts/weapons/melee/lumberjack_melee.gd"},
	{"name": "[L] Lumberjack Ranged", "path": "res://scripts/weapons/ranged/lumberjack_ranged.gd"},
	{"name": "[L] Lumberjack Gadget", "path": "res://scripts/weapons/gadgets/lumberjack_gadget.gd"},
	{"name": "[L] Botanist Melee", "path": "res://scripts/weapons/melee/botanist_melee.gd"},
	{"name": "[L] Botanist Ranged", "path": "res://scripts/weapons/ranged/botanist_ranged.gd"},
	{"name": "[L] Botanist Gadget", "path": "res://scripts/weapons/gadgets/botanist_gadget.gd"},
	{"name": "[L] Mower Melee", "path": "res://scripts/weapons/melee/mower_melee.gd"},
	{"name": "[L] Mower Ranged", "path": "res://scripts/weapons/ranged/mower_ranged.gd"},
	{"name": "[L] Mower Gadget", "path": "res://scripts/weapons/gadgets/mower_gadget.gd"},
	{"name": "[L] Trimmer Melee", "path": "res://scripts/weapons/melee/trimmer_melee.gd"},
	{"name": "[L] Trimmer Ranged", "path": "res://scripts/weapons/ranged/trimmer_ranged.gd"},
	{"name": "[L] Trimmer Gadget", "path": "res://scripts/weapons/gadgets/trimmer_gadget.gd"},
	{"name": "[L] Blower Melee", "path": "res://scripts/weapons/melee/blower_melee.gd"},
	{"name": "[L] Blower Ranged", "path": "res://scripts/weapons/ranged/blower_ranged.gd"},
	{"name": "[L] Blower Gadget", "path": "res://scripts/weapons/gadgets/blower_gadget.gd"},
	{"name": "[L] Raker Melee", "path": "res://scripts/weapons/melee/raker_melee.gd"},
	{"name": "[L] Raker Ranged", "path": "res://scripts/weapons/ranged/raker_ranged.gd"},
	{"name": "[L] Raker Gadget", "path": "res://scripts/weapons/gadgets/raker_gadget.gd"},
	{"name": "[L] Sprinkler Melee", "path": "res://scripts/weapons/melee/sprinkler_melee.gd"},
	{"name": "[L] Sprinkler Ranged", "path": "res://scripts/weapons/ranged/sprinkler_ranged.gd"},
	{"name": "[L] Sprinkler Gadget", "path": "res://scripts/weapons/gadgets/sprinkler_gadget.gd"},
	{"name": "[L] Climber Melee", "path": "res://scripts/weapons/melee/climber_melee.gd"},
	{"name": "[L] Climber Ranged", "path": "res://scripts/weapons/ranged/climber_ranged.gd"},
	{"name": "[L] Climber Gadget", "path": "res://scripts/weapons/gadgets/climber_gadget.gd"},
	{"name": "[L] Hobbyist Melee", "path": "res://scripts/weapons/melee/hobbyist_melee.gd"},
	{"name": "[L] Hobbyist Ranged", "path": "res://scripts/weapons/ranged/hobbyist_ranged.gd"},
	{"name": "[L] Hobbyist Gadget", "path": "res://scripts/weapons/gadgets/hobbyist_gadget.gd"}
]

# We will dynamically duplicate the player node since it's not a saved scene yet

var ui_canvas: CanvasLayer

func _ready() -> void:
	# Default to player control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	_populate_class_data()
	_build_training_ui()
	
	# Start player as Gardener by default
	player.setup_class(1, TeamManager.LandscaperClass.GARDENER)
	
	# Spawn a resupply box nearby for unlimited testing
	var SupplyBox = load("res://scripts/items/supply_box.gd")
	var box = SupplyBox.new()
	box.infinite_respawn = true
	add_child(box)
	box.global_position = player.global_position + Vector3(0, 0, -4.0) # 4 meters in front of spawn

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if ui_canvas.visible:
			ui_canvas.hide()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			ui_canvas.show()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _populate_class_data() -> void:
	# Load Roofers
	for key in TeamManager.RooferClass.keys():
		class_options.append({
			"team": 0,
			"class_enum": TeamManager.RooferClass[key],
			"name": "[Roofer] " + key.capitalize()
		})
	# Load Landscapers
	for key in TeamManager.LandscaperClass.keys():
		class_options.append({
			"team": 1,
			"class_enum": TeamManager.LandscaperClass[key],
			"name": "[Landscaper] " + key.capitalize()
		})

func _build_training_ui() -> void:
	ui_canvas = CanvasLayer.new()
	ui_canvas.hide() # Hidden by default
	add_child(ui_canvas)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 20)
	ui_canvas.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "TRAINING ROOM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())
	
	# --- PLAYER SETUP ---
	var lbl_player = Label.new()
	lbl_player.text = "Your Class:"
	vbox.add_child(lbl_player)
	
	player_class_dropdown = OptionButton.new()
	for opt in class_options:
		player_class_dropdown.add_item(opt["name"])
	vbox.add_child(player_class_dropdown)
	
	var apply_player_btn = Button.new()
	apply_player_btn.text = "Change Class"
	apply_player_btn.pressed.connect(_on_change_player_class)
	vbox.add_child(apply_player_btn)
	vbox.add_child(HSeparator.new())
	
	# --- NPC SETUP ---
	var lbl_npc = Label.new()
	lbl_npc.text = "NPC Class:"
	vbox.add_child(lbl_npc)
	
	npc_class_dropdown = OptionButton.new()
	for opt in class_options:
		npc_class_dropdown.add_item(opt["name"])
	vbox.add_child(npc_class_dropdown)
	
	var spawn_npc_btn = Button.new()
	spawn_npc_btn.text = "Spawn Dummy NPC"
	spawn_npc_btn.pressed.connect(_on_spawn_npc)
	vbox.add_child(spawn_npc_btn)
	vbox.add_child(HSeparator.new())
	
	# --- ITEM SPAWNER ---
	var lbl_item = Label.new()
	lbl_item.text = "Spawn Item:"
	vbox.add_child(lbl_item)
	
	item_dropdown = OptionButton.new()
	for item in item_options:
		item_dropdown.add_item(item["name"])
	vbox.add_child(item_dropdown)
	
	var spawn_item_btn = Button.new()
	spawn_item_btn.text = "Drop Item"
	spawn_item_btn.pressed.connect(_on_spawn_item)
	vbox.add_child(spawn_item_btn)
	
	vbox.add_child(HSeparator.new())
	var hint = Label.new()
	hint.text = "Press ESC to toggle mouse."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

func _on_change_player_class() -> void:
	var idx = player_class_dropdown.selected
	var data = class_options[idx]
	player.setup_class(data["team"], data["class_enum"])
	ui_canvas.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_spawn_npc() -> void:
	var idx = npc_class_dropdown.selected
	var data = class_options[idx]
	
	# Duplicate the player node
	var npc = player.duplicate(7) # 7 = DUPLICATE_SIGNALS | DUPLICATE_GROUPS | DUPLICATE_SCRIPTS
	npc.owning_peer_id = -1 # Makes them a dummy that doesn't process inputs
	
	# We need to remove the local HUD if it was duplicated
	for child in npc.get_children():
		if child is CanvasLayer:
			child.queue_free()
	
	# Spawn slightly in front of the player
	var forward = -player.camera_pivot.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	npc.position = player.position + forward * 4.0
	npc.position.y += 2.0 # Drop from slightly above
	
	add_child(npc)
	npc.setup_class(data["team"], data["class_enum"])
	ui_canvas.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_spawn_item() -> void:
	var idx = item_dropdown.selected
	var item_data = item_options[idx]
	var item_script = load(item_data["path"])
	var item_instance = item_script.new()
	
	add_child(item_instance)
	
	# Drop it slightly in front of the player
	var forward = -player.camera_pivot.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	item_instance.global_position = player.global_position + forward * 2.0
	item_instance.global_position.y += 1.0 # Drop from waist height
	
	ui_canvas.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
