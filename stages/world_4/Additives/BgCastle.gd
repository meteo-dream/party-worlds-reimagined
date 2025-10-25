extends ParallaxLayer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if modulate.a <= 1:
		modulate.a += 10 * delta
