extends GPUParticles2D

func _physics_process(delta):
	global_position.y = Thunder.view.border.position.y
