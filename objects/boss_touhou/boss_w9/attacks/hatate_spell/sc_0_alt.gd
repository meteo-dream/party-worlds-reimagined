extends BossSpellcardW9

const BULLET_RED_RINGED_CIRCLE = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/bullet_red_circle_ringed.tscn")
const BULLET_BLUE_RINGED_CIRCLE = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/bullet_blue_circle_ringed.tscn")
const sc0_ring_radius: float = 15.0
const sc0_amount_red_in_ring: int = 3
const sc0_amount_blue_in_ring: int = 4
const sc0_amount_in_loop: int = 3
const sc0_shoot_interval: float = 0.45
const sc0_blue_speed_init: float = 200.0
const sc0_blue_speed: float = 180.0
const sc0_red_speed_init: float = 220.0
const sc0_red_speed: float = 200.0
const sc0_boss_move_time: float = 2.5
const wave_duration: float = 3.0
const boss_move_interval: float = 1.5
const wait_duration: float = 2.5

var attacking_phase: bool = false
var wait_phase: bool = false
var mid_phase_move: bool = false
var allow_random_move: bool = false
var sc0_wave_shoot_offset: float
@onready var sc0_wave_timer: Timer = $WaveTimer
@onready var sc0_interval_timer: Timer = $IntervalTimer
@onready var sc0_boss_move_interval_timer: Timer = $BossInterval

func start_attack() -> void:
	hide_photo_counter()
	super()

func middle_attack() -> void:
	sc0_wave_shoot_offset = 0.0 - deg_to_rad(25)
	begin_attack = true
	attacking_phase = true
	super()

func _physics_process(delta: float) -> void:
	if _boss_attack_interrupt(): return
	if sc0_boss_move_interval_timer.time_left <= 0.0 and allow_random_move:
		sc0_boss_move_interval_timer.start(sc0_boss_move_time + boss_move_interval)
		var upper_bound = Vector2(300, -90)
		var lower_bound = Vector2(-300, -200)
		move_boss_wander(Wander_Type.MOVE_X_TOWARDS_PLAYER, boss.boss_handler.global_position, upper_bound, lower_bound, randf_range(90.0, 200.0), sc0_boss_move_time)
		boss_nice_aura()
	if attacking_phase:
		if sc0_wave_timer.is_stopped():
			sc0_wave_timer.start(wave_duration)
			sc0_wave_timer.timeout.connect(func() -> void:
				attacking_phase = false
				)
		elif sc0_wave_timer.time_left <= (wave_duration * 0.9) and !allow_random_move:
			allow_random_move = true
		if sc0_interval_timer.is_stopped():
			sc0_interval_timer.start(sc0_shoot_interval)
			sc0_ring_shooting(BULLET_RED_RINGED_CIRCLE, sc0_ring_radius, sc0_amount_red_in_ring, sc0_red_speed_init, sc0_wave_shoot_offset, randf_range(0, (PI*2)/sc0_amount_red_in_ring), 2, 1.0, sc0_red_speed)
			sc0_ring_shooting(BULLET_BLUE_RINGED_CIRCLE, sc0_ring_radius / 2, sc0_amount_blue_in_ring, sc0_blue_speed_init, sc0_wave_shoot_offset, randf_range(0, (PI*2)/sc0_amount_red_in_ring), 2, 1.0, sc0_blue_speed)
			sc0_wave_shoot_offset += (((PI*2) / sc0_amount_in_loop) + (PI*2) / 9)
			play_sound(boss.bullet_shoot_1)
	elif !attacking_phase:
		if wait_phase: return
		wait_phase = true
		mid_phase_move = false
		sc0_wave_timer.stop()
		sc0_interval_timer.stop()
		sc0_wave_shoot_offset = 0.0 - deg_to_rad(25)
		await _set_timer(clamp(wait_duration - 1.9, 0.1, wait_duration - 1.9))
		play_sound(boss.short_charge_up)
		leaf_gather_effect()
		await _set_timer(1.5)
		wait_phase = false
		attacking_phase = true

func end_attack() -> void:
	super()
	bullet_screen_clear()
	play_sound(boss.bullet_shoot_1)
	player_gain_score(spellcard_score_bonus)
	goto_next_spell()

func force_end_attack() -> void:
	end_attack_global()
	super()

func end_attack_global() -> void:
	begin_attack = false
	allow_random_move = false
	sc0_wave_timer.stop()
	sc0_interval_timer.stop()
	sc0_boss_move_interval_timer.stop()
	mid_phase_move = false
	super()

func spawn_bullet_circle(bullet_type: PackedScene, radius: float, amount: int, speed: float, angle: float, offset: float, wait: float, b_speed: float, b_angle: float, use_circle_rotation: bool = true) -> void:
	play_sound(boss.bullet_shoot_1)
	for i in amount:
		var current_dist_angle = ((2*PI) / amount) * i + offset
		var starting_position = boss.global_position + Vector2(radius * cos(current_dist_angle), radius * sin(current_dist_angle))
		var final_rotation = b_angle
		if use_circle_rotation: final_rotation = current_dist_angle
		shoot_ringed_accel_bullet_from_position(bullet_type, starting_position, speed, wait, angle, b_speed, final_rotation, current_dist_angle)

func sc0_ring_shooting(bullet_type: PackedScene, radius: float, amount_per_ring: int = 3, speed: float = 120.0, angular_offset: float = 0.0, offset: float = 0.0, lanes: int = 2, wait: float = 1.0, b_speed: float = 100.0, b_angle: float = 0.0) -> void:
	for i in lanes:
		spawn_bullet_circle(bullet_type, radius, amount_per_ring, speed, angular_offset + (PI * i), offset, wait, b_speed, b_angle)
