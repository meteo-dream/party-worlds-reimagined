extends BossSpellcardFinal

const KNIFE_RED = preload("res://objects/boss_touhou/boss_final/remilia/bullets/bullet_knife_red.tscn")
const KNIFE_BLUE = preload("res://objects/boss_touhou/boss_final/remilia/bullets/bullet_knife_blue.tscn")
@export var sc7_no_wandering: bool = false
@export var alternate_fire: bool = false
@export var sc0_knife_amount: int = 12
@export var sc0_knife_interval: float = 0.001
@export var sc0_knife_speed: float = 2500.0
var sc0_knife_circle_gap: float = deg_to_rad(360.0 / sc0_knife_amount)
var sc0_shoot_knife: bool = false
var sc0_aim_angle: float
var sc0_knives_shot: int = 0
var sc0_actual_interval: float
var sc0_actual_speed: float
@onready var interval_timer: Timer = $KnifeInterval

func _ready() -> void:
	interval_timer.timeout.connect(func() -> void:
		sc0_shoot_knife = true
		)

func middle_attack() -> void:
	restart_pattern()
	super()

func restart_pattern() -> void:
	sc0_aim_angle = aim_at_player()
	sc0_actual_interval = 0.12
	sc0_actual_speed = 170.0
	var tw = get_tree().create_tween()
	tw.tween_property(self, "sc0_actual_interval", sc0_knife_interval, 7.0)
	tw.parallel().tween_property(self, "sc0_actual_speed", sc0_knife_speed, 10.0)
	if !sc7_no_wandering:
		move_boss_wander(Wander_Type.MOVE_X_TOWARDS_PLAYER, boss.boss_handler.global_position, Vector2(200, -140), Vector2(-200, 30), randf_range(0.0, 100.0), 0.1)
		boss_nice_aura()
	begin_attack = true
	sc0_shoot_knife = true

func _physics_process(delta: float) -> void:
	if !begin_attack: return
	if sc0_knives_shot > sc0_knife_amount:
		sc0_knives_shot = 0
		sc0_aim_angle -= deg_to_rad(360)
	if sc0_shoot_knife:
		interval_timer.start(sc0_actual_interval)
		sc0_shoot_knife = false
		sc0_knives_shot += 1
		# The actual shooting part
		#play_sound(boss.bullet_shoot_1, boss, true)
		for i in 8:
			var speed = sc0_actual_speed
			var angle = sc0_aim_angle - (deg_to_rad(45) * i)
			var bullet_type = KNIFE_RED
			if alternate_fire: bullet_type = KNIFE_BLUE
			for k in 2:
				spawn_knife(bullet_type, speed * (1.0 - (0.2 * k)), angle)
		sc0_aim_angle += sc0_knife_circle_gap
		if alternate_fire: sc0_aim_angle -= sc0_knife_circle_gap * 2

func end_attack_global() -> void:
	begin_attack = false
	sc0_shoot_knife = false
	super()

func spawn_knife(bullet_type: PackedScene, speed: float = 2.0, angle: float = 0.0) -> void:
	var calc_velocity: Vector2 = Vector2(speed * cos(angle), speed * sin(angle))
	shoot_simple_bullet(bullet_type, boss.global_position, calc_velocity, angle)
