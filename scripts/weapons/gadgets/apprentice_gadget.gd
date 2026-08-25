extends "res://scripts/weapons/base_tool.gd"

var visual_root: Node3D

func _init() -> void:
	tool_name = "First Aid Kit"
	slot_type = 2
	cooldown = 12.0

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var box = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.2, 0.15, 0.1)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mesh.material = mat
	box.mesh = mesh
	box.position = Vector3(0, 0, -0.2)
	visual_root.add_child(box)
	
	var cross = MeshInstance3D.new()
	var cross_mesh = BoxMesh.new()
	cross_mesh.size = Vector3(0.05, 0.05, 0.11)
	var cross_mat = StandardMaterial3D.new()
	cross_mat.albedo_color = Color(1.0, 0.0, 0.0)
	cross_mesh.material = cross_mat
	cross.mesh = cross_mesh
	box.add_child(cross)

func primary_action() -> void:
	if not can_use(): return
	_start_cooldown()
	if not wielder:
		return
	
	if wielder.get("health") != null and wielder.get("max_health") != null:
		wielder.health = min(wielder.health + 30, wielder.max_health)
		if wielder.has_method("update_health_bar"):
			wielder.update_health_bar()
