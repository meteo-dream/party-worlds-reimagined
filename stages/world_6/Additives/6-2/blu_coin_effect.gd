extends AnimatedSprite2D

func _physics_process(delta):
	if frame == 4:
		queue_free()
