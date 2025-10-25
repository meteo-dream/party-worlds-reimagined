extends Sprite2D

const appear_time_type2: float = 0.2

@export_enum("Spellcard Ring:0", "Border of Life Ring:1", "Spellcard Declaration:2") var ring_type = 0
@export var rotation_speed: float = -0.05
@export var source_offset_array: Array[float] = [0.383, 0.625, 0.75]
@export var type_2_life_time: float = 1.0
var boss_node
var can_shrink: bool = false
var grow_thickness: bool = false
var post_appear_scale: Vector2 = Vector2(4.0, 4.0)
var appear_thickness_0: float = 1.0
var scale_at_time_of_shrink: Vector2
var time_left_offset_percent: float
# This here exists because the final boss is timed to the music lmao
var DO_NOT_USE_TIMER: bool = false
var appear_faster_scale: float = 1.0

@onready var quality: SettingsManager.QUALITY = SettingsManager.settings.quality
@onready var QUALITY = SettingsManager.QUALITY

func _ready() -> void:
	SettingsManager.settings_updated.connect(_update_visibility)
	_update_visibility.call_deferred()
	
	set_instance_shader_parameter("source_offset", source_offset_array[ring_type])
	match ring_type:
		0:
			set_instance_shader_parameter("thickness", 1.0)
		1:
			rotation_speed *= -1.0
	if is_instance_valid(boss_node):
		#boss_node.add_child(self)
		z_index = boss_node.z_index - 1
	play_appear_animation()

func _update_visibility() -> void:
	quality = SettingsManager.settings.quality
	visible = !(quality == QUALITY.MIN)

func _physics_process(delta: float) -> void:
	rotate(rotation_speed * Engine.time_scale)
	if is_instance_valid(boss_node): global_position = boss_node.global_position
	else: return
	if ring_type == 0: set_instance_shader_parameter("thickness", appear_thickness_0)
	if !can_shrink: return
	var actual_percent_value = set_actual_percent_value(set_ring_percent_scale())
	scale = scale_at_time_of_shrink * actual_percent_value
	if actual_percent_value < 0.7: enable_grow_thickness()
	if !grow_thickness: return
	set_instance_shader_parameter("thickness", 0.1 + (0.5 * (1.0 - (actual_percent_value + time_left_offset_percent))))

func set_ring_percent_scale() -> float:
	var final_value: float
	if !DO_NOT_USE_TIMER:
		final_value = boss_node.sc_actual_timer.time_left / boss_node.current_spell_used.spellcard_time
	else:
		final_value = boss_node.current_playback_time / boss_node.limit_playback_time
	return clampf(final_value, 0.0, 1.0)

func set_actual_percent_value(percent_scale: float) -> float:
	return clampf(percent_scale + 0.1, 0.15, 1.0)

func play_appear_animation() -> void:
	match ring_type:
		0:
			var tw_scale = get_tree().create_tween()
			tw_scale.set_ease(Tween.EASE_OUT)
			tw_scale.set_trans(Tween.TRANS_CIRC)
			tw_scale.tween_property(self, "appear_thickness_0", 0.1, 0.6 * appear_faster_scale)
			tw_scale.parallel().tween_property(self, "scale", post_appear_scale, 0.2 * appear_faster_scale)
			tw_scale.tween_callback(enable_shrinking)
		1:
			scale = Vector2.ZERO
			var tw2 = get_tree().create_tween()
			tw2.tween_property(self, "scale", post_appear_scale * 3.0, 0.3 * appear_faster_scale)
			tw2.tween_property(self, "scale", post_appear_scale, 1.0 * appear_faster_scale)
			tw2.tween_callback(enable_shrinking)
		2:
			modulate.a = 0.0
			var tw3 = get_tree().create_tween()
			tw3.tween_property(self, "modulate:a", 1.0, appear_time_type2)
			await get_tree().create_timer(type_2_life_time, false).timeout
			var tw4 = get_tree().create_tween()
			tw4.tween_property(self, "modulate:a", 0.0, appear_time_type2)
			tw4.tween_callback(func() -> void: queue_free())

func enable_shrinking() -> void:
	scale_at_time_of_shrink = scale
	can_shrink = true

func enable_grow_thickness() -> void:
	if grow_thickness: return
	grow_thickness = true
	time_left_offset_percent = 1.0 - set_actual_percent_value(set_ring_percent_scale())

func play_end_anim() -> void:
	var tw = get_tree().create_tween()
	tw.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tw.tween_callback(func() -> void: queue_free())
