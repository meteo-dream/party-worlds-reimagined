extends W8Truck

var autoscroll = get_parent()
var is_moving: bool = true

func _physics_process(delta: float) -> void:
	super(delta)
	if is_moving and autoscroll:
		global_position.x = autoscroll.global_position.x

func _on_path_follow_2d_scroll_stopped() -> void:
	stop_truck()
	is_moving = false
