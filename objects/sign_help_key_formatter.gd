extends "res://engine/objects/signs/sign_help_key_formatter.gd"

var button_string: String = tr('%s button', "e.g. Space button, etc.")

func update_text() -> void:
	var _events: Array[InputEvent] = InputMap.action_get_events(action)
	var _event: String = "buttons on keyboard"
	var _temp: String
	for i in _events:
		if i is InputEventKey:
			_temp = button_string % i.as_text().get_slice(' (', 0)
			_event = _temp
			break
		if _temp: _event = _temp
	
	text = tr(_template) % [_event]
