extends ParallaxLayer
@export var speed = 5

func _physics_process(_delta):
	motion_offset.x -= speed * _delta
