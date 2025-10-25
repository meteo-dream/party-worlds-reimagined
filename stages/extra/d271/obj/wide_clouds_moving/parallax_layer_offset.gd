extends ParallaxLayer

@export var speed: Vector2

func _physics_process(delta):
	motion_offset += speed * delta
