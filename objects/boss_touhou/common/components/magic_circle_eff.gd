extends Sprite2D

@export var rotation_speed_in_radians: float = -0.1
@export_group("Circle Pulse")
@export var scale_min: Vector2 = Vector2(1.2, 1.2)
@export var scale_max: Vector2 = Vector2(1.3, 1.3)
@export_range(0, 360, 0.01, "suffix: °") var phase: float
@export var random_phase: bool:
	set(rph):
		random_phase = rph
		if random_phase:
			phase = randf_range(0, 360)
@export var frequency: float = 4.0
@export_group("Appear Animation Settings")
@export var rotation_speed_on_appear_in_radians: float = -0.2
@export var animation_duration: float = 0.8

var free_rotate: bool = false
var actual_rotate_speed: float = 0.0

@onready var quality: SettingsManager.QUALITY = SettingsManager.settings.quality
@onready var QUALITY = SettingsManager.QUALITY

func _ready() -> void:
	scale = Vector2.ZERO
	SettingsManager.settings_updated.connect(_update_visibility)
	_update_visibility.call_deferred()

func _update_visibility() -> void:
	quality = SettingsManager.settings.quality
	visible = !(quality == QUALITY.MIN)

func _physics_process(delta: float) -> void:
	if !free_rotate:
		rotate(actual_rotate_speed * Engine.time_scale)
		return
	rotate(rotation_speed_in_radians * Engine.time_scale)
	var scale_calc = Thunder.Math.oval(scale_min, scale_max - scale_min, deg_to_rad(phase))
	scale = Vector2(scale_calc.x, scale_calc.x)
	phase = wrapf(phase + frequency * Thunder.get_delta(delta), 0, 360)

func appear_animation() -> void:
	actual_rotate_speed = rotation_speed_on_appear_in_radians
	var tw_scale = get_tree().create_tween()
	tw_scale.set_trans(Tween.TRANS_CIRC)
	tw_scale.set_ease(Tween.EASE_OUT)
	tw_scale.tween_property(self, "scale", scale_max, animation_duration)
	tw_scale.tween_callback(allow_free_rotate)
	var tw_rotate = get_tree().create_tween()
	tw_rotate.tween_property(self, "actual_rotate_speed", 0.0, animation_duration)

func allow_free_rotate() -> void:
	free_rotate = true
	actual_rotate_speed = rotation_speed_in_radians

func disappear_animation() -> void:
	var tw = get_tree().create_tween()
	tw.set_trans(Tween.TRANS_CIRC)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector2.ZERO, animation_duration)
	tw.tween_callback(func() -> void:
		free_rotate = false
		actual_rotate_speed = 0.0
		global_rotation = 0.0
		)
