extends BossSpellcardFinal

const SHOOT_BEHIND_OPTION = preload("res://objects/boss_touhou/boss_final/kevin_marisa/minion/circle_shoot_behind.tscn")
const STAR_BIG = preload("res://objects/boss_touhou/boss_final/kevin_marisa/bullets/bullet_marisa_star_big.tscn")
const DASH_WARNING = preload("res://objects/boss_touhou/boss_final/kevin_marisa/spark_warning.tscn")

const offset_from_center_x: float = 480.0

var height_list: Array[float] = [((416.0 / 3) / 2), ((416.0 / 3) / 2) + (416.0 / 3), ((416.0 / 3) / 2) + ((416.0 / 3) * 2)]
@export var marisa_dormant_duration_sec: float = 2.5
@export var marisa_dash_time_sec: float = 0.9
@export_group("Magic Circle Properties", "magic_circle_")
@export var magic_circle_count: int = 7
@export var magic_circle_radius: float = 85.0
@export var magic_circle_radius_growth_time_sec: float = 0.5
@export var magic_circle_orbit_speed: float = 700.0
@export var magic_circle_spawn_range: float = 360.0
@export var magic_circle_orbit_acceleration_time_sec: float = 0.4
@export_group("Magic Circle Shooting", "shooting_")
@export var shooting_bullet_type: PackedScene = STAR_BIG
@export var shooting_speed: float = 700.0
@export var shooting_interval_sec: float = 0.1
var orbit_divide_unit: float = magic_circle_spawn_range / magic_circle_count
@onready var rest_timer: Timer = $Timer

var current_shoot_angle: float
var magic_circle_array: Array
var half_a_lane: float = (416.0 / 3) / 2
var dash_warning_line: Node2D

var hitbox_off_by_default: bool = false

func _ready() -> void:
	rest_timer.timeout.connect(func() -> void:
		pass
	)

func middle_attack() -> void:
	if boss.disable_hurtbox:
		hitbox_off_by_default = true
	boss.disable_hurtbox = false
	
	summon_magic_circles()
	super()
	await _set_timer(0.2)
	var player_lane: int = do_player_lane_search()
	var boss_new_pos: Vector2 = get_setup_position(player_lane)
	move_boss(boss_new_pos, 2.1)
	await _set_timer(1.9)
	begin_attack = true

func _physics_process(delta: float) -> void:
	if _boss_attack_interrupt(): return
	if rest_timer.time_left <= 0.0:
		rest_timer.start(marisa_dormant_duration_sec + 1.2)
		play_sound(boss.short_charge_up)
		var player_lane: int = do_player_lane_search()
		var warning_angle: float = get_warning_line_angle()
		spawn_warning_line(player_lane, warning_angle)
		await _set_timer(1.2)
		delete_warning_line()
		marisa_dash_move(player_lane)

func end_attack_global() -> void:
	begin_attack = false
	magic_circle_clear()
	magic_circle_stop_shooting()
	rest_timer.stop()
	delete_warning_line()
	if hitbox_off_by_default: boss.disable_hurtbox = true
	super()

func do_player_lane_search() -> int:
	var the_player = Thunder._current_player
	if !is_instance_valid(the_player): return 1
	if the_player.global_position.y < height_list[0] + half_a_lane: return 0
	if the_player.global_position.y > height_list[2] - half_a_lane: return 2
	return 1

func get_warning_line_angle() -> float:
	var anchor: Vector2 = boss.boss_handler.global_position
	if boss.global_position.x > anchor.x:
		return PI
	return 0.0

func get_setup_position(which_lane: int) -> Vector2:
	var chosen_lane: int = clampi(which_lane, 0, height_list.size() - 1)
	var anchor: Vector2 = boss.boss_handler.global_position
	var setup_position: Vector2 = anchor
	if boss.global_position.x <= anchor.x:
		setup_position.x = anchor.x - offset_from_center_x
	else:
		setup_position.x = anchor.x + offset_from_center_x
	setup_position.y = anchor.y - 240.0 + height_list[chosen_lane]
	return setup_position

func marisa_dash_move(which_lane: int) -> void:
	if _boss_attack_interrupt(): return
	var chosen_lane: int = clampi(which_lane, 0, height_list.size() - 1)
	var anchor: Vector2 = boss.boss_handler.global_position
	var setup_position: Vector2 = get_setup_position(chosen_lane)
	boss.global_position = setup_position
	var destination: Vector2 = setup_position
	if setup_position.x <= anchor.x:
		destination.x = anchor.x + offset_from_center_x
		current_shoot_angle = PI
	else:
		destination.x = anchor.x - offset_from_center_x
		current_shoot_angle = 0
	move_boss(destination, marisa_dash_time_sec, Tween.TransitionType.TRANS_LINEAR)
	magic_circle_shoot(current_shoot_angle)
	await _set_timer(marisa_dash_time_sec)
	magic_circle_stop_shooting()

func summon_magic_circles() -> void:
	#if _boss_attack_interrupt(): return
	play_sound(boss.summon_minion)
	for i in magic_circle_count:
		var circle_property_array: Array = [orbit_divide_unit * i, magic_circle_radius, magic_circle_radius_growth_time_sec, magic_circle_orbit_speed, magic_circle_orbit_acceleration_time_sec]
		var bullet_property_array: Array = [shooting_bullet_type, i, randf_range(shooting_speed * 0.85, shooting_speed * 2.0), randf_range(shooting_interval_sec * 0.5, shooting_interval_sec * 0.7)]
		spawn_minion(circle_property_array, bullet_property_array)

func spawn_minion(circle_properties: Array, bullet_properties: Array) -> void:
	var magic_circle = SHOOT_BEHIND_OPTION.instantiate()
	magic_circle.orbit_angle_offset = circle_properties[0]
	magic_circle.final_orbit_amplitude = circle_properties[1]
	magic_circle.orbit_amplitude_time_sec = circle_properties[2]
	magic_circle.final_orbit_speed = circle_properties[3]
	magic_circle.orbit_acceleration_time_sec = circle_properties[4]
	magic_circle.shoot_bullet_type = bullet_properties[0]
	magic_circle.shoot_bullet_color = bullet_properties[1]
	magic_circle.shoot_bullet_speed = bullet_properties[2]
	magic_circle.shoot_interval_sec = bullet_properties[3]
	if is_instance_valid(boss):
		magic_circle.anchor_node = boss
		magic_circle.node_for_playing_shoot_sound = boss.boss_handler
	Scenes.current_scene.add_child(magic_circle)
	magic_circle_array.append(magic_circle)
	magic_circle.global_position = boss.global_position
	magic_circle.reset_physics_interpolation()

func magic_circle_shoot(angle: float) -> void:
	if magic_circle_array.size() > 0:
		for i in magic_circle_array.size():
			if is_instance_valid(magic_circle_array[i]):
				magic_circle_array[i].forced_shoot_angle = angle
				magic_circle_array[i].turn_on_shooting()

func magic_circle_stop_shooting() -> void:
	if magic_circle_array.size() > 0:
		for i in magic_circle_array.size():
			if is_instance_valid(magic_circle_array[i]):
				magic_circle_array[i].turn_off_shooting()

func magic_circle_clear() -> void:
	if magic_circle_array.size() > 0:
		for i in magic_circle_array.size():
			if is_instance_valid(magic_circle_array[i]):
				magic_circle_array[i].delete_self()

func bullet_screen_clear(score: bool = true) -> void:
	magic_circle_clear()
	super(score)

func spawn_warning_line(lane: int, angle: float) -> void:
	if is_instance_valid(dash_warning_line): return
	var self_position: Vector2 = Vector2(boss.global_position.x, boss.boss_handler.global_position.y - 240.0 + height_list[clampi(lane, 0, height_list.size() - 1)])
	dash_warning_line = DASH_WARNING.instantiate()
	dash_warning_line.desired_x_scale = 38.0
	dash_warning_line.target_position = self_position + Vector2(100.0 * cos(angle), 100.0 * sin(angle))
	dash_warning_line.scale.y = 0.3
	Scenes.current_scene.add_child(dash_warning_line)
	dash_warning_line.global_position = self_position
	dash_warning_line.reset_physics_interpolation()
	play_sound(boss.prepare_master_spark, dash_warning_line)

func delete_warning_line() -> void:
	if is_instance_valid(dash_warning_line):
		dash_warning_line.delete_self()
