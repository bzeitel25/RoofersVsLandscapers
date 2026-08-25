extends StaticBody3D
class_name ZiplineObject

var start_pos: Vector3
var end_pos: Vector3

func initialize(p_start: Vector3, p_end: Vector3) -> void:
	start_pos = p_start
	end_pos = p_end
	
	global_position = (start_pos + end_pos) / 2.0
	var dist = start_pos.distance_to(end_pos)
	look_at(end_pos, Vector3.UP)
	
	# Create physical cable mesh
	var mesh_inst = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.05
	cyl.height = dist
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.1) # Black cable
	cyl.material = mat
	mesh_inst.mesh = cyl
	mesh_inst.rotation_degrees.x = 90
	add_child(mesh_inst)
	
	# Create large interaction hitbox
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.5, 1.5, dist)
	col.shape = shape
	add_child(col)
	
	# Important: Make sure it's on a collision layer the player's interact raycast can hit!
	# The player interact raycast usually checks layer 1 (world) or something. We'll set this to 1 and 8.
	collision_layer = 1 | 8

func interact(player: Node3D) -> void:
	if player.has_method("mount_zipline"):
		player.mount_zipline(self)
