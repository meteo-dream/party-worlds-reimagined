extends BossSpellcardW9

const BULLET_ARROW_BLUE = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/bullet_arrow_blue.tscn")
const HATATE_VIEWFINDER = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/camera_viewfinder/hatate_camera.tscn")
const sc2_total_viewfinder_time: float = 1.1
const sc2_single_viewfinder_time: float = 0.8
const sc2_viewfinder_count: int = 5
const sc2_viewfinder_speed: float = 93.0
const sc2_viewfinder_distance: float = 65.0
const sc2_viewfinder_delay: float = ((sc2_total_viewfinder_time - sc2_single_viewfinder_time) / sc2_viewfinder_count) + 0.01
const sc2_boss_wander_time: float = 1.0
const sc2_boss_postshoot_rest: float = 0.6
const sc2_boss_postshoot_wander_time: float = sc2_boss_wander_time
const sc2_boss_shoot_time: float = 0.7
const sc2_boss_shoot_interval: float = 0.02
const sc2_postshoot_rest: float = 0.8
const sc2_shoot_init_speed_max: float = 450.0
const sc2_shoot_init_speed_min: float = 230.0
const sc2_shoot_after_speed_max: float = 230.0
const sc2_shoot_after_speed_min: float = 140.0
const sc2_shoot_decel_time: float = 1.0
const sc2_shoot_distance: float = 3.0
const sc2_arrow_per_shooting: int = 10
const sc2_arrow_range: float = deg_to_rad(90)

var shoot_wave: bool = false
var photo_wave: bool = false
var wander_wave: bool = false
var sc2_chase_eff: bool = false
var viewfinder_bullet: CameraViewfinder
var viewfinder_pool: Array[CameraViewfinder]
@onready var sc2_shoot_interval_timer: Timer = $ShootPhaseTimer
@onready var sc2_shoot_total_timer: Timer = $ShootTotalTimer
@onready var sc2_cooldown_timer: Timer = $CooldownRestTimer
@onready var sc2_viewfinder_timer: Timer = $ViewfinderExistTimer


func start_attack() -> void:
	sc2_shoot_total_timer.timeout.connect(func() -> void:
		shoot_wave = false
		await _set_timer(sc2_postshoot_rest)
		photo_wave = true
		)
	sc2_viewfinder_timer.timeout.connect(func() -> void:
		photo_wave = false
		await _set_timer(sc2_boss_postshoot_rest)
		wander_wave = true
		)
	sc2_cooldown_timer.timeout.connect(func() -> void:
		wander_wave = false
		sc2_chase_eff = false
		shoot_wave = true
		)
	show_photo_counter()
	super()

func middle_attack() -> void:
	move_boss(boss.boss_handler.global_position + Vector2(0.0, -115.0))
	await _set_timer(0.5)
	leaf_gather_effect()
	play_sound(boss.short_charge_up)
	await _set_timer(1.2)
	begin_attack = true
	shoot_wave = true
	super()

func _physics_process(delta: float) -> void:
	if _boss_attack_interrupt(): return
	# Arrow-shooting step
	if shoot_wave:
		if !sc2_shoot_total_timer.is_stopped() and sc2_shoot_total_timer.time_left <= (sc2_boss_shoot_time / 2.0) and !sc2_chase_eff:
			sc2_chase_eff = true
			spawn_aim_eff(85.0, 0.0, 1.2)
		if sc2_shoot_total_timer.is_stopped():
			sc2_shoot_total_timer.start(sc2_boss_shoot_time)
			var upper_bound = Vector2(300, 20)
			var lower_bound = Vector2(-300, -100)
			move_boss_wander(Wander_Type.MOVE_TOWARDS_PLAYER, boss.boss_handler.global_position, upper_bound, lower_bound, randf_range(90.0, 250.0), sc2_boss_shoot_time + 0.5)
		if sc2_shoot_interval_timer.is_stopped():
			sc2_shoot_interval_timer.start(sc2_boss_shoot_interval)
			play_sound(boss.bullet_twinkle, null, true)
			for i in sc2_arrow_per_shooting:
				var shoot_range_min = aim_at_player() + (sc2_arrow_range / 2)
				var shoot_range_max = aim_at_player() + ((PI*2) - (sc2_arrow_range / 2))
				var rand_angle = randf_range(shoot_range_min, shoot_range_max)
				var rand_speed = randf_range(sc2_shoot_init_speed_min, sc2_shoot_init_speed_max)
				var rand_later_speed = randf_range(sc2_shoot_after_speed_min, sc2_shoot_after_speed_max)
				shoot_decel_bullet(BULLET_ARROW_BLUE, boss.global_position, sc2_shoot_distance, rand_speed, rand_later_speed, rand_angle, rand_angle, sc2_shoot_decel_time)
	# Photoshoot step
	if photo_wave:
		if sc2_viewfinder_timer.is_stopped():
			sc2_viewfinder_timer.start(sc2_total_viewfinder_time)
			delete_aim_eff(true)
			var atk_time = get_tree().create_timer(sc2_single_viewfinder_time)
			atk_time.timeout.connect(func() -> void:
				restore_time()
				_hatate_attack_anim()
				await _set_timer(0.3)
				if hatate_attack_anim_played: reset_boss_anim_from_attack()
				)
			var starting_angle = aim_at_player() - (PI / 2)
			boss_nice_aura()
			boss_play_attack_anim()
			play_sound(boss.camera_zoom)
			slow_time()
			for i in sc2_viewfinder_count:
				if !photo_wave: continue
				play_sound(boss.camera_zoom, null, true)
				var used_angle = starting_angle + (PI / (sc2_viewfinder_count - 1)) * i
				shoot_viewfinder(sc2_single_viewfinder_time, sc2_viewfinder_speed, used_angle)
				await _set_timer(sc2_viewfinder_delay)
	# Wander-around-like-a-hobo step
	if wander_wave:
		if sc2_cooldown_timer.is_stopped():
			sc2_cooldown_timer.start(sc2_boss_postshoot_wander_time)
			var upper_bound = Vector2(300, 80)
			var lower_bound = Vector2(-300, -100)
			move_boss_wander(Wander_Type.RANDOM, boss.boss_handler.global_position, upper_bound, lower_bound, randf_range(80.0, 180.0), sc2_boss_postshoot_wander_time)

func prep_before_loop() -> void:
	if _boss_attack_interrupt(): return
	leaf_gather_effect()
	play_sound(boss.short_charge_up)
	await _set_timer(1.2)
	#

func end_attack() -> void:
	Audio.play_sound(boss.bullet_shoot_1, boss)
	for i in viewfinder_pool.size():
		if is_instance_valid(viewfinder_pool[i]):
			viewfinder_pool[i].delete_self()
	super()
	bullet_screen_clear()
	play_sound(boss.bullet_shoot_1)
	player_gain_score(spellcard_score_bonus)
	await _set_timer(0.3)
	goto_next_spell()

func force_end_attack() -> void:
	for i in viewfinder_pool.size():
		if is_instance_valid(viewfinder_pool[i]):
			viewfinder_pool[i].take_picture()
	super()

func end_attack_global() -> void:
	restore_time()
	reset_boss_anim()
	begin_attack = false
	shoot_wave = false
	photo_wave = false
	wander_wave = false
	sc2_shoot_interval_timer.stop()
	sc2_shoot_total_timer.stop()
	sc2_cooldown_timer.stop()
	sc2_viewfinder_timer.stop()
	super()

func shoot_decel_bullet(bullet_type: PackedScene, init_position: Vector2, distance: float = 15.0, b_velocity: float = 100.0, new_velocity: float = 50.0, angle: float = 0.0, rotation: float = 0.0, decel_time: float = 1.0) -> void:
	if !check_if_within_playfield(init_position): return
	var bullet_shot = bullet_type.instantiate()
	bullet_shot.rotation = rotation
	bullet_shot.veloc = Vector2(b_velocity * cos(angle), b_velocity * sin(angle))
	Scenes.current_scene.add_child(bullet_shot)
	boss.bullet_pool.append(bullet_shot)
	bullet_shot.z_index = boss.z_index + 2
	bullet_shot.global_position = init_position + Vector2(distance * cos(angle), distance * sin(angle))
	bullet_shot.reset_physics_interpolation()
	bullet_shot.enable_movement()
	bullet_shot.tween_bullet_speed(new_velocity, decel_time)

func shoot_viewfinder(duration: float = 5.0, speed: float = 50.0, angle: float = 0.0, rotation_offset: float = 0.0, scale: float = 1.3) -> void:
	var result_veloc = Vector2(speed * cos(angle), speed * sin(angle))
	var result_distance = Vector2(sc2_viewfinder_distance * cos(angle), sc2_viewfinder_distance * sin(angle))
	viewfinder_bullet = HATATE_VIEWFINDER.instantiate()
	viewfinder_bullet.w9_boss = boss
	viewfinder_bullet.use_destination_vector_instead = false
	viewfinder_bullet.velocity = result_veloc
	viewfinder_bullet.rotation = angle
	viewfinder_bullet.life_time = sc2_single_viewfinder_time
	viewfinder_bullet.scale = Vector2(scale, 0.0)
	viewfinder_bullet.camera_rotate_offset = rotation_offset
	viewfinder_bullet.camera_flash = true
	viewfinder_bullet.camera_flash_growth = 0.005
	Scenes.current_scene.add_child(viewfinder_bullet)
	boss.bullet_pool.append(viewfinder_bullet)
	viewfinder_pool.append(viewfinder_bullet)
	viewfinder_bullet.z_index = boss.z_index + 8
	viewfinder_bullet.global_position = boss.global_position + result_distance
	viewfinder_bullet.reset_physics_interpolation()
	viewfinder_bullet.appear_anim(true, scale)
	viewfinder_bullet.start_moving = true
