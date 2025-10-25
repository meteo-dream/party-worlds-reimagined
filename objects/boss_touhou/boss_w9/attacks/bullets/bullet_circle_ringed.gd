extends BulletBase

@export var sfx_twinkle: AudioStream
var slow_then_speed: bool = false
var slow_then_speed_time: float = 1.0
var slow_then_speed_veloc: float = 50.0
var slow_then_speed_angle: float = 0.0

func _ready() -> void:
	if slow_then_speed:
		actual_vel = veloc
	appear_animation()
	super()

func enable_movement() -> void:
	if slow_then_speed:
		var tw = get_tree().create_tween()
		tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tw.tween_property(self, "actual_vel", Vector2(0.0, 0.0), slow_then_speed_time / 2.0)
		await get_tree().create_timer(slow_then_speed_time, false).timeout
		var new_velocity: Vector2 = Vector2(slow_then_speed_veloc * cos(slow_then_speed_angle), slow_then_speed_veloc * sin(slow_then_speed_angle))
		var tw2 = get_tree().create_tween()
		tw2.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tw2.tween_property(self, "actual_vel", new_velocity, slow_then_speed_time / 2.0)
		if sfx_twinkle: Audio.play_sound(sfx_twinkle, self)
	else:
		actual_vel = veloc
	allow_movement = true
	global_rotation = 0.0
