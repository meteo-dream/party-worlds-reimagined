extends Sprite2D

@export var rotation_speed: float = 0.3
var stop_spin: bool

@onready var quality: SettingsManager.QUALITY = SettingsManager.settings.quality
@onready var QUALITY = SettingsManager.QUALITY

func _ready() -> void:
	stop_spin = false
	SettingsManager.settings_updated.connect(_update_visibility)
	_update_visibility.call_deferred()

func _update_visibility() -> void:
	quality = SettingsManager.settings.quality
	visible = !(quality == QUALITY.MIN)

func _physics_process(delta: float) -> void:
	if !stop_spin: rotate(rotation_speed)
