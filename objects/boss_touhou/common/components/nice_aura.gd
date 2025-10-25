extends Sprite2D

@export var rotation_speed: float = 0.1
@export var shrink_time: float = 0.3
var anchor_node: Node2D
@onready var quality: SettingsManager.QUALITY = SettingsManager.settings.quality
@onready var QUALITY = SettingsManager.QUALITY

func _ready() -> void:
	SettingsManager.settings_updated.connect(_update_visibility)
	_update_visibility.call_deferred()
	
	modulate.a = 0.0
	var tw = get_tree().create_tween()
	tw.tween_property(self, "scale", Vector2.ZERO, shrink_time)
	tw.parallel().tween_property(self, "modulate:a", 1.0, 0.1)
	tw.tween_callback(_delete_self)

func _update_visibility() -> void:
	quality = SettingsManager.settings.quality
	visible = !(quality == QUALITY.MIN)

func _physics_process(delta: float) -> void:
	rotate(rotation_speed)
	if is_instance_valid(anchor_node):
		global_position = anchor_node.global_position
		reset_physics_interpolation()

func _delete_self() -> void: queue_free()
