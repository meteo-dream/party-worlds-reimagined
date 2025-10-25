extends Node

func _physics_process(delta: float) -> void:
	var tweak: bool = SettingsManager.get_tweak("console_enabled", false)
	if Console.is_visible() && !tweak:
		Console.hide()
