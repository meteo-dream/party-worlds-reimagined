extends BulletBase
class_name AcceleratingRedBullet

@export var target_velocity: Vector2
const move_after_sec: float = 1.75
const move_acceleration_time: float = 1.25
var new_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	veloc = Vector2.ZERO
	actual_vel = Vector2.ZERO
	super()

func enable_movement() -> void:
	await get_tree().create_timer(move_after_sec, false).timeout
	if move_after_sec <= 0.0:
		actual_vel = target_velocity
	else:
		var tw = get_tree().create_tween()
		tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tw.tween_property(self, "new_velocity", target_velocity, move_acceleration_time)
	allow_movement = true

func _movement_process(delta: float) -> void:
	actual_vel = new_velocity
	super(delta)
