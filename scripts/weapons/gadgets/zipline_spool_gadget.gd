class_name ZiplineSpool
extends BaseTool

const ZIPLINE_SCRIPT = preload("res://scripts/traversal/zipline_object.gd")

@export var max_deploy_distance: float = 20.0 # From camera

var _start_point: Vector3 = Vector3.ZERO
var _has_start_point: bool = false
var _ghost_start_peg: MeshInstance3D = null
var _ghost_line: MeshInstance3D = null

func _ready() -> void:
	tool_name = "Zipline Spool"
	cooldown = 20.0
	slot_type = 2 # Gadget
	supply_cost = 25 # Costs 25 supplies
	super._ready()
	
	# Create a visual for the handheld spool
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	
	var visual_root = Node3D.new()
	add_child(visual_root)
	
	var spool = MeshInstance3D.new()
	var r_mesh = CylinderMesh.new()
	r_mesh.height = 0.3
	r_mesh.top_radius = 0.15
	r_mesh.bottom_radius = 0.15
	r_mesh.material = mat
	spool.mesh = r_mesh
	spool.rotation_degrees.z = 90
	visual_root.add_child(spool)

func equip(new_wielder: Node3D) -> void:
	super.equip(new_wielder)
	
	if not _ghost_start_peg:
		_ghost_start_peg = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		s_mesh.radius = 0.2
		s_mesh.height = 0.4
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.5, 0.0, 0.5) # Orange transparent
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		s_mesh.material = mat
		_ghost_start_peg.mesh = s_mesh
		get_tree().current_scene.add_child(_ghost_start_peg)
		_ghost_start_peg.hide()
		
		_ghost_line = MeshInstance3D.new()
		var l_mesh = CylinderMesh.new()
		l_mesh.top_radius = 0.02
		l_mesh.bottom_radius = 0.02
		l_mesh.material = mat
		_ghost_line.mesh = l_mesh
		get_tree().current_scene.add_child(_ghost_line)
		_ghost_line.hide()

func unequip() -> void:
	super.unequip()
	if _ghost_start_peg: _ghost_start_peg.hide()
	if _ghost_line: _ghost_line.hide()
	_has_start_point = false

func drop() -> void:
	if _ghost_start_peg: _ghost_start_peg.queue_free()
	if _ghost_line: _ghost_line.queue_free()
	super.drop()

func _process(_delta: float) -> void:
	if not wielder or freeze == false or not can_use():
		if _ghost_start_peg: _ghost_start_peg.hide()
		if _ghost_line: _ghost_line.hide()
		return
	
	var target = wielder.get_aim_target() if wielder.has_method("get_aim_target") else Vector3.ZERO
	if target == Vector3.ZERO: return
	
	# Are we close enough to the target point to shoot our zipline there?
	var dist = wielder.global_position.distance_to(target)
	if dist > max_deploy_distance:
		if _ghost_start_peg: _ghost_start_peg.hide()
		if _ghost_line: _ghost_line.hide()
		return
		
	if _ghost_start_peg:
		_ghost_start_peg.show()
		
		if not _has_start_point:
			_ghost_start_peg.global_position = target
			if _ghost_line: _ghost_line.hide()
		else:
			_ghost_start_peg.global_position = _start_point
			if _ghost_line:
				_ghost_line.show()
				var mid = (_start_point + target) / 2.0
				var line_dist = _start_point.distance_to(target)
				_ghost_line.global_position = mid
				_ghost_line.look_at(target, Vector3.UP)
				_ghost_line.rotation_degrees.x = 90
				_ghost_line.mesh.height = line_dist

func primary_use_pressed(character: Node3D) -> void:
	if not can_use(): return
	if not _ghost_start_peg or not _ghost_start_peg.visible: return
	
	var target = wielder.get_aim_target()
	
	if not _has_start_point:
		_start_point = target
		_has_start_point = true
	else:
		# Deploy the final zipline!
		var z_obj = ZIPLINE_SCRIPT.new()
		get_tree().current_scene.add_child(z_obj)
		z_obj.initialize(_start_point, target)
		
		_has_start_point = false
		_start_cooldown()
		consume_supplies()

func primary_use_released(character: Node3D) -> void:
	pass
