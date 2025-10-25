extends BossSpellcardFinal

const BUBBLE_RED = preload("res://objects/boss_touhou/boss_final/remilia/bullets/bullet_big_bubble_red.tscn")
const BIG_RED = preload("res://objects/boss_touhou/boss_final/remilia/bullets/bullet_big_red.tscn")
const RED_RINGED = preload("res://objects/boss_touhou/boss_final/remilia/bullets/bullet_red_circle_ringed.tscn")

@export var sc6_force_no_bounce: bool = false
@export var sc2_initial_shot_speed: float = 550.0
@export var sc2_shot_spread: float = 14.0
@export var sc2_phase_interval: float = 1.9
@export var sc2_phase2_cone: float = 45.0
@export var sc2_subshot1_amount: int = 25
@export var sc2_subshot2_amount: int = 40
@export var sc2_is_end_phase: bool = false
@onready var shot_interval_timer: Timer = $ShotInterval
var waves_shot: int = 0
var special_stop_shooting_after: bool = false
var stop_shooting: bool = false

func _ready() -> void:
	shot_interval_timer.timeout.connect(func() -> void:
		if !is_new_spell_card and !sc2_is_end_phase and waves_shot > 2:
			move_boss(boss.boss_handler.global_position + Vector2(0.0, -50.0), 1.2)
			waves_shot = 0
			if Engine.time_scale > 1.0:
				add_support_platforms()
			special_stop_shooting_after = true
			return
		move_boss_chase_player()
	)

func middle_attack() -> void:
	if is_new_spell_card or sc2_is_end_phase:
		var x_offset = 150.0
		var anchor = boss.boss_handler.global_position
		if is_instance_valid(Thunder._current_player):
			if Thunder._current_player.global_position.x > anchor.x: x_offset *= -1.0
		var destination_pos: Vector2 = Vector2(anchor.x + x_offset, anchor.y - 50.0)
		move_boss(destination_pos, 1.0)
		add_support_platforms()
		await _set_timer(0.8)
	else:
		move_boss_chase_player()
		hide_support_platforms()
	begin_attack = true
	super()

func end_attack() -> void:
	if (!sc2_is_end_phase and !is_new_spell_card) or is_new_spell_card:
		boss._danmaku_clear_screen(false)
	super()

func _physics_process(delta: float) -> void:
	if _boss_attack_interrupt() or stop_shooting: return
	if shot_interval_timer.time_left <= 0:
		var waiting_time = sc2_phase_interval + 1.2
		if is_new_spell_card and waves_shot > 1 and !sc2_is_end_phase:
			waves_shot = -1
			waiting_time += 2.5
		shot_interval_timer.start(waiting_time)
		leaf_gather_effect()
		play_sound(boss.short_charge_up)
		await _set_timer(1.2)
		if sc2_is_end_phase and waves_shot > 0:
			bullet_screen_clear(false)
			waves_shot = 0
		waves_shot += 1
		if !is_new_spell_card and !sc2_is_end_phase:
			for i in 5:
				spawn_scarlet_shot(true, true, deg_to_rad(-90.0 + ((sc2_phase2_cone / 4.0) * (-2 + i))))
		else:
			if sc6_force_no_bounce:
				for i in 3:
					var offset_angle: float = aim_at_player() - (deg_to_rad(110.0) * 1) + (deg_to_rad(110.0) * i)
					spawn_scarlet_shot(true, !sc2_is_end_phase, offset_angle)
			else:
				spawn_scarlet_shot(true, !sc2_is_end_phase, aim_at_player())
		if special_stop_shooting_after: stop_shooting = true
		if _boss_attack_interrupt(): return
		play_sound(boss.bullet_shoot_1, boss, true)

func end_attack_global() -> void:
	begin_attack = false
	waves_shot = 0
	shot_interval_timer.stop()
	if sc2_is_end_phase:
		hide_support_platforms()
	special_stop_shooting_after = false
	super()

func move_boss_chase_player() -> void:
	boss_nice_aura()
	var upper_bound = Vector2(300, -50)
	var lower_bound = Vector2(-300, -200)
	var wander_style = Wander_Type.RANDOM
	if !is_new_spell_card and !sc2_is_end_phase:
			wander_style = Wander_Type.MOVE_TOWARDS_PLAYER
	move_boss_wander(wander_style, boss.boss_handler.global_position, upper_bound, lower_bound, randf_range(90.0, 230.0), 1.2)

func spawn_scarlet_shot(bouncy: bool = false, bounce_once: bool = true, angle: float = 0.0, angle_spread: float = deg_to_rad(sc2_shot_spread), fastest_speed: float = sc2_initial_shot_speed) -> void:
	if _boss_attack_interrupt(): return
	var angle_spread_half: float = angle_spread * 0.5
	var angle_spread_subshot1: float = angle_spread_half * 0.8
	# Big bubble shot
	shoot_simple_bouncy_shot(BUBBLE_RED, fastest_speed, angle, bouncy, bounce_once, 0.0)
	# Trail shot 1
	for i in sc2_subshot1_amount:
		var subshot_speed: float = randf_range(fastest_speed * 0.55, fastest_speed * 0.95)
		var subshot_angle: float = angle + randf_range(-angle_spread_subshot1, angle_spread_subshot1)
		shoot_simple_bouncy_shot(BIG_RED, subshot_speed, subshot_angle, bouncy, bounce_once, 0.0)
	# Trail shot 2
	for k in sc2_subshot2_amount:
		var subshot_speed: float = randf_range(fastest_speed * 0.1, fastest_speed * 0.8)
		if !is_new_spell_card and !sc2_is_end_phase: subshot_speed = randf_range(fastest_speed * 0.25, fastest_speed * 0.9)
		var subshot_angle: float = angle + randf_range(-angle_spread_half, angle_spread_half)
		shoot_simple_bouncy_shot(RED_RINGED, subshot_speed, subshot_angle, bouncy, bounce_once, 0.0)

func shoot_simple_normal_shot(bullet_type: PackedScene, speed: float = 2.0, angle: float = 0.0) -> void:
	var calc_velocity: Vector2 = Vector2(speed * cos(angle), speed * sin(angle))
	shoot_simple_bullet(bullet_type, boss.global_position, calc_velocity, angle)

func shoot_simple_bouncy_shot(bullet_type: PackedScene, speed: float = 50.0, angle: float = 0.0, bouncy: bool = true, bounce_once: bool = false, rotation: float = 0.0) -> void:
	var calculated_velocity: Vector2 = Vector2(speed * cos(angle), speed * sin(angle))
	shoot_bouncy_bullet(bullet_type, boss.global_position, calculated_velocity, rotation, bouncy, bounce_once)

func shoot_bouncy_bullet(bullet_type: PackedScene, init_position: Vector2 = Vector2.ZERO, b_velocity: Vector2 = Vector2(50.0, 50.0), rotation: float = 0.0, bouncy: bool = true, bounce_once: bool = false) -> void:
	if !check_if_within_playfield(init_position): return
	var bullet_shot = bullet_type.instantiate()
	bullet_shot.rotation = rotation
	bullet_shot.veloc = b_velocity
	bullet_shot.bouncy = bouncy
	bullet_shot.bounce_once = bounce_once
	if sc6_force_no_bounce:
		bullet_shot.bouncy = false
	bullet_shot.anchor_for_bounce = boss.boss_handler.global_position
	Scenes.current_scene.add_child(bullet_shot)
	boss.bullet_pool.append(bullet_shot)
	bullet_shot.appear_animation()
	bullet_shot.z_index = boss.z_index + 1
	bullet_shot.global_position = init_position
	bullet_shot.reset_physics_interpolation()
	bullet_shot.enable_movement()
	if !is_new_spell_card and !sc2_is_end_phase:
		await _set_timer(sc2_phase_interval * 0.9)
		if is_instance_valid(bullet_shot): bullet_shot.delete_self()
		if begin_attack: hide_support_platforms()
