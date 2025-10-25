extends BulletBase

@export var do_accelerate: bool = false
@export var final_accelerate_speed: float = 300.0
@export var decelerate_delay_sec: float = 0.3
@export var decelerate_time_sec: float = 0.7
var entered_from_offscreen: bool = false
var allow_disappear_offscreen: bool = false

func _ready() -> void:
	bullet_sprite = $AnimatedSprite2D
	super()

func enable_movement() -> void:
	if !do_accelerate:
		super()
		return
	#used_angle = veloc.angle()
	#veloc = Vector2(50.0 * cos(used_angle), 50.0 * sin(used_angle))
	var new_angle: float = veloc.angle()
	super()
	var tw = get_tree().create_tween()
	tw.tween_property(self, "veloc", Vector2.ZERO, decelerate_time_sec)
	await get_tree().create_timer(decelerate_time_sec + decelerate_delay_sec, false).timeout
	var the_player = Thunder._current_player
	if is_instance_valid(the_player):
		new_angle = global_position.angle_to_point(the_player.global_position)
	veloc = Vector2(final_accelerate_speed * cos(new_angle), final_accelerate_speed * sin(new_angle))
	global_rotation = new_angle
	entered_from_offscreen = true

func _movement_process(delta: float) -> void:
	actual_vel = veloc
	super(delta)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if allow_disappear_offscreen: super()

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if entered_from_offscreen:
		allow_disappear_offscreen = true
	super()
