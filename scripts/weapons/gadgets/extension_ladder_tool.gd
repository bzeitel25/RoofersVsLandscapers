class_name ExtensionLadderTool
extends "res://scripts/weapons/base_tool.gd"

const LADDER_SCRIPT = preload("res://scripts/traversal/ladder_object.gd")

@export var max_deploy_distance: float = 8.0 # From camera
@export var min_deploy_distance: float = 1.0 # From player

var _ghost_ladder: Node3D = null
var _last_valid_pos: Vector3 = Vector3.ZERO
var _last_valid_normal: Vector3 = Vector3.ZERO
var _last_valid_height: float = 5.0
var _can_deploy: bool = false

func _ready() -> void:
	tool_name = "Extension Ladder"
	cooldown = 8.0
	slot_type = 2 # Gadget
	super._ready()
	
	# Create a visual for the handheld ladder gadget
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.4, 0.1) # Wood
	
	var visual_root = Node3D.new()
	visual_root.rotation_degrees.x = -60 # Point forward
	add_child(visual_root)
	
	var left_rail = MeshInstance3D.new()
	var r_mesh = BoxMesh.new()
	r_mesh.size = Vector3(0.04, 0.6, 0.04)
	r_mesh.material = mat
	left_rail.mesh = r_mesh
	left_rail.position = Vector3(-0.15, 0, 0)
	visual_root.add_child(left_rail)
	
	var right_rail = MeshInstance3D.new()
	right_rail.mesh = r_mesh
	right_rail.position = Vector3(0.15, 0, 0)
	visual_root.add_child(right_rail)
	
	for i in range(3):
		var rung = MeshInstance3D.new()
		var rung_mesh = BoxMesh.new()
		rung_mesh.size = Vector3(0.3, 0.03, 0.03)
		rung_mesh.material = mat
		rung.mesh = rung_mesh
		rung.position = Vector3(0, -0.2 + (i * 0.2), 0)
		visual_root.add_child(rung)

func equip(new_wielder: Node3D) -> void:
	super.equip(new_wielder)
	
	# Create ghost ladder
	if not _ghost_ladder:
		_ghost_ladder = Node3D.new()
		_ghost_ladder.set_script(LADDER_SCRIPT)
		_ghost_ladder.is_ghost = true
		_ghost_ladder.ladder_height = 5.0
		get_tree().current_scene.add_child(_ghost_ladder)
		_ghost_ladder.hide()

func unequip() -> void:
	super.unequip()
	if _ghost_ladder:
		_ghost_ladder.hide()

func drop() -> void:
	if _ghost_ladder:
		_ghost_ladder.queue_free()
		_ghost_ladder = null
	super.drop()

func _process(delta: float) -> void:
	super._process(delta)
	
	if not wielder or freeze == false or not can_use():
		if _ghost_ladder:
			_ghost_ladder.hide()
		return
	
	_update_ghost_ladder()

func _update_ghost_ladder() -> void:
	_can_deploy = false
	
	var camera = wielder.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if not camera:
		if _ghost_ladder: _ghost_ladder.hide()
		return
		
	var space_state = wielder.get_world_3d().direct_space_state
	
	# Raycast from camera forward
	var query = PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_transform.basis.z * max_deploy_distance)
	query.exclude = [wielder.get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result and result.normal.y < 0.5: # Hit a wall
		var dist_to_player = wielder.global_position.distance_to(result.position)
		if dist_to_player < max_deploy_distance:
			
			# Find ground position
			var ground_pos = result.position
			var ground_query = PhysicsRayQueryParameters3D.create(result.position + (result.normal * 0.1), result.position + (result.normal * 0.1) - Vector3(0, 15.0, 0))
			var ground_result = space_state.intersect_ray(ground_query)
			if ground_result:
				ground_pos.y = ground_result.position.y
				
			# Find roof height
			var top_ray_start = result.position - (result.normal * 0.5) + Vector3(0, 15.0, 0)
			var roof_query = PhysicsRayQueryParameters3D.create(top_ray_start, top_ray_start - Vector3(0, 20.0, 0))
			var roof_result = space_state.intersect_ray(roof_query)
			
			var target_height = 5.0
			if roof_result:
				target_height = (roof_result.position.y - ground_pos.y) + 1.2
			else:
				target_height = (result.position.y - ground_pos.y) + 2.0
				
			target_height = clampf(target_height, 2.0, 20.0)
			
			# Lean the ladder 12 degrees
			var lean_angle = 12.0
			var lean_dist = (target_height * tan(deg_to_rad(lean_angle))) + 0.4
			var leaned_ground_pos = ground_pos + (result.normal * lean_dist)
			
			_can_deploy = true
			_last_valid_pos = leaned_ground_pos
			_last_valid_normal = result.normal
			_last_valid_height = target_height / cos(deg_to_rad(lean_angle))
			
			if _ghost_ladder:
				_ghost_ladder.global_position = _last_valid_pos
				var look_target = _last_valid_pos + _last_valid_normal
				look_target.y = _last_valid_pos.y
				_ghost_ladder.look_at(look_target, Vector3.UP)
				_ghost_ladder.rotation_degrees.x = lean_angle
				
				_ghost_ladder.show()
				if _ghost_ladder.has_node("visual_root"):
					_ghost_ladder.get_node("visual_root").scale.y = _last_valid_height / 5.0
				_ghost_ladder.set_ghost_valid(true)
				return
	
	if _ghost_ladder:
		_ghost_ladder.hide()

func primary_action() -> void:
	if not can_use() or not wielder or not _can_deploy:
		return
		
	_deploy_ladder(_last_valid_pos, _last_valid_normal, _last_valid_height)
	_start_cooldown()
	
	if _ghost_ladder:
		_ghost_ladder.hide()

func _deploy_ladder(deploy_pos: Vector3, wall_normal: Vector3, height: float) -> void:
	var ladder = Node3D.new()
	ladder.set_script(LADDER_SCRIPT)
	ladder.ladder_height = height
	
	var world = wielder.get_tree().current_scene
	world.add_child(ladder)
	
	ladder.global_position = deploy_pos
	
	var look_target = deploy_pos + wall_normal
	look_target.y = deploy_pos.y
	ladder.look_at(look_target, Vector3.UP)
	ladder.rotation_degrees.x = 12.0
