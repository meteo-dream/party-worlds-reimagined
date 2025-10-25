extends LevelWithEndCutscene

const SOUND_PATCH_MOVE = preload("res://objects/boss_touhou/cutscene/sounds/smw_princess_help.wav")
const PATCHOULI_NODE = preload("res://objects/boss_touhou/boss_final/patch_boss.tscn")
const KEVIN_NODE = preload("res://objects/boss_touhou/cutscene/marisa_cutscene.tscn")

@onready var boss_handler_node = $BossW9Handler

func SPECIAL_do_cutscene() -> void:
	if !is_instance_valid(boss_handler_node): return
	var new_destination = boss_handler_node.global_position + Vector2(940.0, -60.0)
	var start_position = boss_handler_node.global_position - Vector2(640.0, -60.0)
	
	var patch_node = PATCHOULI_NODE.instantiate()
	patch_node.is_used_in_cutscene = true
	Scenes.current_scene.add_child(patch_node)
	patch_node.global_position = start_position
	patch_node.reset_physics_interpolation()
	patch_node.move_boss(new_destination, 3.5, Tween.TransitionType.TRANS_LINEAR)
	
	var marisa_new = KEVIN_NODE.instantiate()
	marisa_new.spawn_smoke_effect = true
	Scenes.current_scene.add_child(marisa_new)
	marisa_new.global_position = start_position - Vector2(150.0, 50.0)
	marisa_new.reset_physics_interpolation()
	marisa_new.move_boss(new_destination - Vector2(150.0, 120.0), 3.5, Tween.TransitionType.TRANS_LINEAR)
	
	Audio.play_sound(SOUND_PATCH_MOVE, boss_handler_node)
