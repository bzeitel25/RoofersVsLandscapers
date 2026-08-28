extends SceneTree
func _init():
	var m = StandardMaterial3D.new()
	for p in m.get_property_list():
		if 'repeat' in p.name:
			print(p.name)
	quit()

