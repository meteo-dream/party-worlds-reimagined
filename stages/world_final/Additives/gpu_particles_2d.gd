extends GPUParticles2D

@onready var quality: SettingsManager.QUALITY = SettingsManager.settings.quality
@onready var QUALITY = SettingsManager.QUALITY
@onready var init_amount: int = amount

func _ready() -> void:
	SettingsManager.settings_updated.connect(_update_visibility)
	_update_visibility.call_deferred()

func _update_visibility() -> void:
	quality = SettingsManager.settings.quality
	visible = !(quality == QUALITY.MIN)
	emitting = !(quality == QUALITY.MIN)
	if quality == QUALITY.MID:
		amount = mini(200, floori(init_amount * 0.5))
	elif quality == QUALITY.MAX:
		amount = init_amount

func _on_final_boss_handler_final_boss_triggered() -> void:
	queue_free()
