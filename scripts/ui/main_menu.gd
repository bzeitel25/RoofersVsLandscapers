extends Control

var main_panel: PanelContainer
var ip_input: LineEdit
var name_input: LineEdit

var lobby_panel: PanelContainer
var player_list_label: Label
var class_dropdown: OptionButton
var team_dropdown: OptionButton
var start_button: Button

func _ready() -> void:
	if has_node("VBoxContainer"):
		$VBoxContainer.queue_free()
		
	_build_ui()
	NetworkManager.lobby_updated.connect(_on_lobby_updated)
	NetworkManager.connected_to_server.connect(_show_lobby)

func _build_ui() -> void:
	# --- MAIN PANEL ---
	main_panel = PanelContainer.new()
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(main_panel)
	
	var vbox = VBoxContainer.new()
	main_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "ROOFERS VS LANDSCAPERS\nWeb Multiplayer"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())
	
	name_input = LineEdit.new()
	name_input.placeholder_text = "Enter Player Name"
	name_input.text = "Player" + str(randi() % 1000)
	vbox.add_child(name_input)
	
	var host_btn = Button.new()
	host_btn.text = "Host Server"
	host_btn.pressed.connect(_on_host_pressed)
	vbox.add_child(host_btn)
	
	vbox.add_child(HSeparator.new())
	
	ip_input = LineEdit.new()
	ip_input.placeholder_text = "Enter Host IP (e.g., 127.0.0.1)"
	ip_input.text = "127.0.0.1"
	vbox.add_child(ip_input)
	
	var join_btn = Button.new()
	join_btn.text = "Join Server"
	join_btn.pressed.connect(_on_join_pressed)
	vbox.add_child(join_btn)
	
	vbox.add_child(HSeparator.new())
	
	var test_btn = Button.new()
	test_btn.text = "Offline Training"
	test_btn.pressed.connect(_on_test_pressed)
	vbox.add_child(test_btn)
	
	# --- LOBBY PANEL (Hidden initially) ---
	lobby_panel = PanelContainer.new()
	lobby_panel.set_anchors_preset(Control.PRESET_CENTER)
	lobby_panel.hide()
	add_child(lobby_panel)
	
	var lvbox = VBoxContainer.new()
	lobby_panel.add_child(lvbox)
	
	var l_title = Label.new()
	l_title.text = "-- LOBBY --"
	l_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvbox.add_child(l_title)
	
	player_list_label = Label.new()
	player_list_label.text = "Players:\n"
	lvbox.add_child(player_list_label)
	
	lvbox.add_child(HSeparator.new())
	
	team_dropdown = OptionButton.new()
	team_dropdown.add_item("Roofer (Defend)", 0)
	team_dropdown.add_item("Landscaper (Attack)", 1)
	team_dropdown.item_selected.connect(_on_team_selected)
	lvbox.add_child(team_dropdown)
	
	class_dropdown = OptionButton.new()
	# Add some base classes
	class_dropdown.add_item("Foreman", 0)
	class_dropdown.add_item("Tar King", 1)
	class_dropdown.add_item("Gutter Sniper", 2)
	class_dropdown.add_item("Gardener / Botanist", 10)
	class_dropdown.add_item("Leaf Blower", 11)
	class_dropdown.add_item("Lumberjack", 12)
	class_dropdown.item_selected.connect(_on_class_selected)
	lvbox.add_child(class_dropdown)
	
	start_button = Button.new()
	start_button.text = "Start Game"
	start_button.pressed.connect(_on_start_game)
	lvbox.add_child(start_button)

func _on_host_pressed() -> void:
	NetworkManager.host_game(7350)
	_show_lobby()

func _on_join_pressed() -> void:
	NetworkManager.join_game(ip_input.text, 7350)

func _show_lobby() -> void:
	main_panel.hide()
	lobby_panel.show()
	start_button.visible = NetworkManager.is_host
	# Send name to server
	NetworkManager.register_player.rpc_id(1, multiplayer.get_unique_id(), name_input.text)
	_on_team_selected(0)
	_on_class_selected(0)

func _on_team_selected(idx: int) -> void:
	var team = team_dropdown.get_item_id(idx)
	NetworkManager.set_player_team.rpc_id(1, multiplayer.get_unique_id(), team)

func _on_class_selected(idx: int) -> void:
	# Custom RPC to tell server our class
	pass

func _on_lobby_updated(players: Array) -> void:
	var t = "Players:\n"
	for p in players:
		var team_str = "Roofer" if p["team"] == 0 else "Landscaper"
		t += "- " + p["name"] + " (" + team_str + ")\n"
	player_list_label.text = t

func _on_start_game() -> void:
	if NetworkManager.is_host:
		# For now, just load training arena for everyone
		_load_level.rpc("res://scenes/main/suburban_arena.tscn")

@rpc("call_local", "reliable")
func _load_level(path: String) -> void:
	get_tree().change_scene_to_file(path)

func _on_test_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/suburban_arena.tscn")
