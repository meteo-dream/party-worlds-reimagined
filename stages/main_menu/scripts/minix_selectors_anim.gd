extends Label

@export var left_side: bool = true

func _ready() -> void:
	var init_pos := position
	var tw = create_tween().set_loops()
	tw.tween_property(self, "position:x", init_pos.x - (3.0 if left_side else -3.0), 0.2)
	tw.tween_callback(set_position.bind(init_pos))
