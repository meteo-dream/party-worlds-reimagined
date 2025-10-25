extends Label

var start_position: Vector2

func _ready() -> void:
	modulate.a = 0.0
	
	start_position -= Vector2(16.0, 0.0)
	global_position = start_position
	reset_physics_interpolation()
	
	var move_time: float = 0.5
	if text != "?": move_time = 0.1
	
	var tw2 = get_tree().create_tween()
	tw2.tween_property(self, "modulate:a", 1.0, move_time)
	var tw = get_tree().create_tween()
	tw.set_trans(Tween.TRANS_CIRC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:y", start_position.y - 110.0, move_time)
	tw.tween_interval(0.8)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: queue_free())
