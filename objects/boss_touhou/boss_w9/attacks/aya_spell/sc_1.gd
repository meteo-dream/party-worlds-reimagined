extends BossSpellcardW9

const BULLET_ARROW_RED = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/bullet_arrow_red.tscn")
const BULLET_ARROW_PURPLE = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/bullet_arrow_purple.tscn")
const AYA_VIEWFINDER = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/camera_viewfinder/aya_camera.tscn")
const sc1_arrow_interval: float = 0.4
const sc1_arrow_speed: float = 300.0
const sc1_arrow_purple_frequency: int = 5
const sc1_arrow_number_per_ring: int = 9
const sc1_arrow_shooting_time: float = 3.5
const sc1_viewfinder_time: float = 0.9
const sc1_viewfinder_speed: float = 790.0

var arrows_shot: int = 0
var arrow_wave_enabled: bool = false
var photoshoot_enabled: bool = false
var mid_phase_movement: bool = false
var sc1_spawned_chase_eff: bool = false
var viewfinder_bullet: CameraViewfinder
@onready var sc1_viewfinder_wait_timer: Timer = $ViewfinderNoShowTimer
@onready var sc1_viewfinder_exist_timer: Timer = $ViewfinderWaitTimer
@onready var sc1_bullet_interval_timer: Timer = $IntervalTimer

func start_attack() -> void:
	sc1_viewfinder_wait_timer.timeout.connect(func() -> void:
		arrow_wave_enabled = false
		delete_aim_eff(true)
		photoshoot_enabled = true
		)
	sc1_viewfinder_exist_timer.timeout.connect(func() -> void:
		photoshoot_enabled = false
		arrow_wave_enabled = true
		mid_phase_movement = false
		reset_boss_anim_from_attack()
		if is_instance_valid(viewfinder_bullet):
			viewfinder_bullet.take_picture()
		arrows_shot = 0
		restore_time()
		)
	show_photo_counter()
	super()

func middle_attack() -> void:
	boss_to_default_start_pos()
	await _set_timer(0.5)
	leaf_gather_effect()
	play_sound(boss.short_charge_up)
	await _set_timer(1.2)
	begin_attack = true
	arrow_wave_enabled = true
	super()

func _physics_process(delta: float) -> void:
	if _boss_attack_interrupt(): return
	if arrow_wave_enabled:
		if sc1_viewfinder_wait_timer.time_left <= 0:
			sc1_viewfinder_wait_timer.start(sc1_arrow_shooting_time)
		else:
			if sc1_bullet_interval_timer.is_stopped():
				if arrows_shot % sc1_arrow_purple_frequency == 0:
					shoot_in_ring(BULLET_ARROW_PURPLE, sc1_arrow_speed, 20.0, aim_at_player() + (PI*0.125)*(arrows_shot%2), int(sc1_arrow_number_per_ring * 1.5))
				else: shoot_in_ring(BULLET_ARROW_RED, sc1_arrow_speed, 20.0, aim_at_player() + (PI*0.125)*(arrows_shot%2), sc1_arrow_number_per_ring)
				sc1_bullet_interval_timer.start(sc1_arrow_interval)
			if sc1_viewfinder_wait_timer.time_left <= (sc1_arrow_shooting_time * 0.8) and !sc1_spawned_chase_eff:
				sc1_spawned_chase_eff = true
				spawn_aim_eff(70.0, deg_to_rad(90.0))
	if !mid_phase_movement and !sc1_viewfinder_wait_timer.time_left <= 0 and sc1_viewfinder_wait_timer.time_left <= sc1_arrow_shooting_time / 2:
		mid_phase_movement = true
		boss_nice_aura()
		var upper_bound = Vector2(300, 130)
		var lower_bound = Vector2(-300, -200)
		move_boss_wander(Wander_Type.MOVE_TOWARDS_PLAYER, boss.boss_handler.global_position, upper_bound, lower_bound, randf_range(250.0, 300.0), clamp(1.7, sc1_arrow_shooting_time / 2, 1.7))
		arrow_wave_enabled = false
		delete_aim_eff()
		leaf_gather_effect(sc1_arrow_shooting_time / 2)
		play_sound(boss.short_charge_up)
	#if arrow_wave_enabled and !sc1_viewfinder_wait_timer.time_left <= 0:
		#if sc1_bullet_interval_timer.is_stopped() and arrow_wave_enabled:
			#if arrows_shot % sc1_arrow_purple_frequency == 0:
				#shoot_in_ring(BULLET_ARROW_PURPLE, sc1_arrow_speed, 20.0, aim_at_player() + (PI*0.125)*(arrows_shot%2), int(sc1_arrow_number_per_ring * 1.5))
			#else: shoot_in_ring(BULLET_ARROW_RED, sc1_arrow_speed, 20.0, aim_at_player() + (PI*0.125)*(arrows_shot%2), sc1_arrow_number_per_ring)
			#sc1_bullet_interval_timer.start(sc1_arrow_interval)
		#if sc1_viewfinder_wait_timer.time_left <= sc1_arrow_shooting_time / 2.0 and !sc1_spawned_chase_eff:
			#sc1_spawned_chase_eff = true
			#spawn_aim_eff(70.0, deg_to_rad(90.0))
	if sc1_viewfinder_exist_timer.time_left <= 0 and photoshoot_enabled:
		sc1_viewfinder_exist_timer.start(sc1_viewfinder_time)
		sc1_spawned_chase_eff = false
		boss_play_attack_anim()
		shoot_viewfinder()
		slow_time()
	

func end_attack() -> void:
	Audio.play_sound(boss.bullet_shoot_1, boss)
	if is_instance_valid(viewfinder_bullet):
		viewfinder_bullet.delete_self()
	super()
	bullet_screen_clear()
	play_sound(boss.bullet_shoot_1)
	player_gain_score(spellcard_score_bonus)
	await _set_timer(0.3)
	goto_next_spell()

func force_end_attack() -> void:
	if is_instance_valid(viewfinder_bullet):
		viewfinder_bullet.take_picture()
	super()

func end_attack_global() -> void:
	boss.keep_sc_bg = false
	restore_time()
	begin_attack = false
	arrow_wave_enabled = false
	photoshoot_enabled = false
	mid_phase_movement = false
	super()

func shoot_at_distance(bullet_type: PackedScene, b_speed: float = 100.0, distance: float = 20.0, angle: float = 0.0, rotation: float = 0.0) -> void:
	var final_position: Vector2 = boss.global_position + Vector2(distance * cos(angle), distance * sin(angle))
	shoot_bullet_from_position(bullet_type, final_position, b_speed, angle, rotation)

func shoot_in_ring(bullet_type: PackedScene, b_speed: float = 100.0, distance: float = 20.0, angle_offset: float = 0.0, lanes: int = 5) -> void:
	play_sound(boss.bullet_shoot_1)
	for i in lanes:
		var final_angle = ((PI*2)/lanes) * i + angle_offset
		shoot_at_distance(bullet_type, b_speed, distance, final_angle, final_angle)
	arrows_shot += 1

func shoot_viewfinder(duration: float = 5.0) -> void:
	play_sound(boss.camera_zoom)
	viewfinder_bullet = AYA_VIEWFINDER.instantiate()
	viewfinder_bullet.camera_rotate_offset = PI / 2
	viewfinder_bullet.rotation = aim_at_player()
	viewfinder_bullet.use_destination_vector_instead = false
	viewfinder_bullet.homing = true
	viewfinder_bullet.homing_speed = sc1_viewfinder_speed
	viewfinder_bullet.life_time = sc1_viewfinder_time
	viewfinder_bullet.camera_flash = true
	viewfinder_bullet.camera_flash_growth = 0.008
	Scenes.current_scene.add_child(viewfinder_bullet)
	boss.bullet_pool.append(viewfinder_bullet)
	viewfinder_bullet.global_position = boss.global_position
	viewfinder_bullet.reset_physics_interpolation()
	viewfinder_bullet.appear_anim()
	viewfinder_bullet.w9_boss = boss
	viewfinder_bullet.start_moving = true
	viewfinder_bullet.homing_slow_down_over_time()
	viewfinder_bullet.shrink_over_time()
