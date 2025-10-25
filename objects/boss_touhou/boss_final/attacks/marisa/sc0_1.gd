extends BossSpellcardFinal

const ORBITING_MAGIC_CIRCLE = preload("res://objects/boss_touhou/boss_final/kevin_marisa/minion/magic_circle_orbit_option.tscn")
const STAR_SMALL = preload("res://objects/boss_touhou/boss_final/kevin_marisa/bullets/bullet_marisa_star_small.tscn")

@export var clear_screen_on_active: bool = false
@export var final_phase: bool = false
@export var combo_attack: bool = false
@export_group("Magic Circle Properties", "magic_circle_")
@export var magic_circle_count: int = 7
@export var magic_circle_radius: float = 70.0
@export var magic_circle_radius_growth_time_sec: float = 1.3
@export var magic_circle_orbit_speed: float = 360.0
@export var magic_circle_spawn_range: float = 360.0
@export var magic_circle_orbit_acceleration_time_sec: float = 1.2
@export var magic_circle_escape_delay_sec: float = 0.0
@export_group("Magic Circle Shooting", "shooting_")
@export var shooting_bullet_type: PackedScene = STAR_SMALL
@export_enum("Violet: 0", "Red: 1", "Gold: 2", "Lime Yellow: 3", "Green: 4", "Blue: 5", "Cyan: 6") var shooting_bullet_color: int = 0
@export var shooting_speed: float = 170.0
@export var shooting_interval_sec: float = 0.2
@export var shooting_delay_time_sec: float = 2.0
var orbit_divide_unit: float = magic_circle_spawn_range / magic_circle_count
@onready var wander_interval_timer: Timer = $WanderInterval
var waves_shot: int
var allow_spawn_circles: bool = false

func _ready() -> void:
	wander_interval_timer.timeout.connect(func() -> void:
		allow_spawn_circles = true
		)

func middle_attack() -> void:
	begin_attack = true
	allow_spawn_circles = true
	if clear_screen_on_active:
		bullet_screen_clear(false)
	if final_phase:
		move_boss(boss.boss_handler.global_position + Vector2(0.0, -100.0), 0.7)
		summon_magic_circles()
		begin_attack = false
	super()

func _physics_process(delta: float) -> void:
	if !begin_attack or boss.force_end_player_death: return
	if allow_spawn_circles:
		if magic_circle_escape_delay_sec > 0.0:
			var new_time: float = (magic_circle_escape_delay_sec - shooting_delay_time_sec) * 1.5
			wander_interval_timer.start(new_time)
			allow_spawn_circles = false
			summon_magic_circles()
			waves_shot += 1
			await _set_timer(magic_circle_escape_delay_sec / 2)
			move_boss_chase_player()
		else:
			allow_spawn_circles = false
			summon_magic_circles()
			await _set_timer(1.5)
			move_boss_chase_player()

func force_end_attack() -> void:
	super()
	if final_phase:
		bullet_screen_clear(false)

func end_attack_global() -> void:
	begin_attack = false
	wander_interval_timer.stop()
	allow_spawn_circles = false
	waves_shot = 0
	super()

func move_boss_chase_player() -> void:
	if combo_attack:
		move_boss_chase_narrow(boss.global_position)
		return
	if _boss_attack_interrupt(): return
	#boss_nice_aura()
	var upper_bound = Vector2(300, -100)
	var lower_bound = Vector2(-300, -200)
	var anchor: Vector2 = boss.boss_handler.global_position
	move_boss_wander(Wander_Type.RANDOM, anchor, upper_bound, lower_bound, randf_range(90.0, 230.0), 1.2)

func summon_magic_circles() -> void:
	if _boss_attack_interrupt(): return
	play_sound(boss.summon_minion)
	for i in magic_circle_count:
		var circle_property_array: Array = [orbit_divide_unit * i, magic_circle_radius, magic_circle_radius_growth_time_sec, magic_circle_orbit_speed, magic_circle_orbit_acceleration_time_sec, magic_circle_escape_delay_sec]
		var bullet_property_array: Array = [shooting_bullet_type, i, shooting_speed, shooting_interval_sec, shooting_delay_time_sec]
		spawn_minion(circle_property_array, bullet_property_array)

func spawn_minion(circle_properties: Array, bullet_properties: Array) -> void:
	var magic_circle = ORBITING_MAGIC_CIRCLE.instantiate()
	magic_circle.orbit_angle_offset = circle_properties[0]
	magic_circle.final_orbit_amplitude = circle_properties[1]
	magic_circle.orbit_amplitude_time_sec = circle_properties[2]
	magic_circle.final_orbit_speed = circle_properties[3]
	if waves_shot % 2 == 1: magic_circle.final_orbit_speed *= -1.0
	magic_circle.orbit_acceleration_time_sec = circle_properties[4]
	magic_circle.time_before_orbit_escape_sec = circle_properties[5]
	magic_circle.shoot_bullet_type = bullet_properties[0]
	magic_circle.shoot_bullet_color = bullet_properties[1]
	magic_circle.shoot_bullet_speed = bullet_properties[2]
	magic_circle.shoot_interval_sec = bullet_properties[3]
	magic_circle.shoot_delay_time_sec = bullet_properties[4]
	if is_instance_valid(boss):
		magic_circle.anchor_node = boss
		magic_circle.node_for_playing_shoot_sound = boss.boss_handler
	Scenes.current_scene.add_child(magic_circle)
	boss.bullet_pool.append(magic_circle)
	magic_circle.global_position = boss.global_position
	magic_circle.reset_physics_interpolation()
