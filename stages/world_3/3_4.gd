extends LevelWithEndCutscene

const SOUND_CHARGE_LONG = preload("res://objects/boss_touhou/common/sounds/se_ch00.wav")
const FLASHBANG = preload("res://objects/boss_touhou/cutscene/flashbang.tscn")
const SOUND_PATCH_MOVE = preload("res://objects/boss_touhou/cutscene/sounds/smw_princess_help.wav")
const SOUND_TRANSFORM = preload("res://objects/boss_touhou/cutscene/sounds/smas_transform.wav")

const REVIVE = preload("res://engine/objects/players/prefabs/sounds/1up.wav")
const APPEAR = preload("res://stages/world_3/objects/chorniy_mario/appear.ogg")
const JUMP = preload("res://engine/objects/players/prefabs/sounds/jump.wav")

@onready var finish_line = $FinishLine

func SPECIAL_do_cutscene() -> void:
	# Move Patchouli into action.
	var patch_move_pos: Vector2 = finish_line.global_position - Vector2(32.0, 176.0)
	var patch_node = load("res://objects/boss_touhou/boss_final/patch_boss.tscn").instantiate()
	patch_node.is_used_in_cutscene = true
	Scenes.current_scene.add_child(patch_node)
	patch_node.z_index = 50
	patch_node.global_position = patch_move_pos + Vector2(640.0, -100.0)
	patch_node.reset_physics_interpolation()
	Audio.play_sound(SOUND_PATCH_MOVE, finish_line)
	patch_node.SPECIAL_do_w3_cutscene(patch_move_pos)
	await get_tree().create_timer(5.5, false, false).timeout
	# Spawn Kevin
	patch_node.reset_to_default_anim()
	var kevin_spawn_pos: Vector2 = finish_line.global_position + Vector2(128.0, -144.0)
	var kevin_new = load("res://objects/boss_touhou/cutscene/kevin_cutscene.tscn").instantiate()
	Scenes.current_scene.add_child(kevin_new)
	kevin_new.z_index = 50
	kevin_new.global_position = kevin_spawn_pos
	kevin_new.reset_physics_interpolation()
	Audio.play_sound(REVIVE, kevin_new)
	Audio.play_sound(APPEAR, kevin_new)
	Audio.play_sound(JUMP, kevin_new)
	kevin_new.transform_into_marisa.connect(func() -> void:
		# Start transformation
		Audio.play_sound(load("res://objects/boss_touhou/cutscene/sounds/charge_2.wav"), kevin_new)
		await get_tree().create_timer(0.4, false, false).timeout
		do_screen_shake(3.2, 8)
		patch_node.w34_spawn_leaf_elsewhere = true
		patch_node.w34_spawn_leaf_position = kevin_new.global_position
		patch_node.leaf_gather_effect(2.8, 250.0, 300, 0.4, 1)
		await get_tree().create_timer(2.1, false, false).timeout
		do_screen_shake(0.4, 6)
		await get_tree().create_timer(0.25, false, false).timeout
		do_screen_shake(0.4, 3)
		await get_tree().create_timer(0.25, false, false).timeout
		do_screen_shake(0.4, 1)
		await get_tree().create_timer(0.25, false, false).timeout
		# Flashbang
		Audio.play_sound(SOUND_TRANSFORM, kevin_new)
		var flashbang = FLASHBANG.instantiate()
		Scenes.current_scene.add_child(flashbang)
		flashbang.z_index = 80
		flashbang.global_position = Thunder.view.border.position + Vector2i(320, 240)
		flashbang.reset_physics_interpolation()
		var marisa_new = load("res://objects/boss_touhou/cutscene/marisa_cutscene.tscn").instantiate()
		Scenes.current_scene.add_child(marisa_new)
		Audio.play_sound(APPEAR, kevin_new)
		marisa_new.z_index = 50
		marisa_new.global_position = kevin_new.global_position
		marisa_new.reset_physics_interpolation()
		Audio.play_sound(load("res://objects/boss_touhou/cutscene/sounds/charge_up.wav"), marisa_new)
		kevin_new.queue_free()
		await get_tree().create_timer(2.0, false, false).timeout
		patch_node.move_boss(patch_move_pos + Vector2(700.0, -45.0), 1.1, Tween.TRANS_CIRC, Tween.EASE_IN)
		marisa_new.move_boss(patch_move_pos + Vector2(700.0, 0.0), 1.1, Tween.TRANS_CIRC, Tween.EASE_IN)
		)

func do_screen_shake(duration: float = 0.2, amplitude: int = 6, interval: float = 0.01) -> void:
	if Thunder._current_camera.has_method(&"shock"):
		Thunder._current_camera.shock(duration, Vector2.ONE * amplitude, interval)
