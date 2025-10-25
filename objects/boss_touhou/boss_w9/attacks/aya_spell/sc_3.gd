extends BossSpellcardW9

const BULLET_ARROW_RED = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/bullet_arrow_red.tscn")
const AYA_VIEWFINDER = preload("res://objects/boss_touhou/boss_w9/attacks/bullets/camera_viewfinder/aya_camera.tscn")
const sc3_arrow_speed_max: float = 800.0
const sc3_arrow_speed_min: float = 80.0
const sc3_arrow_dist: float = 20.0
const sc3_arrow_number_per_burst: int = 420
const sc3_arrow_range: float = deg_to_rad(40)
const sc3_boss_leap_time: float = 0.5
const sc3_viewfinder_distance_from_boss: float = 90.0
const sc3_viewfinder_scale: float = 1.85
const sc3_rest_time: float = 1.9

var viewfinder_bullet: CameraViewfinder
@onready var ViewfinderTimer: Timer = $ViewfinderExistTimer
@onready var RestTimer: Timer = $RestTimer

var photos_attempted: int = 0
var sc3_actual_leap_time: float
var leapt: bool = false
var going_up: bool = false
var change_to_vertical: bool = false

func start_attack() -> void:
	show_photo_counter()
	super()

func middle_attack() -> void:
	play_sound(boss.switch_to_sideways_viewfinder)
	move_boss(Vector2(boss.boss_handler.global_position.x, boss.boss_handler.global_position.y), sc3_boss_leap_time)
	await _set_timer(sc3_boss_leap_time)
	boss.keep_sc_bg = true
	leaf_gather_effect()
	play_sound(boss.short_charge_up)
	await _set_timer(1.2)
	boss_nice_aura()
	update_leap_time()
	sc3_actual_leap_time = sc3_boss_leap_time + 0.7
	var jump_pos_x = boss.boss_handler.global_position.x + 290.0
	if player:
		if boss.global_position.x < player.global_position.x:
			jump_pos_x = boss.boss_handler.global_position.x - 290.0
	move_boss(Vector2(jump_pos_x, boss.boss_handler.global_position.y + 80.0), sc3_actual_leap_time)
	await _set_timer(sc3_actual_leap_time)
	begin_attack = true
	super()

func _physics_process(delta: float) -> void:
	if _boss_attack_interrupt(): return
	if !leapt:
		leapt = true
		var player_angle = aim_at_player()
		var camera_alignment = 1
		if change_to_vertical: camera_alignment = 0
		shoot_instant_viewfinder(sc3_viewfinder_scale, player_angle, player_angle, ((PI / 2) * camera_alignment))
		photos_attempted += 1
		await _set_timer(0.4)
		if !change_to_vertical and photos_attempted >= 10:
			change_to_vertical = true
			play_sound(boss.switch_to_vertical_viewfinder)
		# Shoot at player
		#var shoot_range_min = aim_at_player() - (sc3_arrow_range / 2)
		#var shoot_range_max = aim_at_player() + (sc3_arrow_range / 2)
		# Shoot away from player
		var shoot_range_min = aim_at_player() + (sc3_arrow_range / 2)
		var shoot_range_max = aim_at_player() + ((PI*2) - (sc3_arrow_range / 2))
		shoot_wave(BULLET_ARROW_RED, sc3_arrow_dist, sc3_arrow_number_per_burst, shoot_range_min, shoot_range_max)
		await _set_timer(0.4)
		var origin_point = Vector2(boss.boss_handler.global_position.x, boss.global_position.y)
		# Jump time
		update_leap_time()
		if sc3_actual_leap_time < sc3_boss_leap_time: sc3_actual_leap_time = sc3_boss_leap_time
		screen_border_jump(origin_point, 180, 420, sc3_actual_leap_time)
		await _set_timer(sc3_actual_leap_time)
		leapt = false

func end_attack() -> void:
	boss.defeated_boss_wander = true
	super()
	Audio.play_sound(boss.bullet_shoot_1, boss)
	if is_instance_valid(viewfinder_bullet):
		viewfinder_bullet.delete_self()
	bullet_screen_clear()
	play_sound(boss.bullet_shoot_1)
	player_gain_score(spellcard_score_bonus)
	goto_next_spell()

func force_end_attack() -> void:
	boss.keep_sc_bg = false
	if is_instance_valid(viewfinder_bullet):
		viewfinder_bullet.take_picture()
	super()

func end_attack_global() -> void:
	begin_attack = false
	super()

func update_leap_time() -> void:
	sc3_actual_leap_time -= 0.3
	if sc3_actual_leap_time < sc3_boss_leap_time:
		sc3_actual_leap_time = sc3_boss_leap_time

func screen_border_jump(origin_point: Vector2, min_y: float, max_y: float, duration: float = 0.5) -> void:
	if _boss_attack_interrupt(): return
	boss_nice_aura()
	var random_height: float = randf_range(100.0, 110.0)
	if going_up: random_height = -(random_height)
	var new_y = origin_point.y + random_height
	if new_y > max_y:
		new_y = max_y
		going_up = true
	elif new_y < min_y:
		new_y = min_y
		going_up = false
	var new_x = origin_point.x + 280
	if boss.global_position.x > origin_point.x:
		new_x = origin_point.x - 280
	var destination: Vector2 = Vector2(new_x, new_y)
	move_boss(destination, duration)

func shoot_wave(bullet_type: PackedScene, distance: float, bullet_number: int, angle_range_min: float, angle_range_max: float) -> void:
	play_sound(boss.bullet_shoot_1)
	if _boss_attack_interrupt(): return
	for i in bullet_number:
		var final_angle = randf_range(angle_range_min, angle_range_max)
		shoot_at_distance(bullet_type, randf_range(sc3_arrow_speed_min, sc3_arrow_speed_max), distance, final_angle, final_angle)

func shoot_instant_viewfinder(scale: float, angle: float, rotation: float, rotation_offset: float) -> void:
	var distance_from_boss: Vector2 = Vector2(sc3_viewfinder_distance_from_boss * cos(angle), sc3_viewfinder_distance_from_boss * sin(angle))
	viewfinder_bullet = AYA_VIEWFINDER.instantiate()
	viewfinder_bullet.instant_flash = true
	viewfinder_bullet.camera_flash = true
	viewfinder_bullet.global_rotation = rotation + rotation_offset
	viewfinder_bullet.scale = Vector2(scale, scale)
	viewfinder_bullet.start_moving = false
	viewfinder_bullet.life_time = 0.02
	Scenes.current_scene.add_child(viewfinder_bullet)
	boss.bullet_pool.append(viewfinder_bullet)
	viewfinder_bullet.w9_boss = boss
	viewfinder_bullet.viewfinder_sprite.frame = 1
	viewfinder_bullet.viewfinder_sprite.self_modulate.a = 1.0
	viewfinder_bullet.global_position = boss.global_position + distance_from_boss
	viewfinder_bullet.reset_physics_interpolation()
	viewfinder_bullet.appear_anim()
