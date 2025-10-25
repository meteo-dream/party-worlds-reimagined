extends BossSpellcardFinal

const DROPLET_RED = preload("res://objects/boss_touhou/boss_final/remilia/bullets/bullet_drop_red.tscn")
const FIRE_RED = preload("res://objects/boss_touhou/boss_final/remilia/bullets/bullet_fireball_red.tscn")

@export var clear_screen_on_activate: bool = false
@export var droplet_interval: float = 0.15
@export var droplet_speed: float = 300.0
@export var remilia_start_shooting: bool = false
@export var remilia_shoot_interval: float = 2.0
@export var remilia_shoot_amount: int = 5
@export var remilia_shoot_speed: float = 250.0
@export var remilia_shoot_cone: float = 85.5
@onready var rain_interval_timer: Timer = $RainTimer
@onready var remi_interval_timer: Timer = $RemiInterval
var cone_angle_increment: float = deg_to_rad(remilia_shoot_cone) / 3
var rain_enabled: bool = false
var remi_shoot: bool = false

func _ready() -> void:
	rain_interval_timer.timeout.connect(func() -> void:
		if !boss.force_end_player_death:
			rain_enabled = true)
	remi_interval_timer.timeout.connect(func() -> void:
		if !boss.force_end_player_death and remilia_start_shooting:
			leaf_gather_effect()
			play_sound(boss.short_charge_up)
			await _set_timer(1.2)
			remi_shoot = true
			return
		await _set_timer(1.2)
		remi_shoot = true)

func middle_attack() -> void:
	begin_attack = true
	rain_enabled = true
	super()
	if clear_screen_on_activate:
		bullet_screen_clear(false)
	if remilia_start_shooting:
		leaf_gather_effect()
		play_sound(boss.short_charge_up)
		await _set_timer(1.2)
		remi_shoot = true
	else: remi_shoot = true

func _physics_process(delta: float) -> void:
	if !begin_attack: return
	var anchor_point = boss.boss_handler.global_position
	if rain_enabled:
		rain_interval_timer.start(droplet_interval)
		rain_enabled = false
		if !remilia_start_shooting:
			for i in 2:
				spawn_droplet_random(DROPLET_RED, anchor_point, randf_range(40.0, droplet_speed))
		else:
			var new_angle: float = deg_to_rad(90) + (randi_range(-1, 1) * randf_range(deg_to_rad(30), deg_to_rad(80)))
			spawn_droplet_random(DROPLET_RED, anchor_point, randf_range(40.0, droplet_speed), new_angle, true)
	if remi_shoot:
		remi_interval_timer.start(remilia_shoot_interval)
		remi_shoot = false
		move_boss_wander(Wander_Type.RANDOM, anchor_point, Vector2(200, -80), Vector2(-200, 100), randf_range(50.0, 100.0), remilia_shoot_interval / 2.0)
		if remilia_start_shooting:
			var player_angle: float = aim_at_player()
			play_sound(boss.bullet_shoot_1, boss)
			for k in 2:
				player_angle += deg_to_rad(180) * k
				for j in 3:
					var used_angle = player_angle + (cone_angle_increment * (-1 + j))
					for i in clamp(remilia_shoot_amount, 0, 50):
						spawn_knife(FIRE_RED, remilia_shoot_speed * (1.0 - (0.15 * i)), used_angle)

func end_attack() -> void:
	if remilia_start_shooting:
		Audio.play_sound(boss.bullet_shoot_1, boss.boss_handler)
	super()

func end_attack_global() -> void:
	begin_attack = false
	rain_interval_timer.stop()
	rain_enabled = false
	remi_interval_timer.stop()
	remilia_start_shooting = false
	remi_shoot = false
	super()

func spawn_knife(bullet_type: PackedScene, speed: float = 2.0, angle: float = 0.0) -> void:
	var calc_velocity: Vector2 = Vector2(speed * cos(angle), speed * sin(angle))
	#play_sound(boss.bullet_shoot_1, boss, true)
	shoot_simple_bullet(bullet_type, boss.global_position, calc_velocity, angle)

func spawn_droplet_random(bullet_type: PackedScene, anchor: Vector2, speed: float = 2.0, angle: float = deg_to_rad(90), homing: bool = false) -> void:
	var calc_velocity: Vector2 = Vector2(speed * cos(angle), speed * sin(angle))
	var start_pos: Vector2 = Vector2(anchor.x + randf_range(-310.0, 310.0), 0.0)
	if homing and is_instance_valid(Thunder._current_player):
		start_pos = Vector2(Thunder._current_player.global_position.x + randf_range(-100.0, 100.0), 0.0)
	#play_sound(boss.bullet_shoot_dimmed_sfx, boss, true)
	shoot_simple_bullet(bullet_type, start_pos, calc_velocity, angle)
