extends Sprite2D

func _ready() -> void:
	var tw = get_tree().create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: queue_free())
