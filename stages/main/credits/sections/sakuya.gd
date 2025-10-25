extends Node

func _ready() -> void:
	if CharacterManager.get_character_display_name().to_lower() != "reimu":
		queue_free()
