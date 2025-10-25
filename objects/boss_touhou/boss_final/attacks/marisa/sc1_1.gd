extends BossSpellcardFinal

const LASER_MAGIC_CIRCLE = preload("res://objects/boss_touhou/boss_final/kevin_marisa/minion/laser_circle_minion.tscn")
const BULLET_LASER = preload("res://objects/boss_touhou/boss_final/kevin_marisa/bullets/bullet_marisa_laser_thin.tscn")

@export var play_spell_end_sound: bool = true
@export_group("Laser Spawner Properties", "spawner_")
@export var spawner_count: int = 13
@export var spawner_move_time_sec: float = 0.5
@export var spawner_shoot_delay_sec: float = 0.3
@export var spawner_interval_sec: float = 0.01
@export var spawner_boss_shoot_interval_sec: float = 1.0
@export_group("Laser Properties", "laser_")
@export_enum("Violet: 0", "Red: 1", "Gold: 2", "Lime Yellow: 3", "Green: 4", "Blue: 5", "Cyan: 6") var laser_color: int = 5
@export_enum("Violet: 0", "Red: 1", "Gold: 2", "Lime Yellow: 3", "Green: 4", "Blue: 5", "Cyan: 6") var laser_alt_color: int = 1
@export var laser_life_time_sec: float = 0.7
@export var laser_desired_scale: float = 1.3
@export var laser_wait_time: float = 1.0
@export var laser_resize_time: float = 0.5
@export var laser_life_time: float = 1.0
@export var laser_disappear_time: float = 0.5
@export var laser_angular_variation: float = 8.0

var actual_spawner_count: int
var allow_spawn_circles: bool = false
var spawned_count: int
var do_alt_color: bool = false

@onready var shoot_interval_timer: Timer = $SpawnInterval
@onready var boss_interval_timer: Timer = $BossInterval

func _ready() -> void:
	actual_spawner_count = spawner_count - 1
	boss_interval_timer.timeout.connect(func() -> void:
		actual_spawner_count = actual_spawner_count
		spawned_count = 0
		do_alt_color = !do_alt_color
		allow_spawn_circles = true
		play_sound(boss.summon_minion, boss)
	)

func middle_attack() -> void:
	bullet_screen_clear(false)
	begin_attack = true
	allow_spawn_circles = true
	play_sound(boss.summon_minion, boss)
	super()

func _physics_process(delta: float) -> void:
	if _boss_attack_interrupt(): return
	if allow_spawn_circles and shoot_interval_timer.time_left <= 0.0:
		if spawned_count > actual_spawner_count:
			if boss_interval_timer.time_left <= 0.0:
				var final_time: float = spawner_boss_shoot_interval_sec + (spawner_interval_sec * actual_spawner_count)
				boss_interval_timer.start(final_time)
				move_boss_chase_player()
			allow_spawn_circles = false
			return
		shoot_interval_timer.start(spawner_interval_sec)
		summon_magic_circle(spawned_count, actual_spawner_count)
		spawned_count += 1

func end_attack() -> void:
	if play_spell_end_sound: Audio.play_sound(boss.bullet_shoot_1, boss.boss_handler)
	super()

func end_attack_global() -> void:
	begin_attack = false
	shoot_interval_timer.stop()
	boss_interval_timer.stop()
	allow_spawn_circles = false
	spawned_count = 0
	super()

func move_boss_chase_player() -> void:
	if _boss_attack_interrupt(): return
	#boss_nice_aura()
	var upper_bound = Vector2(300, -100)
	var lower_bound = Vector2(-300, -200)
	move_boss_wander(Wander_Type.MOVE_X_TOWARDS_PLAYER, boss.boss_handler.global_position, upper_bound, lower_bound, randf_range(90.0, 300.0), 1.2)

func summon_magic_circle(iteration_count: int = 0, total: int = spawner_count) -> void:
	if _boss_attack_interrupt(): return
	var start_pos: Vector2 = Vector2(boss.boss_handler.global_position.x, boss.boss_handler.global_position.y + 178.0)
	var the_player = Thunder._current_player
	if is_instance_valid(the_player): start_pos.x = the_player.global_position.x
	start_pos += Vector2(-640.0, 0.0)
	var diff_distance: float = 1280.0 / total
	var final_pos: Vector2 = start_pos + Vector2(diff_distance * iteration_count, 0.0)
	var circle_properties: Array = [final_pos, spawner_move_time_sec]
	var laser_properties: Array = [laser_life_time_sec, laser_desired_scale, laser_wait_time, laser_resize_time, laser_life_time, laser_disappear_time]
	var used_laser_color: int = laser_color
	if do_alt_color:
		used_laser_color = laser_alt_color
	var used_angle: float = deg_to_rad(0)
	if deg_to_rad(laser_angular_variation) > 0.0:
		used_angle = randf_range(-(deg_to_rad(laser_angular_variation) / 2), (deg_to_rad(laser_angular_variation) / 2))
	var shoot_properties: Array = [BULLET_LASER, used_laser_color, used_angle, spawner_shoot_delay_sec]
	spawn_minion(circle_properties, laser_properties, shoot_properties)

func spawn_minion(circle_properties: Array, laser_properties: Array, shoot_properties: Array) -> void:
	var magic_circle = LASER_MAGIC_CIRCLE.instantiate()
	magic_circle.move_destination = circle_properties[0]
	magic_circle.move_time_sec = circle_properties[1]
	magic_circle.shoot_laser_life_time_sec = laser_properties[0]
	magic_circle.shoot_use_laser_blast_instead = false
	magic_circle.shoot_use_as_warning = false
	magic_circle.shoot_desired_scale = laser_properties[1]
	magic_circle.shoot_wait_time = laser_properties[2]
	magic_circle.shoot_resize_time = laser_properties[3]
	magic_circle.shoot_life_time = laser_properties[4]
	magic_circle.shoot_disappear_time = laser_properties[5]
	magic_circle.shoot_bullet_type = shoot_properties[0]
	magic_circle.shoot_bullet_color = shoot_properties[1]
	magic_circle.shoot_bullet_speed = 0.0
	magic_circle.shoot_angle = shoot_properties[2]
	magic_circle.shoot_delay_time_sec = shoot_properties[3]
	magic_circle.bullet_delete_pool = boss
	if is_instance_valid(boss):
		magic_circle.node_for_playing_shoot_sound = boss.boss_handler
	Scenes.current_scene.add_child(magic_circle)
	boss.bullet_pool.append(magic_circle)
	magic_circle.global_position = boss.global_position
	magic_circle.reset_physics_interpolation()
