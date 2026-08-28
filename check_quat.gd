extends SceneTree
func _init():
	var m = Node3D.new()
	m.scale = Vector3(1, 0.5, 1)
	m.quaternion = Quaternion(Vector3.UP, 0.5)
	print(m.scale)
	quit()

