extends "res://engine/objects/bumping_blocks/message_block/message_block.gd"

#@export var main_hint_list_text: Array[String]
#@export var alternative_hint_list_text: Array[String]

var main_hint_list: Array[String] = [tr("Aya will follow you around. Make her fly far!", "9-3 Boss 1 Hint 1"), tr("Her camera can reach quite far! Pit her into a corner and run like hell!", "9-3 Boss 1 Hint 2"), tr("Right when she dashes at you, run and jump as far as you can!", "9-3 Boss 1 Hint 3"), tr("Aya will dash from edge to edge. Try not to jump!", "9-3 Boss 1 Hint 4")]
var alternative_hint_list: Array[String] = [tr("Slow and steady wins the race.", "9-3 Boss 2 Hint 1"), tr("Try to keep yourself under her as much as you can.", "9-3 Boss 2 Hint 2"), tr("Jump far away when she takes photos!", "9-3 Boss 2 Hint 3"), tr("Misdirect the homing shots that come from her photographing.", "9-3 Boss 2 Hint 4")]

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
