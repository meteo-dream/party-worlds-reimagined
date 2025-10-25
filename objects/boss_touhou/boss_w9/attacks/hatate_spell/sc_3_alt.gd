extends BossSpellcardW9

const BULLET_AMULET_PURPLE = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/bullet_amulet_purple.tscn")
const HATATE_VIEWFINDER = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/camera_viewfinder/hatate_camera.tscn")
const sc3_amulet_count: int = 300
const sc3_amulet_init_speed: float = 5.0
const sc3_amulet_later_speed: float = 150.0
const sc3_amulet_accel_time: float = 1.0
const sc3_amulet_player_cone: float = deg_to_rad(140)
const sc3_amulet_homing_frequency: int = 3
const sc3_viewfinder_time: float = 0.8
const sc3_viewfinder_rest_time: float = 1.0
const sc3_viewfinder_speed: float = 55.0
const sc3_viewfinder_distance: float = 45.0
const sc3_viewfinder_scale: float = 1.6
const sc3_cooldown_time: float = 1.6

var viewfinder_bullet: CameraViewfinder
@onready var ViewfinderTimer: Timer = $ViewfinderExistTimer
@onready var RestTimer: Timer = $RestTimer

var photo_shoot: bool = false
var cooldown: bool = false
var bullets_fired: int = 0

func start_attack() -> void:
	ViewfinderTimer.timeout.connect(func() -> void:
		restore_time()
		photo_shoot = false
		if is_instance_valid(viewfinder_bullet):
			viewfinder_bullet.take_picture()
		await _set_timer(0.3)
		if !begin_attack: return
		boss_nice_aura()
		_hatate_attack_anim()
		await _set_timer(0.6)
		if hatate_attack_anim_played: reset_boss_anim_from_attack()
		cooldown = true
		)
	RestTimer.timeout.connect(func() -> void:
		cooldown = false
		photo_shoot = true
		)
	show_photo_counter()
	super()

func middle_attack() -> void:
	boss.keep_sc_bg = true
	_start_sc_hatate_move()
	await _set_timer(0.5)
	leaf_gather_effect()
	play_sound(boss.short_charge_up)
	await _set_timer(1.2)
	begin_attack = true
	photo_shoot = true
	super()

func _physics_process(delta: float) -> void:
	if _boss_attack_interrupt(): return
	if ViewfinderTimer.is_stopped() and photo_shoot:
		ViewfinderTimer.start(sc3_viewfinder_time)
		var target_position = boss.global_position
		var target_angle = aim_at_player()
		var target_player = Thunder._current_player
		if target_player:
			target_position = target_player.global_position
		boss_play_attack_anim()
		var distance_from_player: Vector2 = Vector2(sc3_viewfinder_distance * cos(target_angle + PI), sc3_viewfinder_distance * sin(target_angle + PI))
		shoot_distant_viewfinder(target_position + distance_from_player, sc3_viewfinder_speed, sc3_viewfinder_scale, target_angle, target_angle + (PI / 2))
		slow_time()
		await _set_timer(sc3_viewfinder_time)
		shoot_scatter_amulets(BULLET_AMULET_PURPLE, sc3_amulet_init_speed, sc3_amulet_later_speed, sc3_amulet_count, sc3_amulet_accel_time)
	if RestTimer.is_stopped() and cooldown:
		RestTimer.start(sc3_cooldown_time + 1.2)
		bullets_fired = 0
		var upper_bound = Vector2(300, -50)
		var lower_bound = Vector2(-300, -200)
		var wander_style = Wander_Type.RANDOM
		move_boss_wander(wander_style, boss.boss_handler.global_position, upper_bound, lower_bound, randf_range(90.0, 160.0), sc3_cooldown_time)
		await _set_timer(sc3_cooldown_time)
		if _boss_attack_interrupt(): return
		bullet_screen_clear(false)
		leaf_gather_effect()
		play_sound(boss.short_charge_up)

func end_attack() -> void:
	super()
	Audio.play_sound(boss.bullet_shoot_1, boss)
	if is_instance_valid(viewfinder_bullet):
		viewfinder_bullet.delete_self()
	bullet_screen_clear()
	play_sound(boss.bullet_shoot_1)
	player_gain_score(spellcard_score_bonus)
	goto_next_spell()

func force_end_attack() -> void:
	if is_instance_valid(viewfinder_bullet):
		viewfinder_bullet.take_picture()
	super()

func end_attack_global() -> void:
	begin_attack = false
	photo_shoot = false
	cooldown = false
	ViewfinderTimer.stop()
	RestTimer.stop()
	super()

func _start_sc_hatate_move() -> void:
	var old_pos = boss.global_position
	if boss.boss_handler:
		old_pos = boss.boss_handler.global_position
	var new_x = 0.0
	var new_y = -100.0
	new_y = -120.0
	if player.global_position.x > boss.boss_handler.global_position.x: new_x = -160
	if player.global_position.x < boss.boss_handler.global_position.x: new_x = 160
	move_boss(old_pos + Vector2(new_x, new_y))

func shoot_scatter_amulets(bullet_type: PackedScene, init_veloc: float = 15.0, new_veloc: float = 100.0, bullet_tally: int = 8, accel_time: float = 0.5) -> void:
	if !is_instance_valid(viewfinder_bullet): return
	if !viewfinder_bullet.AmuletCrutch: return
	play_sound(boss.bullet_shoot_1)
	# Boring calculation shit.
	var viewfinder_rect: Rect2 = viewfinder_bullet.get_rect()
	var anchor_top_left = viewfinder_bullet.AmuletCrutch.position
	# Calculate amulet-specific shit, position comes later
	var length_ratio = viewfinder_rect.size.x / viewfinder_rect.size.y
	var amulet_y_count = int(sqrt(bullet_tally / length_ratio))
	var amulet_x_count = int(bullet_tally / amulet_y_count)
	var distance_x_amulet: float = viewfinder_rect.size.x / amulet_x_count
	var distance_y_amulet: float = viewfinder_rect.size.y / amulet_y_count
	for i in amulet_x_count:
		for j in amulet_y_count:
			viewfinder_bullet.AmuletCrutch.position.x = anchor_top_left.x + distance_x_amulet * i
			viewfinder_bullet.AmuletCrutch.position.y = anchor_top_left.y + distance_y_amulet * j
			var used_speed_later: float = new_veloc
			var player_angle: float = 0.0
			var player_homing = Thunder._current_player
			if player_homing: player_angle = viewfinder_bullet.AmuletCrutch.global_position.angle_to_point(player_homing.global_position)
			var rand_angle_offset = randf_range((sc3_amulet_player_cone / 2), (PI*2) - (sc3_amulet_player_cone / 2))
			var rand_angle = player_angle + rand_angle_offset
			if bullets_fired % sc3_amulet_homing_frequency == 0:
				rand_angle = player_angle
				used_speed_later *= 4.0
			shoot_accel_bullet(BULLET_AMULET_PURPLE, viewfinder_bullet.AmuletCrutch.global_position, init_veloc, used_speed_later, rand_angle, rand_angle, accel_time)
			bullets_fired += 1

func shoot_accel_bullet(bullet_type: PackedScene, init_position: Vector2, b_velocity: float = 100.0, new_velocity: float = 50.0, angle: float = 0.0, rotation: float = 0.0, accel_time: float = 1.0) -> void:
	if !check_if_within_playfield(init_position): return
	var bullet_shot = bullet_type.instantiate()
	bullet_shot.rotation = rotation
	bullet_shot.veloc = Vector2(b_velocity * cos(angle), b_velocity * sin(angle))
	Scenes.current_scene.add_child(bullet_shot)
	boss.bullet_pool.append(bullet_shot)
	bullet_shot.z_index = boss.z_index + 2
	bullet_shot.global_position = init_position
	bullet_shot.reset_physics_interpolation()
	bullet_shot.enable_movement()
	bullet_shot.tween_bullet_speed(new_velocity, accel_time)

func shoot_distant_viewfinder(target_position: Vector2, velocity: float, scale: float, angle: float, rotation: float) -> void:
	play_sound(boss.camera_zoom)
	viewfinder_bullet = HATATE_VIEWFINDER.instantiate()
	viewfinder_bullet.w9_boss = boss
	viewfinder_bullet.use_destination_vector_instead = false
	viewfinder_bullet.velocity = Vector2(velocity * cos(angle), velocity * sin(angle))
	viewfinder_bullet.rotation = rotation
	viewfinder_bullet.life_time = sc3_viewfinder_time
	viewfinder_bullet.scale = Vector2(scale, 0.0)
	viewfinder_bullet.camera_rotate_offset = 0.0
	viewfinder_bullet.camera_flash = true
	viewfinder_bullet.camera_flash_growth = 0.005
	Scenes.current_scene.add_child(viewfinder_bullet)
	boss.bullet_pool.append(viewfinder_bullet)
	viewfinder_bullet.z_index = boss.z_index + 8
	viewfinder_bullet.global_position = target_position
	viewfinder_bullet.reset_physics_interpolation()
	viewfinder_bullet.appear_anim(true, scale)
	viewfinder_bullet.start_moving = true
