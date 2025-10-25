extends PathFollow2D

@export var speed = 50

func _physics_process(delta):
	progress += speed * delta
