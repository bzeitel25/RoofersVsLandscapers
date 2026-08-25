# ============================================================
# Main Menu UI Controller
# ============================================================
extends Control


func _on_host_pressed() -> void:
	var error := NetworkManager.host_game()
	if error == OK:
		print("[Menu] Hosting game...")
		# TODO: Switch to lobby scene
		get_tree().change_scene_to_file("res://scenes/main/test_level.tscn")


func _on_join_pressed() -> void:
	# TODO: Show IP input dialog
	var error := NetworkManager.join_game("127.0.0.1")
	if error == OK:
		print("[Menu] Joining game...")
		get_tree().change_scene_to_file("res://scenes/main/test_level.tscn")


func _on_test_pressed() -> void:
	print("[Menu] Loading test level (solo)...")
	get_tree().change_scene_to_file("res://scenes/main/test_level.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
