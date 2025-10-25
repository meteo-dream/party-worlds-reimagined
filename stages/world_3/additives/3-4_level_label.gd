extends Label

var template: String = text

func _ready() -> void:
	var player_name: String = CharacterManager.get_character_display_name().to_lower()
	text = template % player_name
