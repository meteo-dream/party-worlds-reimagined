extends BossSpellcardW9

const BULLET_ARROW_RED = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/bullet_arrow_red.tscn")
const AYA_VIEWFINDER = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/camera_viewfinder/aya_camera.tscn")
const sc2_arrow_speed: float = 150.0
const sc2_arrow_speed2: float = 120.0
const sc2_arrow_speed3: float = 90.0
const sc2_arrow_number_per_ring: int = 12
const sc2_viewfinder_time: float = 0.9
const sc2_viewfinder_speed: float = 650.0
const sc2_distance_from_player: float = 60.0
const sc2_rest_time: float = 1.9

var attack_round: bool = false
var shooting_photo: bool = false
var viewfinder_bullet: CameraViewfinder
@onready var sc2_viewfinder_wait_timer: Timer = $RestTimer
@onready var sc2_viewfinder_exist_timer: Timer = $ViewfinderWaitTimer

func start_attack() -> void:
	sc2_viewfinder_wait_timer.timeout.connect(prep_before_loop)
	sc2_viewfinder_exist_timer.timeout.connect(func() -> void:
		reset_boss_anim_from_attack()
		if is_instance_valid(viewfinder_bullet):
			viewfinder_bullet.take_picture()
		restore_time()
		if sc2_viewfinder_wait_timer.time_left <= 0:
			sc2_viewfinder_wait_timer.start(sc2_rest_time)
		)
	show_photo_counter()
	super()

func middle_attack() -> void:
	move_boss(boss.boss_handler.global_position + Vector2(0.0, -115.0))
	spawn_aim_eff()
	play_sound(boss.switch_to_vertical_viewfinder)
	await _set_timer(0.5)
	leaf_gather_effect()
	play_sound(boss.short_charge_up)
	await _set_timer(1.2)
	begin_attack = true
	attack_round = true
	super()

func _physics_process(delta: float) -> void:
	if _boss_attack_interrupt(): return
	if attack_round:
		attack_round = false
		delete_aim_eff()
		boss_nice_aura()
		var angle_to_boss = player.global_position.angle_to_point(boss.global_position)
		var offset_dest = Vector2(sc2_distance_from_player * cos(angle_to_boss), sc2_distance_from_player * sin(angle_to_boss))
		move_boss(player.global_position + offset_dest, 0.5)
		await _set_timer(0.65)
		if !shooting_photo and sc2_viewfinder_exist_timer.time_left <= 0:
			shooting_photo = true
			sc2_viewfinder_exist_timer.start(sc2_viewfinder_time)
			boss_play_attack_anim()
			shoot_viewfinder()
			shoot_in_ring(BULLET_ARROW_RED, sc2_arrow_speed, 5.0, aim_at_player(), sc2_arrow_number_per_ring)
			shoot_in_ring(BULLET_ARROW_RED, sc2_arrow_speed2, 5.0, aim_at_player(), int(sc2_arrow_number_per_ring * 0.8))
			shoot_in_ring(BULLET_ARROW_RED, sc2_arrow_speed3, 5.0, aim_at_player(), int(sc2_arrow_number_per_ring * 0.6))
			slow_time()

func prep_before_loop() -> void:
	if _boss_attack_interrupt(): return
	spawn_aim_eff()
	await _set_timer(0.5)
	leaf_gather_effect()
	play_sound(boss.short_charge_up)
	await _set_timer(1.2)
	attack_round = true
	shooting_photo = false
	sc2_viewfinder_exist_timer.stop()

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
	restore_time()
	begin_attack = false
	attack_round = false
	shooting_photo = true
	sc2_viewfinder_exist_timer.stop()
	super()

func shoot_in_ring(bullet_type: PackedScene, b_speed: float = 100.0, distance: float = 20.0, angle_offset: float = 0.0, lanes: int = 5) -> void:
	play_sound(boss.bullet_shoot_1)
	for i in lanes:
		var final_angle = ((PI*2)/lanes) * i + angle_offset
		shoot_at_distance(bullet_type, b_speed, distance, final_angle, final_angle)

func shoot_viewfinder(duration: float = 5.0) -> void:
	play_sound(boss.camera_zoom)
	viewfinder_bullet = AYA_VIEWFINDER.instantiate()
	viewfinder_bullet.global_rotation = aim_at_player()
	viewfinder_bullet.camera_flash = true
	viewfinder_bullet.camera_flash_growth = 0.008
	viewfinder_bullet.use_destination_vector_instead = false
	viewfinder_bullet.homing = true
	viewfinder_bullet.homing_speed = sc2_viewfinder_speed
	viewfinder_bullet.life_time = sc2_viewfinder_time
	Scenes.current_scene.add_child(viewfinder_bullet)
	boss.bullet_pool.append(viewfinder_bullet)
	viewfinder_bullet.global_position = boss.global_position
	viewfinder_bullet.reset_physics_interpolation()
	viewfinder_bullet.appear_anim()
	viewfinder_bullet.start_moving = true
	viewfinder_bullet.w9_boss = boss
	viewfinder_bullet.homing_slow_down_over_time()
	viewfinder_bullet.shrink_over_time()
