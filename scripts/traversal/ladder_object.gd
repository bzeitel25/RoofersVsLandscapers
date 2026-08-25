class_name LadderObject
extends Node3D

@export var climb_speed: float = 4.0
@export var ladder_height: float = 5.0
@export var is_ghost: bool = false # Ghost ladders don't have collision

var climb_area: Area3D
var collision_shape: CollisionShape3D
var visual_root: Node3D

func _ready() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	
	if not is_ghost:
		climb_area = Area3D.new()
		add_child(climb_area)
		
		# Layer 4 is Traversal (1 << 3)
		climb_area.collision_layer = 8
		climb_area.collision_mask = 3 # Detect Players (Layer 1 or 2)
		
		collision_shape = CollisionShape3D.new()
		climb_area.add_child(collision_shape)
		
		var box = BoxShape3D.new()
		box.size = Vector3(1.0, ladder_height, 0.5)
		collision_shape.shape = box
		collision_shape.position = Vector3(0, ladder_height / 2.0, 0)
		
		climb_area.body_entered.connect(_on_body_entered)
		climb_area.body_exited.connect(_on_body_exited)
	
	_create_debug_mesh()
	
	if not is_ghost:
		# Animate extending upward
		var final_scale = visual_root.scale
		visual_root.scale = Vector3(1, 0, 1)
		var tween = create_tween()
		tween.tween_property(visual_root, "scale", final_scale, 0.5).set_trans(Tween.TRANS_SPRING)

func set_ghost_valid(is_valid: bool) -> void:
	for child in visual_root.get_children():
		if child is MeshInstance3D and child.material_override:
			if is_valid:
				child.material_override.albedo_color = Color(0.2, 1.0, 0.2, 0.5)
			else:
				child.material_override.albedo_color = Color(1.0, 0.2, 0.2, 0.5)

func _create_debug_mesh() -> void:
	var mat = StandardMaterial3D.new()
	if is_ghost:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.2, 1.0, 0.2, 0.5) # Ghostly green
		mat.emission_enabled = true
		mat.emission = Color(0.2, 1.0, 0.2)
		mat.emission_energy_multiplier = 0.5
	else:
		mat.albedo_color = Color(0.7, 0.4, 0.1) # Wood color
	
	# Two side rails
	var rail_mesh = BoxMesh.new()
	rail_mesh.size = Vector3(0.05, ladder_height, 0.05)
	
	var left_rail = MeshInstance3D.new()
	left_rail.mesh = rail_mesh
	left_rail.material_override = mat
	left_rail.position = Vector3(-0.4, ladder_height / 2.0, 0)
	visual_root.add_child(left_rail)
	
	var right_rail = MeshInstance3D.new()
	right_rail.mesh = rail_mesh
	right_rail.material_override = mat
	right_rail.position = Vector3(0.4, ladder_height / 2.0, 0)
	visual_root.add_child(right_rail)
	
	# Rungs every 0.5 meters
	var num_rungs = int(ladder_height / 0.5)
	for i in range(num_rungs):
		var rung_mesh = BoxMesh.new()
		rung_mesh.size = Vector3(0.8, 0.04, 0.04)
		var rung = MeshInstance3D.new()
		rung.mesh = rung_mesh
		rung.material_override = mat
		# Offset by 0.25 so the first rung isn't exactly at the floor
		rung.position = Vector3(0, 0.25 + (i * 0.5), 0)
		visual_root.add_child(rung)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("enter_ladder"):
		body.enter_ladder(self)

func _on_body_exited(body: Node3D) -> void:
	if body.has_method("exit_ladder"):
		body.exit_ladder()
