extends Sprite2D

# Handle movement and more advanced shooting stuff later
@export var movement_vector: Vector2 = Vector2(50.0, 50.0)
@export var final_rotation_speed: float = 5.0
@export var do_appear_animation: bool = true
@export var node_for_playing_shoot_sound: Node2D
@export var shoot_sound_effect: AudioStream
@export_group("Rotation Acceleration Properties", "rotation_accel_")
@export var rotation_accel_enabled: bool = true
@export var rotation_accel_time: float = 1.0
@export_group("Shooting Properties", "shoot_")
@export var shoot_bullet_type: PackedScene
@export_enum("Violet: 0", "Red: 1", "Gold: 2", "Lime Yellow: 3", "Green: 4", "Blue: 5", "Cyan: 6") var shoot_bullet_color: int = 2
@export var shoot_bullet_speed: float = 200.0
@export var shoot_interval_sec: float = 0.5
@export var shoot_delay_time_sec: float = 3.0
@export_range(0.0, 360.0) var shoot_angle: float
@export var shoot_anchor_position: Vector2
var actual_movement_velocity: Vector2
var actual_rotation_speed: float
var desired_final_scale: Vector2
var desired_final_alpha: float
var bullet_delete_pool: Node2D
@onready var bullet_interval_timer: Timer = $Timer
var begin_shooting: bool = false
var begin_moving: bool = false
var has_left_the_screen: bool = false
var FORCED_stop_shooting: bool = false

func _ready() -> void:
	if do_appear_animation:
		desired_final_scale = scale
		desired_final_alpha = self_modulate.a
		scale = Vector2.ZERO
		self_modulate.a = 0.0
	if rotation_accel_enabled: actual_rotation_speed = 0.0
	else: actual_rotation_speed = final_rotation_speed
	_appear_anim()
	enable_movement()
	_shoot_wait(shoot_delay_time_sec)

func _shoot_wait(time: float) -> void:
	await get_tree().create_timer(time, false).timeout
	if FORCED_stop_shooting: return
	begin_shooting = true

func _appear_anim() -> void:
	var tw = get_tree().create_tween()
	tw.set_parallel(true)
	if do_appear_animation:
		tw.tween_property(self, "self_modulate:a", desired_final_alpha, 0.4)
		tw.tween_property(self, "scale", desired_final_scale, 0.2)
	if rotation_accel_enabled:
		tw.tween_property(self, "actual_rotation_speed", final_rotation_speed, rotation_accel_time)

func _disappear_anim() -> void:
	var tw = get_tree().create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tw.tween_property(self, "self_modulate:a", 0.0, 0.4)

func delete_self() -> void:
	FORCED_stop_shooting = true
	begin_shooting = false
	if has_left_the_screen:
		queue_free()
		return
	_disappear_anim()
	await get_tree().create_timer(0.4, false).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	rotation += deg_to_rad(actual_rotation_speed)
	_movement_process(delta)
	if !begin_shooting or FORCED_stop_shooting: return
	_bullet_firing_process(delta)

# Override this to customize the frame-one movement behavior
func enable_movement() -> void:
	actual_movement_velocity = movement_vector
	begin_moving = true

# Override this to customize the frame-by-frame movement behavior
func _movement_process(delta: float) -> void:
	if has_left_the_screen: delete_self()
	if !begin_moving: return
	global_position += actual_movement_velocity * delta

# Override this to customize the bullet shooting algorithm
func _bullet_firing_process(delta: float) -> void:
	if bullet_interval_timer.time_left <= 0:
		bullet_interval_timer.start(shoot_interval_sec)
		play_sound(shoot_sound_effect)
		shoot_bullet(shoot_bullet_type, shoot_bullet_speed, shoot_angle, shoot_anchor_position, shoot_bullet_color)

func shoot_bullet(bullet_type: PackedScene, speed: float, angle: float, anchor: Vector2, color: int) -> void:
	if !is_instance_valid(bullet_type): return
	var final_velocity: Vector2 = Vector2(speed * cos(angle), speed * sin(angle))
	var new_bullet = bullet_type.instantiate()
	new_bullet.veloc = final_velocity
	new_bullet.selected_color = color
	Scenes.current_scene.add_child(new_bullet)
	if (bullet_delete_pool is FinalBoss) or (bullet_delete_pool is W9Boss):
		bullet_delete_pool.bullet_pool.append(new_bullet)
	new_bullet.appear_animation()
	new_bullet.z_index = z_index + 1
	new_bullet.global_position = global_position
	new_bullet.reset_physics_interpolation()
	new_bullet.enable_movement()

func check_if_within_playfield(position_to_check: Vector2, anchor: Vector2) -> bool:
	if position_to_check.x < anchor.x - 320: return false
	if position_to_check.x > anchor.x + 320: return false
	if position_to_check.y < anchor.y - 240: return false
	if position_to_check.y > anchor.y + 240: return false
	return true

func play_sound(audio: AudioStream, interruptable: bool = true) -> void:
	if !audio:
		print("wtf there is no audio idiot")
		return
	if !interruptable:
		Audio.play_sound(audio, self)
		return
	if !is_instance_valid(node_for_playing_shoot_sound) or (node_for_playing_shoot_sound is not FinalBossHandler):
		print("Audio player not found.")
		return
	node_for_playing_shoot_sound._play_sound_interruptable(audio)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	has_left_the_screen = true

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	has_left_the_screen = false
