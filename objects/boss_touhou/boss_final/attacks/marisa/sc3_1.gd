extends BossSpellcardFinal

const STAR_BIG = preload("res://objects/boss_touhou/boss_final/kevin_marisa/bullets/bullet_marisa_star_big.tscn")
const MASTER_SPARK = preload("res://objects/boss_touhou/boss_final/kevin_marisa/bullets/bullet_master_spark.tscn")
const SPARK_WARNING = preload("res://objects/boss_touhou/boss_final/kevin_marisa/spark_warning.tscn")

# Setting this to false = homing until right before shooting
@export var set_target_before_shooting: bool = true
# Proper settings
@export var show_warning_line: bool = false
@export_group("Master Spark Properties", "spark_")
@export var spark_warning_duration_sec: float = 0.5
@export var spark_distance_from_boss: float = 130.0
@export var spark_duration_sec: float = 4.5
@export var spark_speed: float = 1600.0
@export var spark_scale: float = 1.5
@export var spark_shoot_interval: float = 0.02
@export var spark_shoot_cone: float = 25.0
@export_group("Cooldown Properties", "cool_")
@export var cool_duration: float = 0.7
@export_group("Background Star Bullet Properties", "noise_")
@export var noise_type: PackedScene = STAR_BIG
@export var noise_count_inside: int = 2
@export var noise_count_outside: int = 30
@export var noise_speed: float = 360.0
@export var noise_interval_sec: float = 1.0
@export var noise_shoot_delay_sec: float = 0.7
@export var noise_targeted_cone: float = 64.0
var noise_angle_diff_outside: float = (360.0 - noise_targeted_cone) / noise_count_outside
var the_player: Player
var master_spark_target: Vector2
var warning_line: Node2D
var start_shooting_noise: bool = false
var shoot_master_spark: bool = false
var stop_tracking: bool = false
var noise_color: int
@onready var boss_rest_timer: Timer = $BossRestTimer
@onready var master_spark_timer: Timer = $MasterSparkTimer
@onready var noise_bullet_interval: Timer = $NoiseBulletTimer
@onready var master_spark_interval: Timer = $MasterSparkInterval

func _ready() -> void:
	master_spark_timer.timeout.connect(func() -> void:
		shoot_master_spark = false
		stop_tracking = false
		start_shooting_noise = false
		noise_color = 0
		if _boss_attack_interrupt(): return
		boss_rest_timer.start(cool_duration)
		)
	boss_rest_timer.timeout.connect(master_spark_prep)

func start_attack() -> void:
	super()
	the_player = Thunder._current_player

func middle_attack() -> void:
	super()
	master_spark_prep()
	begin_attack = true

func _physics_process(delta: float) -> void:
	if stop_tracking:
		do_screen_shake()
	if !set_target_before_shooting and !shoot_master_spark and !stop_tracking and !FORCE_END_SPELLCARD:
		if is_instance_valid(the_player):
			master_spark_target = post_bound_adjustment_value(boss.boss_handler.global_position, the_player.global_position)
		if is_instance_valid(warning_line):
			warning_line.target_position = master_spark_target
	if _boss_attack_interrupt(): return
	if shoot_master_spark:
		stop_tracking = false
		if master_spark_timer.time_left <= 0.0:
			Audio.play_sound(boss.bullet_master_spark, boss)
			master_spark_timer.start(spark_duration_sec)
			await _set_timer(noise_shoot_delay_sec)
			if _boss_attack_interrupt(): return
			start_shooting_noise = true
		delete_warning_line()
		do_screen_shake(0.2, 27)
		if master_spark_interval.time_left <= 0.0:
			master_spark_interval.start(spark_shoot_interval)
			var shoot_angle: float = boss.global_position.angle_to_point(master_spark_target)
			var angle_variation: float = deg_to_rad(spark_shoot_cone / 2)
			for i in 3: shoot_spark(spark_speed, shoot_angle, angle_variation, spark_scale)
	if start_shooting_noise and noise_bullet_interval.time_left <= 0.0:
		noise_bullet_interval.start(noise_interval_sec)
		play_sound(boss.bullet_shoot_1, boss, true)
		var homing_pos: Vector2
		if is_instance_valid(the_player): homing_pos = the_player.global_position
		noise_color = wrapi(noise_color + 1, 0, 7)
		var shift_rotate: bool = false
		if noise_color % 2 == 1: shift_rotate = true
		for k in 2:
			var used_speed = noise_speed
			if k % 2 == 0: used_speed *= 0.75
			var used_inside_count: int = noise_count_inside
			var noise_angle_diff_inside: float = (noise_targeted_cone / 2.0) / ceil(used_inside_count / 2.0)
			for i in noise_count_outside + 1:
				var offset_angle: float = deg_to_rad((noise_angle_diff_outside * i) + (noise_targeted_cone / 2.0))
				var shoot_angle: float = boss.global_position.angle_to_point(homing_pos) + offset_angle
				shoot_star_bullet(noise_type, used_speed, shoot_angle, noise_color, shift_rotate)
			for j in used_inside_count:
				var start_angle: float = -(noise_angle_diff_inside * ceil(used_inside_count / 2.0))
				var shoot_angle: float = boss.global_position.angle_to_point(homing_pos) + deg_to_rad(start_angle + noise_angle_diff_inside * j)
				shoot_star_bullet(noise_type, used_speed, shoot_angle, noise_color, shift_rotate)

func end_attack() -> void:
	Audio.play_sound(boss.bullet_shoot_1, boss.boss_handler)
	FORCE_END_SPELLCARD = true
	super()

func end_attack_global() -> void:
	begin_attack = false
	master_spark_timer.stop()
	boss_rest_timer.stop()
	noise_bullet_interval.stop()
	master_spark_interval.stop()
	shoot_master_spark = false
	stop_tracking = false
	start_shooting_noise = false
	noise_color = 0
	delete_warning_line()
	super()

func master_spark_prep() -> void:
	move_boss_predefined()
	setup_master_spark()
	await _set_timer(spark_warning_duration_sec)
	leaf_gather_effect(1.4)
	play_sound(boss.long_charge_up)
	await _set_timer(0.6)
	if _boss_attack_interrupt(): return
	stop_tracking = true
	await _set_timer(1.0)
	if _boss_attack_interrupt(): return
	play_sound(boss.burst_sound)
	shoot_master_spark = true

func move_boss_predefined() -> void:
	var anchor_pos: Vector2 = boss.boss_handler.global_position
	var new_pos: Vector2 = anchor_pos + Vector2(-215.0, -150.0)
	the_player = Thunder._current_player
	if is_instance_valid(the_player):
		if the_player.global_position.x <= boss.boss_handler.global_position.x:
			new_pos.x = anchor_pos.x + 215.0
	if boss.global_position != new_pos:
		move_boss(new_pos, 1.1 + spark_warning_duration_sec)

func setup_master_spark() -> void:
	if is_instance_valid(the_player):
		master_spark_target = post_bound_adjustment_value(boss.boss_handler.global_position, the_player.global_position)
	if !is_instance_valid(warning_line) and show_warning_line:
		warning_line = SPARK_WARNING.instantiate()
		warning_line.anchor_node = boss
		warning_line.target_position = master_spark_target
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

func post_bound_adjustment_value(anchor: Vector2, new_value: Vector2) -> Vector2:
	var final_value: Vector2
	final_value.x = clampf(new_value.x, anchor.x - 200.0, anchor.x + 200.0)
	final_value.y = clampf(new_value.y, anchor.y - 180.0, anchor.y + 180.0)
	return final_value
