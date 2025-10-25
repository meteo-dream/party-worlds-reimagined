extends BossSpellcardFinal

const BUBBLE_PURPLE_SPAWNER = preload("res://objects/boss_touhou/boss_final/remilia/bullets/bullet_big_bubble_purple.tscn")
const KNIFE_BLUE_SPAWNER = preload("res://objects/boss_touhou/boss_final/remilia/bullets/bullet_spawner_knife_blue.tscn")

@export_category("Shoot Properties")
@export var use_bigger_bullet: bool = false
@export var bullet_amount: int = 7
@export var bullet_speed: float = 250.0
@export var bullet_spread_cone: float = 350.0
@export var bullet_shoot_interval_sec: float = 1.0
@onready var remi_interval_timer: Timer = $RemiInterval
var start_angle: float = (bullet_spread_cone / 2.0) * -1.0
var should_increase_next: bool = false

func middle_attack() -> void:
	var anchor = boss.boss_handler.global_position
	var new_destination: Vector2 = Vector2(anchor.x - 200.0, anchor.y - 90.0)
	var the_player = Thunder._current_player
	if is_instance_valid(the_player):
		if the_player.global_position.x <= anchor.x:
			new_destination.x = anchor.x + 200.0
	if boss.global_position != new_destination:
		move_boss(new_destination, 0.5)
	if use_bigger_bullet:
		bullet_screen_clear(false)
	begin_attack = true
	super()

func _physics_process(delta: float) -> void:
	if !begin_attack: return
	if remi_interval_timer.time_left <= 0:
		remi_interval_timer.start(bullet_shoot_interval_sec + 1.2)
		leaf_gather_effect()
		play_sound(boss.short_charge_up)
		await _set_timer(1.2)
		var bullet_to_spawn = KNIFE_BLUE_SPAWNER
		if use_bigger_bullet: bullet_to_spawn = BUBBLE_PURPLE_SPAWNER
		if !begin_attack: return
		play_sound(boss.bullet_twinkle, boss, true)
		var shot_count: int = bullet_amount
		if should_increase_next: shot_count += 1
		var bullet_spread_distance: float = bullet_spread_cone / shot_count
		for i in shot_count:
			var used_angle: float = aim_at_player() + deg_to_rad(start_angle + (bullet_spread_distance * i))
			spawn_bullet(bullet_to_spawn, bullet_speed, used_angle)
		boss_nice_aura()
		should_increase_next = !should_increase_next

func end_attack() -> void:
	if use_bigger_bullet:
		Audio.play_sound(boss.bullet_shoot_1, boss.boss_handler)
	super()

func end_attack_global() -> void:
	begin_attack = false
	remi_interval_timer.stop()
	should_increase_next = false
	super()

func move_boss_wander_predefined(wander_type = Wander_Type.RANDOM) -> void:
	var upper_bound = Vector2(300, -50)
	var lower_bound = Vector2(-300, -200)
	move_boss_wander(wander_type, boss.boss_handler.global_position, upper_bound, lower_bound, randf_range(90.0, 230.0), 1.2)

func spawn_bullet(bullet_type: PackedScene, speed: float = 2.0, angle: float = 0.0) -> void:
	shoot_spawner_bullet(bullet_type, boss.global_position, Vector2(speed * cos(angle), speed * sin(angle)), angle)

func shoot_spawner_bullet(bullet_type: PackedScene, init_position: Vector2 = Vector2.ZERO, b_velocity: Vector2 = Vector2(50.0, 50.0), rotation: float = 0.0) -> void:
	if !check_if_within_playfield(init_position): return
	var bullet_shot = bullet_type.instantiate()
	bullet_shot.rotation = rotation
	bullet_shot.veloc = b_velocity
	bullet_shot.boss = boss
	Scenes.current_scene.add_child(bullet_shot)
	boss.bullet_pool.append(bullet_shot)
	bullet_shot.appear_animation()
	bullet_shot.z_index = boss.z_index + 1
	bullet_shot.global_position = init_position
	bullet_shot.reset_physics_interpolation()
	bullet_shot.enable_movement()
