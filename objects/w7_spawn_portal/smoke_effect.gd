extends Sprite2D

func _ready() -> void:
	scale = Vector2(1.1, 1.1)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(0.0, 0.0), 0.7)

func _physics_process(delta: float) -> void:
	if scale <= Vector2(0.0, 0.0):
		queue_free()
