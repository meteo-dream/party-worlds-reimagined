extends PointLight2D
@export var target: Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	rotation = target.rotation
	energy = target.energy 
