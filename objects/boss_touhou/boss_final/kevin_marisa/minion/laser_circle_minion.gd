extends "res://objects/boss_touhou/common/magic_circle_minion.gd"

const GLOW_TRAIL = preload("res://objects/boss_touhou/boss_final/kevin_marisa/minion/minion_trail.tscn")

@export_group("Movement Properties", "move_")
@export var move_destination: Vector2
@export var move_time_sec: float = 1.0
@export_group("Shooting Properties", "shoot_")
@export var shoot_laser_life_time_sec: float = 1.0
@export var shoot_use_laser_blast_instead: bool = false
@export var shoot_use_as_warning: bool = false
@export var shoot_desired_scale: float = 1.5
@export var shoot_wait_time: float = 1.0
@export var shoot_resize_time: float = 0.5
@export var shoot_life_time: float = 1.0
@export var shoot_disappear_time: float = 0.5
var laser_bullet: Node2D
var laser_shot: bool = false
@onready var disappear_timer: Timer = $DisappearTimer
@onready var shoot_eff: Sprite2D = $LaserShootEffect

@onready var quality: SettingsManager.QUALITY = SettingsManager.settings.quality
@onready var QUALITY = SettingsManager.QUALITY

# Laser blast is treated the same as a normal bullet.
var appear_anim_list: Array[int] = [2, 1, 6, 6, 5, 3, 4]

func _ready() -> void:
	if is_instance_valid(shoot_eff):
		shoot_eff.self_modulate.a = 0.0
		shoot_eff.frame = appear_anim_list[shoot_bullet_color]
	disappear_timer.timeout.connect(func() -> void:
		delete_self()
		if is_instance_valid(shoot_eff):
			shoot_eff.self_modulate.a = 0.0
		)
	SettingsManager.settings_updated.connect(func() -> void:
		quality = SettingsManager.settings.quality)
	super()

func _shoot_wait(time: float) -> void:
	await get_tree().create_timer(time + 0.3, false).timeout
	begin_shooting = true

func _appear_anim() -> void:
	var tw = get_tree().create_tween()
	tw.set_parallel(true)
	if do_appear_animation:
		tw.tween_property(self, "self_modulate:a", desired_final_alpha, 0.03)
		tw.tween_property(self, "scale", desired_final_scale, 0.04)
	if rotation_accel_enabled:
		tw.tween_property(self, "actual_rotation_speed", final_rotation_speed, rotation_accel_time)

func enable_movement() -> void:
	var tw = get_tree().create_tween()
	tw.set_trans(Tween.TRANS_CIRC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", move_destination, move_time_sec)

func _physics_process(delta: float) -> void:
	if is_instance_valid(shoot_eff):
		shoot_eff.rotation -= deg_to_rad(actual_rotation_speed)
	super(delta)

func _movement_process(delta: float) -> void:
	var distance_between: float = absf(global_position.distance_to(move_destination))
	if !begin_shooting and distance_between > 8.0 and bullet_interval_timer.time_left <= 0.0:
		bullet_interval_timer.start(move_time_sec * 0.02)
		_spawn_trail_effect()

func _spawn_trail_effect() -> void:
	if quality == QUALITY.MIN: return
	var glow_trail = GLOW_TRAIL.instantiate()
	Scenes.current_scene.add_child(glow_trail)
	glow_trail.z_index = z_index - 2
	glow_trail.global_position = global_position
	glow_trail.reset_physics_interpolation()

func _bullet_firing_process(delta: float) -> void:
	if !is_instance_valid(laser_bullet) and !laser_shot:
		if !is_instance_valid(shoot_bullet_type): return
		laser_bullet = shoot_bullet_type.instantiate()
		laser_bullet.veloc = Vector2.ZERO
		laser_bullet.rotation = shoot_angle
		laser_bullet.selected_color = shoot_bullet_color
		# The laser's properties.
		laser_bullet.use_as_warning = shoot_use_as_warning
		laser_bullet.desired_scale = shoot_desired_scale
		laser_bullet.wait_time = shoot_wait_time
		laser_bullet.resize_time = shoot_resize_time
		laser_bullet.life_time = shoot_life_time
		laser_bullet.disappear_time = shoot_disappear_time
		# Boilerplate.
		Scenes.current_scene.add_child(laser_bullet)
		if (bullet_delete_pool is FinalBoss) or (bullet_delete_pool is W9Boss):
			bullet_delete_pool.bullet_pool.append(laser_bullet)
		laser_bullet.appear_animation()
		laser_bullet.z_index = z_index + 1
		#laser_bullet.enable_movement()
		play_sound(shoot_sound_effect)
		disappear_timer.start(shoot_wait_time + shoot_resize_time + shoot_life_time + shoot_disappear_time)
		laser_shot = true
		if is_instance_valid(shoot_eff):
			shoot_eff.self_modulate.a = 1.0
	elif is_instance_valid(laser_bullet):
		laser_bullet.global_position = global_position
		laser_bullet.reset_physics_interpolation()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if is_instance_valid(laser_bullet): laser_bullet.queue_free()
	queue_free()

func delete_self() -> void:
	laser_shot = true
	super()
