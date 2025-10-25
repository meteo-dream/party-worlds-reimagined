extends Sprite2D

@onready var quality: SettingsManager.QUALITY = SettingsManager.settings.quality
@onready var QUALITY = SettingsManager.QUALITY
@export var decrement_per_frame: float = 0.1

func _ready() -> void:
	SettingsManager.settings_updated.connect(_update_visibility)
	_update_visibility.call_deferred()

func _physics_process(delta: float) -> void:
	scale.x = clampf(scale.x - decrement_per_frame, 0.0, 5.0)
	scale.y = clampf(scale.y - decrement_per_frame, 0.0, 5.0)

func _update_visibility() -> void:
	quality = SettingsManager.settings.quality
	visible = !(quality == QUALITY.MIN)
