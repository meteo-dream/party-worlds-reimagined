extends BossSpellcardW9

const BULLET_RED_RINGED_CIRCLE = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/bullet_red_circle_ringed.tscn")
const BULLET_BLUE_RINGED_CIRCLE = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/bullet_blue_circle_ringed.tscn")
const sc0_ring_radius: float = 14.0
const sc0_amount_in_ring: int = 9
const sc0_amount_in_loop: int = 3
const sc0_shoot_interval: float = 0.25
const sc0_blue_speed: float = 130.0
const sc0_red_speed: float = 280.0
const wave_duration: float = 3.0
const wait_duration: float = 2.5

var attacking_phase: bool = false
var wait_phase: bool = false
var mid_phase_move: bool = false
var sc0_wave_shoot_offset: float
@onready var sc0_wave_timer: Timer = $WaveTimer
@onready var sc0_interval_timer: Timer = $IntervalTimer

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
	if attacking_phase:
		if sc0_wave_timer.is_stopped():
			boss_play_attack_anim()
			sc0_wave_timer.start(wave_duration)
			sc0_wave_timer.timeout.connect(func() -> void:
				attacking_phase = false
				)
		elif sc0_wave_timer.time_left <= (wave_duration / 1.5) and !mid_phase_move:
			mid_phase_move = true
			boss_nice_aura()
			var upper_bound = Vector2(300, -90)
			var lower_bound = Vector2(-300, -200)
			move_boss_wander(Wander_Type.MOVE_X_TOWARDS_PLAYER, boss.boss_handler.global_position, upper_bound, lower_bound, randf_range(180.0, 300.0), 1.7)
		if sc0_interval_timer.is_stopped():
			sc0_interval_timer.start(sc0_shoot_interval)
			sc0_ring_shooting(BULLET_RED_RINGED_CIRCLE, sc0_red_speed, sc0_wave_shoot_offset)
			sc0_ring_shooting(BULLET_BLUE_RINGED_CIRCLE, sc0_blue_speed, sc0_wave_shoot_offset)
			sc0_wave_shoot_offset += (((PI*2) / sc0_amount_in_loop) + (PI*2)  / 9)
			play_sound(boss.bullet_shoot_1)
	elif !attacking_phase:
		if wait_phase: return
		#reset_boss_anim_from_attack()
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
	attacking_phase = false
	sc0_wave_timer.stop()
	sc0_interval_timer.stop()
	mid_phase_move = false
	super()

func spawn_bullet_circle(bullet_type: PackedScene, radius: float, amount: int, speed: float, angle: float) -> void:
	play_sound(boss.bullet_shoot_1)
	for i in amount:
		var current_dist_angle = ((2*PI) / amount) * i
		var starting_dist_vector = Vector2(radius * cos(current_dist_angle), radius * sin(current_dist_angle))
		var starting_position = boss.global_position + starting_dist_vector
		shoot_bullet_from_position(bullet_type, starting_position, speed, angle)

func sc0_ring_shooting(bullet_type: PackedScene, speed: float = 50.0, angular_offset: float = 0.0, lanes: int = 2) -> void:
	for i in lanes:
		spawn_bullet_circle(bullet_type, sc0_ring_radius, sc0_amount_in_ring, speed, angular_offset + (PI * i))
	return
