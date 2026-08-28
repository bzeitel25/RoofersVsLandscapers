extends SceneTree
func _init():
	var m = StandardMaterial3D.new()
	var keys = m.get_property_list().map(func(p): return p.name)
	var file = FileAccess.open("res://props.txt", FileAccess.WRITE)
	file.store_string(",".join(keys))
	file.close()
	quit()

