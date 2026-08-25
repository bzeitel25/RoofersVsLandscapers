extends StaticBody3D

var health: float = 150.0

func take_damage(amount: float, from_peer: int) -> void:
	health -= amount
	print("Foreman Shield took ", amount, " damage! Health remaining: ", health)
	
	if health <= 0:
		queue_free()
