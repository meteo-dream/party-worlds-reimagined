extends "res://objects/boss_touhou/common/magic_circle_minion.gd"

@export var use_normal_movement: bool = false
@export var final_orbit_amplitude: float = 50.0
@export var orbit_amplitude_time_sec: float = 1.5
@export var final_orbit_speed: float = 10.5
@export var orbit_acceleration_time_sec: float = 1.5
@export var orbit_angle_offset: float = 0.0
@export var use_static_anchor: bool = false
@export var anchor_vector: Vector2
@export var anchor_node: Node2D
@export var time_before_orbit_escape_sec: float = 5.0
var actual_amplitude: float
var actual_orbit_speed: float
var actual_angle_offset: float
var current_angle: float
var release_from_orbit: bool = false
var disable_secondary_shot: bool = false
@onready var orbit_timer: Timer = $OrbitTimer

func _ready() -> void:
	super()
	orbit_timer.timeout.connect(do_orbit_escape)
	if is_instance_valid(anchor_node):
		bullet_delete_pool = anchor_node

func enable_movement() -> void:
	if use_normal_movement:
		super()
		return
	if time_before_orbit_escape_sec > 0.0 and is_instance_valid(orbit_timer):
		orbit_timer.start(time_before_orbit_escape_sec)
	var tw = get_tree().create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "actual_amplitude", final_orbit_amplitude, orbit_amplitude_time_sec)
	tw.tween_property(self, "actual_orbit_speed", final_orbit_speed, orbit_acceleration_time_sec)
	if orbit_angle_offset != 0.0:
		var tw_special = get_tree().create_tween()
		#tw_special.set_trans(Tween.TRANS_CIRC)
		tw_special.set_ease(Tween.EASE_IN)
		tw_special.tween_property(self, "actual_angle_offset", orbit_angle_offset, orbit_amplitude_time_sec)

func _movement_process(delta: float) -> void:
	if use_normal_movement:
		super(delta)
		return
	if release_from_orbit and has_left_the_screen:
		delete_self()
		return
	# Usual orbiting movement should consist of an anchor,
	# distance, angle, and angle velocity.
	var actual_anchor_vector: Vector2 = anchor_vector
	if !use_static_anchor and is_instance_valid(anchor_node):
		actual_anchor_vector = anchor_node.global_position
	current_angle += (deg_to_rad(actual_orbit_speed) * delta)
	var used_angle: float = current_angle + deg_to_rad(actual_angle_offset)
	var offset_vector: Vector2 = Vector2(actual_amplitude * cos(used_angle), actual_amplitude * sin(used_angle))
	global_position = actual_anchor_vector + offset_vector

func _bullet_firing_process(delta: float) -> void:
	if bullet_interval_timer.time_left <= 0:
		bullet_interval_timer.start(shoot_interval_sec)
		play_sound(shoot_sound_effect)
		for i in 1:
			var used_angle: float = _get_bullet_angle()
			var half_speed: float = shoot_bullet_speed * 0.2
			# Aimed away
			shoot_bullet(shoot_bullet_type, shoot_bullet_speed - half_speed * i, used_angle, shoot_anchor_position, shoot_bullet_color)
			# Aimed behind
			if !disable_secondary_shot:
				shoot_bullet(shoot_bullet_type, shoot_bullet_speed - half_speed * i, used_angle + (deg_to_rad(-90) * signf(final_orbit_speed)), shoot_anchor_position, shoot_bullet_color)

func _get_bullet_angle() -> float:
	return current_angle + deg_to_rad(actual_angle_offset)

func do_orbit_escape() -> void:
	var actual_anchor_vector: Vector2 = anchor_vector
	if !use_static_anchor and is_instance_valid(anchor_node):
		actual_anchor_vector = anchor_node.global_position
	release_self_from_orbit(actual_anchor_vector, current_angle + deg_to_rad(actual_angle_offset), actual_amplitude, deg_to_rad(actual_orbit_speed))

# All radians here
func release_self_from_orbit(anchor: Vector2, angle: float, amplitude: float, orbit_speed: float) -> void:
	release_from_orbit = true
	var new_speed: float = (orbit_speed / (2 * PI)) * (2 * PI * amplitude)
	var new_angle: float = angle + ((PI / 2) * signf(orbit_speed))
	movement_vector = Vector2(new_speed * cos(new_angle), new_speed * sin(new_angle))
	actual_movement_velocity = movement_vector
	begin_moving = true
	use_normal_movement = true
	begin_shooting = false
