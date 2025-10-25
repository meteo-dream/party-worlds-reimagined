@icon("res://engine/objects/bumping_blocks/question_block/textures/icon.png")
@tool
class_name W7QuestionBlock
extends "res://engine/objects/bumping_blocks/question_block/question_block.gd"

var correct_sound: AudioStream = preload("res://objects/w7_spawn_portal/sounds/correct.wav")
var portals: Array
var question_blocks: Array
var barricades: Array

# NOTE: EVERYTHING INVOLVED IN THE 7-2 GIMMICK
# HAVE TO BE PUT UNDER ONE PARENT NODE.
# IDEALLY A NODE2D WILL DO. BARRICADES ARE OPTIONAL,
# BUT IF ADDED, PUT THEM UNDER THE SAME PARENT AS
# THE QUESTION BLOCKS AND PORTAL SPAWNERS.

func _ready() -> void:
	super()
	
	var parent = get_parent()
	if parent:
		var child_list: Array = parent.get_children(false)
		for i in child_list.size():
			var child_classname = child_list[i].get_script().get_global_name()
			if child_classname == "W7Portal":
				portals.append(child_list[i])
			if child_classname == "W7QuestionBlock":
				question_blocks.append(child_list[i])
			if child_classname == "W7Barricade":
				barricades.append(child_list[i])

func bump(disable: bool, bump_rotation: float = 0, interrupt: bool = false) -> void:
	super(disable, bump_rotation, interrupt)
	self.call_deferred("portal_spawn_enemy")
	self.call_deferred("portal_barricade_check")

func portal_spawn_enemy() -> void:
	for i in portals.size():
		portals[i].spawn_enemy()

func portal_barricade_check() -> void:
	var okay_to_start: bool = true
	for i in question_blocks.size():
		if !question_blocks[i]._triggered:
			okay_to_start = false
			break
	
	if okay_to_start and barricades.size() > 0:
		for i in barricades.size():
			barricades[i].triggered = true
			Audio.play_sound(correct_sound, self)
