extends Control

var tab_container: TabContainer

# --- Host Tab ---
var host_name_input: LineEdit
var host_private_check: CheckBox
var host_password_input: LineEdit
var host_btn: Button

# --- Join Tab ---
var join_list_vbox: VBoxContainer
var refresh_btn: Button

# --- Direct Tab ---
var ip_input: LineEdit
var name_input: LineEdit

var lobby_panel: PanelContainer
var player_list_label: Label
var class_dropdown: OptionButton
var team_dropdown: OptionButton
var start_button: Button

var password_dialog: ConfirmationDialog
var password_input: LineEdit
var current_joining_server: Dictionary

func _ready() -> void:
	if has_node("VBoxContainer"):
		$VBoxContainer.queue_free()
		
	_build_ui()
	NetworkManager.lobby_updated.connect(_on_lobby_updated)
	NetworkManager.connected_to_server.connect(_show_lobby)
	
	# Master Server Client logic (if autoloaded)
	if has_node("/root/MasterServerClient"):
		var msc = get_node("/root/MasterServerClient")
		msc.server_list_received.connect(_on_server_list_received)
		msc.join_info_received.connect(_on_join_info_received)
		msc.error_occurred.connect(func(msg): print("Master Server Error: ", msg))

func _build_ui() -> void:
	var main_panel = PanelContainer.new()
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(main_panel)
	
	var main_vbox = VBoxContainer.new()
	main_panel.add_child(main_vbox)
	
	var title = Label.new()
	title.text = "ROOFERS VS LANDSCAPERS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	name_input = LineEdit.new()
	name_input.placeholder_text = "Enter Player Name"
	name_input.text = "Player" + str(randi() % 1000)
	main_vbox.add_child(name_input)
	
	tab_container = TabContainer.new()
	main_vbox.add_child(tab_container)
	
	# --- BROWSER TAB ---
	var browser_tab = VBoxContainer.new()
	browser_tab.name = "Public Servers"
	tab_container.add_child(browser_tab)
	
	refresh_btn = Button.new()
	refresh_btn.text = "Refresh List"
	refresh_btn.pressed.connect(_on_refresh_pressed)
	browser_tab.add_child(refresh_btn)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 200)
	browser_tab.add_child(scroll)
	
	join_list_vbox = VBoxContainer.new()
	scroll.add_child(join_list_vbox)
	
	# --- HOST TAB ---
	var host_tab = VBoxContainer.new()
	host_tab.name = "Host Game"
	tab_container.add_child(host_tab)
	
	host_name_input = LineEdit.new()
	host_name_input.placeholder_text = "Server Name"
	host_name_input.text = "My Epic Match"
	host_tab.add_child(host_name_input)
	
	host_private_check = CheckBox.new()
	host_private_check.text = "Private Server"
	host_private_check.toggled.connect(func(t): host_password_input.visible = t)
	host_tab.add_child(host_private_check)
	
	host_password_input = LineEdit.new()
	host_password_input.placeholder_text = "Password"
	host_password_input.secret = true
	host_password_input.hide()
	host_tab.add_child(host_password_input)
	
	host_btn = Button.new()
	host_btn.text = "Start Hosting"
	host_btn.pressed.connect(_on_host_pressed)
	host_tab.add_child(host_btn)
	
	# --- DIRECT TAB ---
	var direct_tab = VBoxContainer.new()
	direct_tab.name = "Direct IP"
	tab_container.add_child(direct_tab)
	
	ip_input = LineEdit.new()
	ip_input.placeholder_text = "Enter Host IP (e.g., 127.0.0.1)"
	ip_input.text = "127.0.0.1"
	direct_tab.add_child(ip_input)
	
	var join_btn = Button.new()
	join_btn.text = "Connect"
	join_btn.pressed.connect(_on_join_pressed)
	direct_tab.add_child(join_btn)
	
	var test_btn = Button.new()
	test_btn.text = "Offline Training"
	test_btn.pressed.connect(_on_test_pressed)
	main_vbox.add_child(test_btn)
	
	# --- LOBBY PANEL (Hidden initially) ---
	lobby_panel = PanelContainer.new()
	lobby_panel.set_anchors_preset(Control.PRESET_CENTER)
	lobby_panel.hide()
	add_child(lobby_panel)
	
	var lvbox = VBoxContainer.new()
	lobby_panel.add_child(lvbox)
	
	var ltitle = Label.new()
	ltitle.text = "MATCH LOBBY"
	ltitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvbox.add_child(ltitle)
	
	player_list_label = Label.new()
	player_list_label.text = "Players:\n- You"
	lvbox.add_child(player_list_label)
	
	var hbox = HBoxContainer.new()
	lvbox.add_child(hbox)
	
	team_dropdown = OptionButton.new()
	team_dropdown.add_item("Roofers (Defend)", 0)
	team_dropdown.add_item("Landscapers (Attack)", 1)
	hbox.add_child(team_dropdown)
	
	class_dropdown = OptionButton.new()
	class_dropdown.add_item("Nailer (Medium)", 0)
	class_dropdown.add_item("Foreman (Medium)", 1)
	class_dropdown.add_item("Tar King (Heavy)", 2)
	class_dropdown.add_item("Shingle Slinger (Light)", 3)
	class_dropdown.add_item("Apprentice (Light)", 4)
	hbox.add_child(class_dropdown)
	
	start_button = Button.new()
	start_button.text = "START MATCH"
	start_button.pressed.connect(_on_start_match_pressed)
	lvbox.add_child(start_button)
	
	# --- PASSWORD DIALOG ---
	password_dialog = ConfirmationDialog.new()
	password_dialog.title = "Enter Password"
	var d_vbox = VBoxContainer.new()
	password_input = LineEdit.new()
	password_input.secret = true
	password_input.placeholder_text = "Password"
	d_vbox.add_child(password_input)
	password_dialog.add_child(d_vbox)
	add_child(password_dialog)
	password_dialog.confirmed.connect(_on_password_confirmed)

func _on_host_pressed() -> void:
	NetworkManager.player_name = name_input.text
	var err = NetworkManager.host_game()
	if err == OK:
		_show_lobby()
		# Register with Master Server
		if has_node("/root/MasterServerClient"):
			get_node("/root/MasterServerClient").register_server(
				host_name_input.text, host_private_check.button_pressed, host_password_input.text, 7350
			)

func _on_join_pressed() -> void:
	NetworkManager.player_name = name_input.text
	NetworkManager.join_game(ip_input.text)

func _on_test_pressed() -> void:
	# Load suburban arena directly for offline
	NetworkManager.player_name = "OfflineTest"
	get_tree().change_scene_to_file("res://scenes/main/suburban_arena.tscn")

func _on_refresh_pressed() -> void:
	if has_node("/root/MasterServerClient"):
		get_node("/root/MasterServerClient").fetch_servers()

func _on_server_list_received(servers: Array) -> void:
	for child in join_list_vbox.get_children():
		child.queue_free()
		
	if servers.is_empty():
		var l = Label.new()
		l.text = "No public servers found."
		join_list_vbox.add_child(l)
		return
		
	for s in servers:
		var btn = Button.new()
		var txt = s.name
		if s.get("private", false):
			txt = "[LOCKED] " + txt
		btn.text = txt
		btn.pressed.connect(func(): _join_server_from_browser(s))
		join_list_vbox.add_child(btn)

func _join_server_from_browser(server_data: Dictionary) -> void:
	current_joining_server = server_data
	if server_data.get("private", false):
		password_input.text = ""
		password_dialog.popup_centered(Vector2(300, 150))
	else:
		NetworkManager.player_name = name_input.text
		if has_node("/root/MasterServerClient"):
			get_node("/root/MasterServerClient").get_join_info(server_data.id)

func _on_password_confirmed() -> void:
	NetworkManager.player_name = name_input.text
	if has_node("/root/MasterServerClient"):
		get_node("/root/MasterServerClient").get_join_info(current_joining_server.id, password_input.text)

func _on_join_info_received(ip: String, port: int) -> void:
	NetworkManager.join_game(ip, port)

func _show_lobby() -> void:
	# Hide main panel, show lobby
	get_child(0).hide()
	lobby_panel.show()
	_on_lobby_updated(NetworkManager.get_lobby_players())
	start_button.visible = NetworkManager.is_host

func _on_lobby_updated(players: Array) -> void:
	var txt = "Players:\n"
	for p in players:
		txt += "- " + str(p.name) + "\n"
	player_list_label.text = txt

func _on_start_match_pressed() -> void:
	# Host tells everyone to start
	if NetworkManager.is_host:
		NetworkManager.start_match.rpc(team_dropdown.selected, class_dropdown.selected)