extends Sprite2D

func _ready():
	modulate.a = 0
func _physics_process(delta):
	if modulate.a >= 0:
		modulate.a -= 10 * delta
