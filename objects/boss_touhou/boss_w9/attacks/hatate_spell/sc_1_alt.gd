extends BossSpellcardW9

const BULLET_ARROW_BLUE = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/bullet_arrow_blue.tscn")
const HATATE_VIEWFINDER = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/camera_viewfinder/hatate_camera.tscn")
const sc1_arrow_interval: float = 0.1
const sc1_arrow_speed: float = 400.0
const sc1_arrow_number_per_ring: int = 6
const sc1_viewfinder_time: float = 0.75
const sc1_viewfinder_speed: float = 80.0
const sc1_viewfinder_distance: float = 60.0
const sc1_cycle_repeat_delay: float = 0.6

const sc1_boss_move_time: float = 1.7
const sc1_boss_move_interval: float = 0.5

var allow_random_move: bool = false
var arrow_wave_enabled: bool = false
var photoshoot_wave_enabled: bool = false
var spin_clockwise: bool = false
var grabbed_player_position: bool = false
var player_pos_shooting: float
var times_moved: int
var rings_shot: int

var viewfinder_bullet: CameraViewfinder
@onready var sc1_viewfinder_wait_timer: Timer = $ViewfinderNoShowTimer
@onready var sc1_viewfinder_exist_timer: Timer = $ViewfinderWaitTimer
@onready var sc1_bullet_interval_timer: Timer = $ArrowIntervalTimer
@onready var sc1_boss_move_interval_timer: Timer = $BossMoveInterval

func start_attack() -> void:
	sc1_viewfinder_wait_timer.timeout.connect(func() -> void:
		arrow_wave_enabled = false
		photoshoot_wave_enabled = true
		)
	sc1_viewfinder_exist_timer.timeout.connect(func() -> void:
		photoshoot_wave_enabled = false
		arrow_wave_enabled = true
		if is_instance_valid(viewfinder_bullet):
			if !viewfinder_bullet.photo_taken:
				viewfinder_bullet.take_picture()
				_hatate_attack_anim()
				await _set_timer(0.3)
				if hatate_attack_anim_played: reset_boss_anim_from_attack()
				restore_time()
		allow_random_move = true
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
	if !boss.force_end_player_death:
		if player.global_position.x > boss.global_position.x: spin_clockwise = true
		elif player.global_position.x < boss.global_position.x: spin_clockwise = false
	# Movement co-step
	if sc1_boss_move_interval_timer.is_stopped() and allow_random_move:
		sc1_boss_move_interval_timer.start(sc1_boss_move_time + sc1_boss_move_interval)
		var upper_bound = Vector2(300, -50)
		var lower_bound = Vector2(-300, -200)
		var wander_style = Wander_Type.RANDOM
		if times_moved >= 2:
			wander_style = Wander_Type.MOVE_TOWARDS_PLAYER
		move_boss_wander(wander_style, boss.boss_handler.global_position, upper_bound, lower_bound, randf_range(90.0, 160.0), sc1_boss_move_time)
		times_moved += 1
		if times_moved >= 3: spawn_aim_eff(85.0, 0.0, 1.2)
	# Hatate can wander around as a treat
	if !allow_random_move and !photoshoot_wave_enabled:
		allow_random_move = true
	# Mass firing step
	if sc1_bullet_interval_timer.is_stopped() and arrow_wave_enabled and !photoshoot_wave_enabled:
		if !grabbed_player_position:
			grabbed_player_position = true
			player_pos_shooting = aim_at_player()
		sc1_bullet_interval_timer.start(sc1_arrow_interval)
		shoot_in_ring(BULLET_ARROW_BLUE, sc1_arrow_speed, 13.0, player_pos_shooting + (PI / sc1_arrow_number_per_ring) + ((PI / 100) * rings_shot), sc1_arrow_number_per_ring)
		if !spin_clockwise: rings_shot -= 1
		else: rings_shot += 1
	# Check to see if it's time for the photoshoot
	if times_moved >= 3 and !photoshoot_wave_enabled and !boss.is_moving:
		photoshoot_wave_enabled = true
	# PHOTOSHOOT!!! step
	if sc1_viewfinder_exist_timer.is_stopped() and photoshoot_wave_enabled:
		delete_aim_eff(true)
		allow_random_move = false
		spin_clockwise = false
		grabbed_player_position = false
		times_moved = 0
		rings_shot = 0
		sc1_viewfinder_exist_timer.start(sc1_viewfinder_time + sc1_cycle_repeat_delay)
		var atk_time = get_tree().create_timer(sc1_viewfinder_time)
		atk_time.timeout.connect(func() -> void:
			restore_time()
			)
		var atk_time2 = get_tree().create_timer(sc1_viewfinder_time - 0.1)
		atk_time2.timeout.connect(func() -> void:
			_hatate_attack_anim()
			await _set_timer(0.3)
			if hatate_attack_anim_played: reset_boss_anim_from_attack()
			)
		boss_nice_aura()
		boss_play_attack_anim()
		shoot_viewfinder(sc1_viewfinder_time, sc1_viewfinder_speed, aim_at_player())
		slow_time()

func end_attack() -> void:
	Audio.play_sound(boss.bullet_shoot_1, boss)
	if is_instance_valid(viewfinder_bullet):
		viewfinder_bullet.delete_self()
	super()
	bullet_screen_clear()
	play_sound(boss.bullet_shoot_1)
	player_gain_score(spellcard_score_bonus)
	await _set_timer(0.2)
	goto_next_spell()

func force_end_attack() -> void:
	if is_instance_valid(viewfinder_bullet):
		viewfinder_bullet.take_picture()
	super()

func end_attack_global() -> void:
	restore_time()
	reset_boss_anim()
	begin_attack = false
	arrow_wave_enabled = false
	photoshoot_wave_enabled = false
	allow_random_move = false
	grabbed_player_position = false
	spin_clockwise = false
	super()

func shoot_at_distance(bullet_type: PackedScene, b_speed: float = 100.0, distance: float = 20.0, angle: float = 0.0, rotation: float = 0.0) -> void:
	var final_position: Vector2 = boss.global_position + Vector2(distance * cos(angle), distance * sin(angle))
	shoot_bullet_from_position(bullet_type, final_position, b_speed, angle, rotation)

func shoot_in_ring(bullet_type: PackedScene, b_speed: float = 100.0, distance: float = 20.0, angle_offset: float = 0.0, lanes: int = 5) -> void:
	play_sound(boss.bullet_shoot_1, null, true)
	for i in lanes:
		var final_angle = ((PI*2)/lanes) * i + angle_offset
		shoot_at_distance(bullet_type, b_speed, distance, final_angle, final_angle)

func shoot_viewfinder(duration: float = 5.0, speed: float = 50.0, angle: float = 0.0, rotation_offset: float = 0.0, scale: float = 1.3) -> void:
	play_sound(boss.camera_zoom)
	var result_veloc = Vector2(speed * cos(angle), speed * sin(angle))
	var result_distance = Vector2(sc1_viewfinder_distance * cos(angle), sc1_viewfinder_distance * sin(angle))
	viewfinder_bullet = HATATE_VIEWFINDER.instantiate()
	viewfinder_bullet.w9_boss = boss
	viewfinder_bullet.use_destination_vector_instead = false
	viewfinder_bullet.velocity = result_veloc
	viewfinder_bullet.rotation = angle
	viewfinder_bullet.life_time = sc1_viewfinder_time
	viewfinder_bullet.scale = Vector2(scale, 0.0)
	viewfinder_bullet.hatate_camera = true
	viewfinder_bullet.camera_rotate_offset = rotation_offset
	viewfinder_bullet.camera_flash = true
	viewfinder_bullet.camera_flash_growth = 0.005
	Scenes.current_scene.add_child(viewfinder_bullet)
	boss.bullet_pool.append(viewfinder_bullet)
	viewfinder_bullet.z_index = boss.z_index + 8
	viewfinder_bullet.global_position = boss.global_position + result_distance
	viewfinder_bullet.reset_physics_interpolation()
	viewfinder_bullet.appear_anim(true, scale)
	viewfinder_bullet.start_moving = true
