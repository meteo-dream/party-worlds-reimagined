extends AnimatedSprite2D

@onready var quality: SettingsManager.QUALITY = SettingsManager.settings.quality
@onready var QUALITY = SettingsManager.QUALITY

func _ready() -> void:
	rotate(randf_range(0, PI*2))
	animation_finished.connect(delete_self)
	SettingsManager.settings_updated.connect(_update_visibility)
	_update_visibility.call_deferred()

func _update_visibility() -> void:
	quality = SettingsManager.settings.quality
	visible = !(quality == QUALITY.MIN)

func delete_self():
	queue_free()
