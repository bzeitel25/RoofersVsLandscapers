extends SceneTree

func _init():
	print("Checking test_level...")
	var test_level = load("res://scenes/main/test_level.tscn")
	if test_level:
		print("test_level loaded OK!")
	else:
		print("test_level FAILED!")
		
	print("Checking suburban_arena...")
	var arena = load("res://scenes/main/suburban_arena.tscn")
	if arena:
		print("suburban_arena loaded OK!")
	else:
		print("suburban_arena FAILED!")
		
	quit()