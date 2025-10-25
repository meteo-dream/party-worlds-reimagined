extends LevelWithEndCutscene

const SOUND_PATCH_MOVE = preload("res://objects/boss_touhou/cutscene/sounds/smw_princess_help.wav")

@export var patchouli_start_position: Vector2 = Vector2.ZERO
@export var move_patchouli_to_position: Vector2 = Vector2.ZERO

func SPECIAL_do_cutscene() -> void:
	var patch_boss = load("res://objects/boss_touhou/boss_final/patch_boss.tscn").instantiate()
	patch_boss.is_used_in_cutscene = true
	patch_boss.w14_move_to_position = move_patchouli_to_position
	Scenes.current_scene.add_child(patch_boss)
	patch_boss.global_position = patchouli_start_position
	patch_boss.reset_physics_interpolation()
	Audio.play_sound(SOUND_PATCH_MOVE, Thunder._current_camera)
	patch_boss.SPECIAL_do_w1_cutscene()
