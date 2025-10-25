extends "res://stages/main_menu/scripts/tweak_boolean.gd"


func _handle_toggle(to_set: bool) -> bool:
	var out: bool = super(to_set)
	if SettingsManager.get_tweak(tweak_name, false):
		Input.set_custom_mouse_cursor(preload("res://engine/components/ui/generic/textures/mouse_cursor.png"))
	else:
		Input.set_custom_mouse_cursor(null)
	return out
