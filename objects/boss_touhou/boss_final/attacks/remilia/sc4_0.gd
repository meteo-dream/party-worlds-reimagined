extends BossSpellcardFinal

const FIRE_RED = preload("res://objects/boss_touhou/boss_final/remilia/bullets/bullet_fireball_red.tscn")

@export_group("Nonspell Properties", "sc4_")
@export var sc4_bullet_count: int = 27
@export var sc4_bullet_initial_speed: float = 230.0
@export var sc4_bullet_final_speed: float = 300.0
@export var sc4_deceleration_time_sec: float = 1.0
@export var sc4_bullet_delay_speed: float = 1.0
@export var sc4_interval_sec: float = 6.0
var start_shooting_fire: bool = false
@onready var boss_rest_timer: Timer = $RestTimer

func _ready() -> void:
	boss_rest_timer.timeout.connect(func() -> void:
		if _boss_attack_interrupt(): return
		start_shooting_fire = true
		)

func middle_attack() -> void:
	begin_attack = true
	start_shooting_fire = true
	super()

func _physics_process(delta: float) -> void:
	if _boss_attack_interrupt(): return
	if start_shooting_fire:
		if boss_rest_timer.time_left <= 0.0:
			boss_rest_timer.start(sc4_interval_sec)
			start_shooting_fire = false
		shoot_ring_fire(sc4_bullet_count * 0.7)
		await _set_timer(sc4_interval_sec / 4)
		shoot_ring_fire(sc4_bullet_count * 0.85)
		await _set_timer(sc4_interval_sec / 4)
		shoot_ring_fire(sc4_bullet_count)
		await _set_timer(sc4_interval_sec / 6)
		if _boss_attack_interrupt(): return
		move_boss_chase_narrow(boss.global_position, true)

func end_attack_global() -> void:
	begin_attack = false
	boss_rest_timer.stop()
	start_shooting_fire = false
	super()

func shoot_ring_fire(count: int) -> void:
	if _boss_attack_interrupt(): return
	play_sound(boss.bullet_shoot_1, boss)
	shoot_ring_of_fire_individual(count)
	await _set_timer(sc4_bullet_delay_speed + sc4_deceleration_time_sec)
	if _boss_attack_interrupt(): return
	play_sound(boss.bullet_twinkle, boss)

func shoot_ring_of_fire_individual(count: int) -> void:
	var sc4_angle_distance: float = deg_to_rad(360.0 / count)
	for i in count:
		var used_angle: float = sc4_angle_distance * i
		shoot_accel_fire(used_angle, sc4_bullet_initial_speed, sc4_bullet_final_speed)

func shoot_accel_fire(angle: float, init_speed: float, final_speed: float) -> void:
	var init_velocity: Vector2 = Vector2(init_speed * cos(angle), init_speed * sin(angle))
	shoot_fire(boss.global_position, init_velocity, angle, final_speed, sc4_bullet_delay_speed, sc4_deceleration_time_sec)

func shoot_fire(init_pos: Vector2, init_veloc: Vector2, angle: float, final_veloc: float, delay: float, decel_time: float) -> void:
	if !check_if_within_playfield(init_pos): return
	var bullet_shot = FIRE_RED.instantiate()
	bullet_shot.rotation = angle
	bullet_shot.veloc = init_veloc
	bullet_shot.do_accelerate = true
	bullet_shot.final_accelerate_speed = final_veloc
	bullet_shot.decelerate_delay_sec = delay
	bullet_shot.decelerate_time_sec = decel_time
	Scenes.current_scene.add_child(bullet_shot)
	boss.bullet_pool.append(bullet_shot)
	bullet_shot.appear_animation()
	bullet_shot.z_index = boss.z_index + 1
	bullet_shot.global_position = init_pos
	bullet_shot.reset_physics_interpolation()
	bullet_shot.enable_movement()
