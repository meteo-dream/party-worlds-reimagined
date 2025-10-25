extends Node2D
class_name BossPlatformSupport

@export var activation_sound_effect: AudioStream
@export var platforms: Array[Node2D]
@export var platform_move_percent: Array[float] = [0.45, 0.45, 0.68, 0.68, 0.22, 0.22]
@export var field_height: float = 480.0
@export var move_duration: float = 0.2
var tween_array: Array[Tween]

func _ready() -> void:
	move_into_position()
	Audio.play_sound(activation_sound_effect, self)

func move_into_position() -> void:
	if platforms.size() <= 0: return
	#var anchor_y: float = global_position.y
	for i in platforms.size():
		if !is_instance_valid(platforms[i]): return
		var destination_pos_clamp: int = clamp(i, 0, platform_move_percent.size() - 1)
		var platform_tween = get_tree().create_tween()
		platform_tween.tween_callback(func() -> void:
			tween_array.append(platform_tween))
		platform_tween.set_trans(Tween.TRANS_CIRC)
		platform_tween.set_ease(Tween.EASE_OUT)
		platform_tween.tween_property(platforms[i], "position:y", field_height * platform_move_percent[destination_pos_clamp], move_duration)

func move_out() -> void:
	if platforms.size() <= 0: return
	for i in tween_array.size():
		if is_instance_valid(tween_array[i]):
			tween_array[i].kill()
	var anchor_x: float = global_position.x + 320.0
	for k in platforms.size():
		if !is_instance_valid(platforms[k]): return
		var end_x: float = -400.0
		if platforms[k].global_position.x > anchor_x:
			end_x = absf(end_x)
		var return_tween = get_tree().create_tween()
		return_tween.tween_property(platforms[k], "global_position:x", anchor_x + end_x, move_duration)
		return_tween.tween_callback(func() -> void:
			queue_free())
