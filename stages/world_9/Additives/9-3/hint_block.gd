extends "res://engine/objects/bumping_blocks/message_block/message_block.gd"

@export var main_hint_list: Array[String]
@export var alternative_hint_list: Array[String]

func _ready() -> void:
	super()
	if !CustomGlobals.w9b_get_hint_visibility():
		queue_free()
		return
	_set_hint_text()

func _set_hint_text() -> void:
	var string_list
	if CustomGlobals.check_for_hatate_boss():
		string_list = alternative_hint_list
	else: string_list = main_hint_list
	var current_hint = clamp(CustomGlobals.w9b_death_phase, 0, string_list.size() - 1)
	message = string_list[current_hint]
