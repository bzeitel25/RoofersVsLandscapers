import os

ladder_object_code = """class_name LadderObject
extends Node3D

@export var climb_speed: float = 4.0
@export var ladder_height: float = 5.0
@export var is_ghost: bool = false # Ghost ladders don't have collision

var climb_area: Area3D
var collision_shape: CollisionShape3D
var visual_root: Node3D

func _ready() -> void:
\tvisual_root = Node3D.new()
\tadd_child(visual_root)
\t
\tif not is_ghost:
\t\tclimb_area = Area3D.new()
\t\tadd_child(climb_area)
\t\t
\t\t# Layer 4 is Traversal (1 << 3)
\t\tclimb_area.collision_layer = 8
\t\tclimb_area.collision_mask = 2 # Detect Players
\t\t
\t\tcollision_shape = CollisionShape3D.new()
\t\tclimb_area.add_child(collision_shape)
\t\t
\t\tvar box = BoxShape3D.new()
\t\tbox.size = Vector3(1.0, ladder_height, 0.5)
\t\tcollision_shape.shape = box
\t\tcollision_shape.position = Vector3(0, ladder_height / 2.0, 0)
\t\t
\t\tclimb_area.body_entered.connect(_on_body_entered)
\t\tclimb_area.body_exited.connect(_on_body_exited)
\t
\t_create_debug_mesh()
\t
\tif not is_ghost:
\t\t# Animate extending upward
\t\tvar final_scale = visual_root.scale
\t\tvisual_root.scale = Vector3(1, 0, 1)
\t\tvar tween = create_tween()
\t\ttween.tween_property(visual_root, "scale", final_scale, 0.5).set_trans(Tween.TRANS_SPRING)

func set_ghost_valid(is_valid: bool) -> void:
\tfor child in visual_root.get_children():
\t\tif child is MeshInstance3D and child.material_override:
\t\t\tif is_valid:
\t\t\t\tchild.material_override.albedo_color = Color(0.2, 1.0, 0.2, 0.5)
\t\t\telse:
\t\t\t\tchild.material_override.albedo_color = Color(1.0, 0.2, 0.2, 0.5)

func _create_debug_mesh() -> void:
\tvar mat = StandardMaterial3D.new()
\tif is_ghost:
\t\tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
\t\tmat.albedo_color = Color(0.2, 1.0, 0.2, 0.5) # Ghostly green
\t\tmat.emission_enabled = true
\t\tmat.emission = Color(0.2, 1.0, 0.2)
\t\tmat.emission_energy_multiplier = 0.5
\telse:
\t\tmat.albedo_color = Color(0.7, 0.4, 0.1) # Wood color
\t
\t# Two side rails
\tvar rail_mesh = BoxMesh.new()
\trail_mesh.size = Vector3(0.05, ladder_height, 0.05)
\t
\tvar left_rail = MeshInstance3D.new()
\tleft_rail.mesh = rail_mesh
\tleft_rail.material_override = mat
\tleft_rail.position = Vector3(-0.4, ladder_height / 2.0, 0)
\tvisual_root.add_child(left_rail)
\t
\tvar right_rail = MeshInstance3D.new()
\tright_rail.mesh = rail_mesh
\tright_rail.material_override = mat
\tright_rail.position = Vector3(0.4, ladder_height / 2.0, 0)
\tvisual_root.add_child(right_rail)
\t
\t# Rungs every 0.5 meters
\tvar num_rungs = int(ladder_height / 0.5)
\tfor i in range(num_rungs):
\t\tvar rung_mesh = BoxMesh.new()
\t\trung_mesh.size = Vector3(0.8, 0.04, 0.04)
\t\tvar rung = MeshInstance3D.new()
\t\trung.mesh = rung_mesh
\t\trung.material_override = mat
\t\t# Offset by 0.25 so the first rung isn't exactly at the floor
\t\trung.position = Vector3(0, 0.25 + (i * 0.5), 0)
\t\tvisual_root.add_child(rung)

func _on_body_entered(body: Node3D) -> void:
\tif body.has_method("enter_ladder"):
\t\tbody.enter_ladder(self)

func _on_body_exited(body: Node3D) -> void:
\tif body.has_method("exit_ladder"):
\t\tbody.exit_ladder()
"""

extension_ladder_tool_code = """class_name ExtensionLadderTool
extends BaseTool

const LADDER_SCRIPT = preload("res://scripts/traversal/ladder_object.gd")

@export var max_deploy_distance: float = 8.0 # From camera
@export var min_deploy_distance: float = 1.0 # From player

var _ghost_ladder: Node3D = null
var _last_valid_pos: Vector3 = Vector3.ZERO
var _last_valid_normal: Vector3 = Vector3.ZERO
var _last_valid_height: float = 5.0
var _can_deploy: bool = false

func _ready() -> void:
\ttool_name = "Extension Ladder"
\tcooldown = 1.0
\tslot_type = 2 # Gadget
\tsuper._ready()
\t
\t# Create a visual for the handheld ladder gadget
\tvar mat = StandardMaterial3D.new()
\tmat.albedo_color = Color(0.7, 0.4, 0.1) # Wood
\t
\tvar visual_root = Node3D.new()
\tvisual_root.rotation_degrees.x = -60 # Point forward
\tadd_child(visual_root)
\t
\tvar left_rail = MeshInstance3D.new()
\tvar r_mesh = BoxMesh.new()
\tr_mesh.size = Vector3(0.04, 0.6, 0.04)
\tr_mesh.material = mat
\tleft_rail.mesh = r_mesh
\tleft_rail.position = Vector3(-0.15, 0, 0)
\tvisual_root.add_child(left_rail)
\t
\tvar right_rail = MeshInstance3D.new()
\tright_rail.mesh = r_mesh
\tright_rail.position = Vector3(0.15, 0, 0)
\tvisual_root.add_child(right_rail)
\t
\tfor i in range(3):
\t\tvar rung = MeshInstance3D.new()
\t\tvar rung_mesh = BoxMesh.new()
\t\trung_mesh.size = Vector3(0.3, 0.03, 0.03)
\t\trung_mesh.material = mat
\t\trung.mesh = rung_mesh
\t\trung.position = Vector3(0, -0.2 + (i * 0.2), 0)
\t\tvisual_root.add_child(rung)

func equip(new_wielder: Node3D) -> void:
\tsuper.equip(new_wielder)
\t
\t# Create ghost ladder
\tif not _ghost_ladder:
\t\t_ghost_ladder = Node3D.new()
\t\t_ghost_ladder.set_script(LADDER_SCRIPT)
\t\t_ghost_ladder.is_ghost = true
\t\t_ghost_ladder.ladder_height = 5.0
\t\tget_tree().current_scene.add_child(_ghost_ladder)
\t\t_ghost_ladder.hide()

func unequip() -> void:
\tsuper.unequip()
\tif _ghost_ladder:
\t\t_ghost_ladder.hide()

func drop() -> void:
\tif _ghost_ladder:
\t\t_ghost_ladder.queue_free()
\t\t_ghost_ladder = null
\tsuper.drop()

func _process(delta: float) -> void:
\tsuper._process(delta)
\t
\tif not wielder or freeze == false:
\t\tif _ghost_ladder:
\t\t\t_ghost_ladder.hide()
\t\treturn
\t
\t_update_ghost_ladder()

func _update_ghost_ladder() -> void:
\t_can_deploy = false
\t
\tvar camera = wielder.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
\tif not camera:
\t\tif _ghost_ladder: _ghost_ladder.hide()
\t\treturn
\t\t
\tvar space_state = wielder.get_world_3d().direct_space_state
\t
\t# Raycast from camera forward
\tvar query = PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_transform.basis.z * max_deploy_distance)
\tquery.exclude = [wielder.get_rid()]
\t
\tvar result = space_state.intersect_ray(query)
\tif result and result.normal.y < 0.5: # Hit a wall
\t\t# Ensure it's not too far from the actual player
\t\tvar dist_to_player = wielder.global_position.distance_to(result.position)
\t\tif dist_to_player < max_deploy_distance:
\t\t\t_can_deploy = true
\t\t\t_last_valid_pos = result.position
\t\t\t_last_valid_normal = result.normal
\t\t\t
\t\t\t# Calculate height dynamically
\t\t\t_last_valid_height = _calculate_wall_height(result.position, result.normal, space_state)
\t\t\t
\t\t\tif _ghost_ladder:
\t\t\t\t# Update ghost ladder dynamically without recreating it (just scale visually)
\t\t\t\t_ghost_ladder.global_position = _last_valid_pos
\t\t\t\t
\t\t\t\tvar look_target = _last_valid_pos + _last_valid_normal
\t\t\t\tlook_target.y = _last_valid_pos.y
\t\t\t\t_ghost_ladder.look_at(look_target, Vector3.UP)
\t\t\t\t
\t\t\t\t_ghost_ladder.show()
\t\t\t\t
\t\t\t\tif _ghost_ladder.has_node("visual_root"):
\t\t\t\t\t# Dynamically scale Y to represent height
\t\t\t\t\t_ghost_ladder.get_node("visual_root").scale.y = _last_valid_height / 5.0
\t\t\t\t_ghost_ladder.set_ghost_valid(true)
\t\t\t\treturn
\t
\t# Hide if not valid
\tif _ghost_ladder:
\t\t_ghost_ladder.hide()

func _calculate_wall_height(hit_pos: Vector3, normal: Vector3, space_state: PhysicsDirectSpaceState3D) -> float:
\t# Raycast straight down from high up, slightly slightly inside the wall
\tvar top_pos = hit_pos - (normal * 0.5) + Vector3(0, 15.0, 0)
\tvar query = PhysicsRayQueryParameters3D.create(top_pos, top_pos - Vector3(0, 20.0, 0))
\tvar result = space_state.intersect_ray(query)
\t
\tif result:
\t\tvar height = result.position.y - hit_pos.y
\t\t# Clamp height between 2 and 12 meters
\t\treturn clampf(height + 1.0, 2.0, 12.0)
\treturn 5.0 # Default height

func primary_action() -> void:
\tif not can_use() or not wielder or not _can_deploy:
\t\treturn
\t\t
\t_deploy_ladder(_last_valid_pos, _last_valid_normal, _last_valid_height)
\t_start_cooldown()
\t
\t# Single use - clear ghost and delete self
\tif _ghost_ladder:
\t\t_ghost_ladder.queue_free()
\t\t_ghost_ladder = null
\t
\tqueue_free()

func _deploy_ladder(deploy_pos: Vector3, wall_normal: Vector3, height: float) -> void:
\tvar ladder = Node3D.new()
\tladder.set_script(LADDER_SCRIPT)
\tladder.ladder_height = height
\t
\tvar world = wielder.get_tree().current_scene
\tworld.add_child(ladder)
\t
\tladder.global_position = deploy_pos
\t
\tvar look_target = deploy_pos + wall_normal
\tlook_target.y = deploy_pos.y
\tladder.look_at(look_target, Vector3.UP)
"""

# Write files
with open("c:/Users/bzeit/OneDrive/Documents/Books/Universe/Roofers vs Landscapers/scripts/traversal/ladder_object.gd", "w") as f:
    f.write(ladder_object_code)

with open("c:/Users/bzeit/OneDrive/Documents/Books/Universe/Roofers vs Landscapers/scripts/weapons/gadgets/extension_ladder_tool.gd", "w") as f:
    f.write(extension_ladder_tool_code)

print("Updated ladder scripts successfully!")
