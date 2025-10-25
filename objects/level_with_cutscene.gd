extends Level
class_name LevelWithEndCutscene

@export var total_cutscene_time_sec: float = 5.0
@export var ignore_time_scale: bool = false
@export_file("*.tscn", "*.scn") var alternate_jump_to_scene: String

func finish(walking: bool = false, walking_dir: int = 1) -> void:
	if !Thunder._current_player: return
	if _level_has_completed:
		return
	level_completed.emit()
	if (
		Thunder.autosplitter.can_split_on("level_end_always") ||
		(Thunder.autosplitter.can_split_on("level_end_no_boss") && !has_meta(&"boss_got_defeated"))
	):
		Thunder.autosplitter.split("Level Ended")
	Thunder.autosplitter.update_il_counter()
	_level_has_completed = true
	print("[Game] Level complete.")

	Thunder._current_hud.timer.paused = true
	Thunder._current_player.completed = true
	Audio.stop_all_musics()
	if completion_music:
		var _custom_music = CharacterManager.get_sound_replace(completion_music, DEFAULT_COMPLETION, "level_complete", false)
		Audio.play_music(_custom_music, -1)

	if walking:
		_force_player_walking = true
		_force_player_walking_dir = walking_dir
	Data.values.onetime_blocks = true
	Thunder._current_player.left_right = 0

	get_tree().call_group_flags(
		get_tree().GROUP_CALL_DEFERRED,
		&"end_level_sequence",
		&"_on_level_end"
	)

	await get_tree().physics_frame
	if completion_music:
		await get_tree().create_timer(completion_music_delay_sec, false, false, true).timeout
	
	# In case the player dies after finish line (e.g. falling in a pit or by touching lava)
	if !Thunder._current_player:
		print_verbose("[Level] Player not found, aborting the level completion sequence.")
		return

	Thunder._current_hud.time_countdown_finished.connect(
		func() -> void:
			await get_tree().create_timer(0.8, false, false).timeout
			SPECIAL_do_cutscene()
			await get_tree().create_timer(total_cutscene_time_sec, false, false, ignore_time_scale).timeout
			# Do not switch scenes if game over screen is opened, might be rare but just in case
			if Scenes.custom_scenes.get("game_over"):
				if Scenes.custom_scenes.game_over.get("opened"):
					return
			var _crossfade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)
			Data.values.checkpoint = -1
			Data.values.checked_cps = []

			var scene_to_jump_to: String = jump_to_scene
			if alternate_jump_to_scene: scene_to_jump_to = alternate_jump_to_scene

			if jump_to_scene or alternate_jump_to_scene:
				if !_crossfade:
					TransitionManager.accept_transition(
						load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
							.instantiate()
							.with_speeds(0.04, -0.1)
							.with_pause()
							.on_player_after_middle(completion_center_on_player_after_transition)
					)

					await TransitionManager.transition_middle
					Scenes.goto_scene(scene_to_jump_to)
				else:
					TransitionManager.accept_transition(
						load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
							.instantiate()
							.with_scene(scene_to_jump_to)
					)
			else:
				printerr("[Level] Jump to scene is not defined in the level.")
	)

	if completion_write_save:
		var profile = ProfileManager.current_profile
		var path = scene_file_path if !completion_write_save_path_override else completion_write_save_path_override
		if Data.values.get("map_force_selected_marker"):
			Data.values.map_force_go_next = true
			Data.values.map_force_old_marker = ""
		if !profile.has_completed(path):
			profile.complete_level(path)
			ProfileManager.save_current_profile()

	Thunder._current_hud.time_countdown()

## Override this to execute cutscene functions. Remember to set the total cutscene time first.
func SPECIAL_do_cutscene() -> void:
	pass
