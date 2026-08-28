extends Node3D

func interact(player: Node3D) -> void:
	if player.has_method("perch"):
		player.perch(global_position)
