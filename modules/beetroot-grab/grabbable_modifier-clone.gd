extends "res://engine/node_modifiers/grabbable_modifier/grabbable_modifier.gd"


func _physics_process(delta: float) -> void:
	if _grabbed && _following_start:
		var _target = get_target_hold_position()
		target_node.global_position = lerp(_from_follow_pos, _target, _follow_progress)
		_follow_progress = min(_follow_progress + 5 * delta, 1)
		if _follow_progress == 1:
			_follow_progress = 0
			_following_start = false
			_following = true

	if _grabbed && _following:
		target_node.global_position = get_target_hold_position()

	if !_grabbed && _wait_until_floor && target_node.is_on_floor():
		_wait_until_floor = false
