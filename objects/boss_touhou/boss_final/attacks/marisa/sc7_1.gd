extends BossSpellcardFinal

const STAR_BIG = preload("res://objects/boss_touhou/boss_final/kevin_marisa/bullets/bullet_marisa_star_big.tscn")
const MASTER_SPARK = preload("res://objects/boss_touhou/boss_final/kevin_marisa/bullets/bullet_master_spark.tscn")
const SPARK_WARNING = preload("res://objects/boss_touhou/boss_final/kevin_marisa/spark_warning.tscn")

const comet_travel_distance: float = 950.0

# Proper settings
@export var show_warning_line: bool = false
@export_group("Marisa Comet Properties", "comet_")
@export var comet_movement_bound_size: Vector2 = Vector2(860.0, 645.0)
@export var comet_dash_time_sec: float = 0.6
@export var comet_rest_time_sec: float = 0.4
@export_group("Master Spark Properties", "spark_")
@export var spark_warning_duration_sec: float = 0.5
@export var spark_distance_from_boss: float = -40.0
@export var spark_speed: float = 2000.0
@export var spark_scale: float = 2.0
@export var spark_shoot_interval: float = 0.001
@export var spark_shoot_cone: float = 25.0
@export_group("Background Star Bullet Properties", "noise_")
@export var noise_type: PackedScene = STAR_BIG
@export var noise_count_inside: int = 4
@export var noise_speed: float = 140.0
@export var noise_interval_sec: float = 0.1
var the_player: Player
var master_spark_target: Vector2
var comet_target: Vector2
var warning_line: Node2D
var start_shooting_noise: bool = false
var shoot_master_spark: bool = false
var stop_tracking: bool = false
var FORCE_STOP_SCREEN_SHAKE: bool = false
var noise_color: int
@onready var master_spark_timer: Timer = $MasterSparkTimer
@onready var noise_bullet_interval: Timer = $NoiseBulletTimer
@onready var master_spark_interval: Timer = $MasterSparkInterval

func _ready() -> void:
	master_spark_timer.timeout.connect(func() -> void:
		shoot_master_spark = false
		stop_tracking = false
		start_shooting_noise = false
		noise_color = 0
		await _set_timer(comet_rest_time_sec + comet_dash_time_sec * 0.1)
		if _boss_attack_interrupt(): return
		add_support_platforms()
		master_spark_prep()
		await _set_timer(spark_warning_duration_sec + 1.2)
		if _boss_attack_interrupt(): return
		bullet_screen_clear(false)
		shoot_master_spark = true
		)

func start_attack() -> void:
	super()
	the_player = Thunder._current_player

func middle_attack() -> void:
	super()
	var setup_pos: Vector2 = boss.boss_handler.global_position - Vector2(0.0, 300.0)
	if boss.movement_tween:
		boss.movement_tween.kill()
	move_boss(setup_pos, 1.0)
	await _set_timer(1.5)
	master_spark_prep()
	begin_attack = true
	await _set_timer(spark_warning_duration_sec + 1.2)
	shoot_master_spark = true

func _physics_process(delta: float) -> void:
	if stop_tracking and !FORCE_END_SPELLCARD:
		do_screen_shake()
	if !shoot_master_spark and !stop_tracking:
		if is_instance_valid(the_player):
			master_spark_target = marisa_get_dash_target(true)
			comet_target = marisa_get_dash_target()
		if is_instance_valid(warning_line):
			warning_line.target_position = comet_target
	if _boss_attack_interrupt(): return
	if shoot_master_spark:
		stop_tracking = false
		if master_spark_timer.time_left <= 0.0:
			Audio.play_sound(boss.bullet_master_spark, boss)
			master_spark_timer.start(comet_dash_time_sec * 0.9)
			marisa_dash_move(comet_target)
			start_shooting_noise = true
		delete_warning_line()
		do_screen_shake(0.2, 40)
		if master_spark_interval.time_left <= 0.0:
			master_spark_interval.start(spark_shoot_interval)
			var shoot_angle: float = boss.global_position.angle_to_point(master_spark_target)
			var angle_variation: float = deg_to_rad(spark_shoot_cone / 2)
			shoot_spark(spark_speed, shoot_angle, angle_variation, spark_scale)
	if start_shooting_noise and noise_bullet_interval.time_left <= 0.0:
		noise_bullet_interval.start(noise_interval_sec)
		play_sound(boss.bullet_shoot_1, boss, true)
		if noise_color == 1: noise_color = 5
		elif noise_color == 5: noise_color = 1
		else: noise_color = 1
		var used_speed = noise_speed
		var noise_angle_diff_inside: float = 360.0 / noise_count_inside
		for j in noise_count_inside:
			var start_angle: float = -(noise_angle_diff_inside * noise_count_inside)
			var shoot_angle: float = randf_range(0.0, PI*2) + deg_to_rad(start_angle + noise_angle_diff_inside * j)
			shoot_star_bullet(noise_type, used_speed, shoot_angle, noise_color, false)

func end_attack() -> void:
	Audio.play_sound(boss.bullet_shoot_1, boss.boss_handler)
	FORCE_END_SPELLCARD = true
	super()

func end_attack_global() -> void:
	begin_attack = false
	FORCE_END_SPELLCARD = true
	master_spark_timer.stop()
	noise_bullet_interval.stop()
	master_spark_interval.stop()
	shoot_master_spark = false
	stop_tracking = false
	start_shooting_noise = false
	noise_color = 0
	delete_warning_line()
	hide_support_platforms()
	super()

func marisa_get_dash_target(behind: bool = false) -> Vector2:
	var anchor: Vector2 = boss.boss_handler.global_position
	var homing_angle: float = aim_at_player()
	var destination: Vector2 = boss.global_position + Vector2(comet_travel_distance * cos(homing_angle), comet_travel_distance * sin(homing_angle))
	var bounds_min: Vector2 = Vector2(anchor.x - (comet_movement_bound_size.x / 2), anchor.y - (comet_movement_bound_size.y / 2))
	var bounds_max: Vector2 = Vector2(anchor.x + (comet_movement_bound_size.x / 2), anchor.y + (comet_movement_bound_size.y / 2))
	destination.x = clampf(destination.x, bounds_min.x, bounds_max.x)
	destination.y = clampf(destination.y, bounds_min.y, bounds_max.y)
	
	if behind:
		homing_angle += PI
		destination = boss.global_position + Vector2(30.0 * cos(homing_angle), 30.0 * sin(homing_angle))
	
	return destination

func marisa_dash_move(target: Vector2) -> void:
	move_boss(target, comet_dash_time_sec, Tween.TransitionType.TRANS_LINEAR, Tween.EASE_IN)

func master_spark_prep() -> void:
	setup_master_spark()
	await _set_timer(spark_warning_duration_sec)
	leaf_gather_effect(1.2, 350.0, 150)
	play_sound(boss.long_charge_up)
	await _set_timer(0.3)
	stop_tracking = true
	#await _set_timer(0.9)
	#play_sound(boss.burst_sound)
	#shoot_master_spark = true

func setup_master_spark() -> void:
	if is_instance_valid(the_player):
		master_spark_target = marisa_get_dash_target(true)
		comet_target = marisa_get_dash_target()
	if !is_instance_valid(warning_line) and show_warning_line:
		warning_line = SPARK_WARNING.instantiate()
		warning_line.anchor_node = boss
		warning_line.target_position = comet_target
		warning_line.desired_x_scale = 38.0
		warning_line.scale.y = 0.5
		Scenes.current_scene.add_child(warning_line)
		warning_line.global_position = boss.global_position
		warning_line.reset_physics_interpolation()
		Audio.play_sound(boss.prepare_master_spark, boss)

func delete_warning_line() -> void:
	if is_instance_valid(warning_line):
		warning_line.delete_self()

# All angles here use radians. Convert appropriately before usage.
func shoot_spark(speed: float, angle: float, variation_angle: float, scale: float) -> void:
	var used_angle: float = angle
	if variation_angle != 0.0:
		used_angle += randf_range(-variation_angle, variation_angle)
	var final_velocity: Vector2 = Vector2(speed * cos(used_angle), speed * sin(used_angle))
	var distance: Vector2 = Vector2(spark_distance_from_boss * cos(used_angle), spark_distance_from_boss * sin(used_angle))
	var spark_bullet = MASTER_SPARK.instantiate()
	spark_bullet.veloc = final_velocity
	spark_bullet.desired_scale = Vector2(scale, scale)
	spark_bullet.bullet_erase_scale = 3.7 + clampf(scale - 1.0, -3.6, scale)
	spark_bullet.rotation = angle
	Scenes.current_scene.add_child(spark_bullet)
	boss.bullet_pool.append(spark_bullet)
	spark_bullet.global_position = boss.global_position + distance
	spark_bullet.reset_physics_interpolation()
	spark_bullet.enable_movement()

func shoot_star_bullet(bullet_type: PackedScene, speed: float, angle: float, color: int, rotate_other_way: bool = false) -> void:
	if !is_instance_valid(bullet_type): return
	var final_velocity: Vector2 = Vector2(speed * cos(angle), speed * sin(angle))
	var new_bullet = bullet_type.instantiate()
	new_bullet.veloc = final_velocity
	new_bullet.selected_color = color
	if rotate_other_way:
		new_bullet.self_rotate_speed *= -1.0
	Scenes.current_scene.add_child(new_bullet)
	boss.bullet_pool.append(new_bullet)
	new_bullet.appear_animation()
	new_bullet.z_index = boss.z_index + 1
	new_bullet.global_position = boss.global_position
	new_bullet.reset_physics_interpolation()
	new_bullet.enable_movement()
