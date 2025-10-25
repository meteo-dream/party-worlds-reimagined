extends Node2D

const LEAF_EFFECT = preload("res://objects/boss_touhou/common/components/leaf_effect.tscn")

@export var duration: float = 1.4
@export var distance_from_center: float = 30.0
@export var amount_of_effect_max: int = 15
@export var effect_travel_time: float = 2.0
@export var frequency: int = 3
@export var randomize_scale: bool = true
@export var spawn_all_at_once: bool = false
@export_enum("Leaf Gathering:0", "Leaf Spreading:1") var effect_type = 0
var check_for_queue_free: bool = false
var internal_timer: int = 0
var countdown_started: bool = false

@onready var quality: SettingsManager.QUALITY = SettingsManager.settings.quality
@onready var QUALITY = SettingsManager.QUALITY

func _ready() -> void:
	frequency = clamp(frequency, 1, frequency)
	SettingsManager.settings_updated.connect(func() -> void:
		quality = SettingsManager.settings.quality)

func _update_visibility() -> void:
	quality = SettingsManager.settings.quality

func enable_queue_free() -> void:
	check_for_queue_free = true

func _physics_process(delta: float) -> void:
	if countdown_started:
		var timer = get_tree().create_timer(duration, false)
		timer.timeout.connect(enable_queue_free)
		countdown_started = false
	
	var children_list = get_child_count(false)
	
	if check_for_queue_free:
		if children_list <= 0:
			queue_free()
		return
	
	var used_effect_max_count: int = amount_of_effect_max
	if quality == QUALITY.MIN:
		used_effect_max_count = ceili(amount_of_effect_max * 0.5)
	
	if children_list >= used_effect_max_count: return
	if !spawn_all_at_once and internal_timer % frequency == 0: spawn_leaf()
	elif spawn_all_at_once:
		for i in used_effect_max_count:
			spawn_leaf()
	internal_timer += 1

func spawn_leaf() -> void:
	var random_angle = randf_range(0, 360)
	var distance_calc = distance_from_center
	var duration_calc = randf_range(effect_travel_time / 3, effect_travel_time)
	if spawn_all_at_once:
		distance_calc += randf_range(-(distance_from_center / 2), distance_from_center * 3)
		duration_calc = randf_range(effect_travel_time, effect_travel_time * 3)
	var random_vector = Vector2(distance_calc * cos(random_angle), distance_calc * sin(random_angle))
	var random_position = self.global_position + random_vector
	var leaf_effect = LEAF_EFFECT.instantiate()
	add_child(leaf_effect)
	leaf_effect.z_index = z_index - 1
	if effect_type == 0:
		leaf_effect.global_position = random_position
		leaf_effect.destination = global_position
	elif effect_type == 1:
		leaf_effect.global_position = global_position
		leaf_effect.destination = random_position
		leaf_effect.z_index = z_index + 6
	leaf_effect.reset_physics_interpolation()
	leaf_effect.duration = duration_calc
	if randomize_scale:
		var random_float = randf_range(-0.2, 2.3)
		leaf_effect.scale += Vector2(random_float, random_float)
	leaf_effect.effect_type = effect_type
	leaf_effect.do_movement()
