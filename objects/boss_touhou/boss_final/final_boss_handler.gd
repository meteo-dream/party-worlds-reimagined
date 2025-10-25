extends Node2D
class_name FinalBossHandler

# This handles various things related to the boss fight, including:
# Nonspells and spells, boss triggering, victory sequence
# Slightly different implementation of progress compared to the W9 bosses.
# Here, the control lies with the handler.
signal final_boss_triggered
signal final_boss_next_phase
signal allow_continue_dialog

const PLATFORM_SUPPORT = preload("res://objects/boss_touhou/boss_final/platform_support.tscn")
const NEW_BALLOON = preload("res://objects/boss_touhou/dialogue/balloon.tscn")
const FINAL_BOSS_HUD = preload("res://objects/boss_touhou/boss_final/final_boss_hud.tscn")

@export_category("VS Remilia Scarlet + Marisa Kirisame?")
@export_group("Custom Victory Screen")
@export var show_victory_screen: bool = true
@export var white_background: Sprite2D
@export var you_win_text: Label
@export_group("Trigger")
@export var boss: FinalBoss
@export var side_boss: FinalBoss
@export_group("Trigger", "trigger_")
@export var trigger_boss_borders: StaticBody2D
@export var trigger_spellcard_background: ParallaxBackground
@export var trigger_boss_HUD: FinalBossHUD
@export var trigger_boss_HUD_Y_offset: float = 0.0
@export var trigger_dialogue: TouhouDialogueBalloon
@export_enum("Left: -1", "Right: 1") var complete_direction: int = 1
@export_group("Music", "boss_music_")
@export var boss_music_song: Resource
@export var boss_music_fading: bool = true
@export var boss_music_start_from_sec: float = 0
@export var boss_music_volume: float = 0
@export var boss_music_overlay_index: int = 1
@export var boss_music_phase_change_channel: int = 25
@export var boss_music_phase_change_note: String = "C-05"
@export var boss_music_excluded_positions: Array[int] = [0, 6, 8, 10, 11, 12, 14, 16, 18, 20, 32, 33, 34, 36]
@export var boss_music_jump_to_position: Array[int] = [29, 0]
@export_group("Battle Settings")
@export var phase_change_in_music_list: Array[float]
@export_group("Spellcard Background Settings", "settings_scbg_")
@export var settings_scbg_remilia_opacity = 0.3
@export var settings_scbg_marisa_layer_1_opacity = 0.65
@export var settings_scbg_marisa_layer_2_opacity = 0.45

@onready var original_time_scale = Engine.time_scale
@onready var music_sync_node: MusicSync = $MusicSync

var phase_index: int
var music_overlay: CanvasLayer
var _cam_parent: Node
var tween_spellcard_bg
var enable_secondary_boss: bool = false

var triggered: bool
var triggered_boss: bool
var spellcard_background_enabled: bool = false
var force_end_due_to_player_death: bool = false
var is_time_slow_active: bool = false
var platform_support_object: BossPlatformSupport
var victory_seq_activated: bool = false

var music_playback: AudioStreamPlaybackMPT
var music_playback_timestamp_index: int = 0

var is_in_dialog: bool = false

@onready var SFXPlayer: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	if CharacterManager.get_character_display_name().to_lower() != "marisa" and CharacterManager.get_character_display_name().to_lower() != "reimu":
		if is_instance_valid(trigger_dialogue): trigger_dialogue.queue_free()
	if !is_instance_valid(trigger_boss_HUD):
		trigger_boss_HUD = FINAL_BOSS_HUD.instantiate()
		Scenes.current_scene.add_child(trigger_boss_HUD)
	
	if is_instance_valid(white_background):
		white_background.hide()
		white_background.self_modulate.a = 0.0
	if is_instance_valid(you_win_text):
		you_win_text.hide()
		you_win_text.self_modulate.a = 0.0
	
	var children_list = get_parent().get_children()
	for i in children_list.size():
		if "musicoverlay" in children_list[i].name.to_lower():
			music_overlay = children_list[i]
	if trigger_spellcard_background:
		trigger_spellcard_background.bg_1.modulate.a = 0.0
		trigger_spellcard_background.bg_2.modulate.a = 0.0
	
	trigger_boss_HUD.boss_entity = boss
	trigger_boss_HUD.y_offset = trigger_boss_HUD_Y_offset
	# Boss
	if is_instance_valid(boss):
		boss.request_show_spellcard.connect(start_spell_card)
		boss.request_hide_spellcard.connect(end_spell_card)
		boss.victory_achieved.connect(_victory_sequence)
		boss.request_fail_battle_forced.connect(_fail_battle_auto)
		boss.request_hud_pity.connect(_bonus_hud_activate)
		boss.request_platform_support.connect(call_for_platform_support)
		boss.request_delete_support.connect(func() -> void:
			if is_instance_valid(platform_support_object):
				platform_support_object.move_out()
			)
		boss.request_slow_time.connect(_set_slow_time_scale)
		boss.request_restore_time.connect(_restore_time_scale)
		
		if boss_music_jump_to_position.size() > 0:
			phase_index = 18
	# Side Boss
	if is_instance_valid(side_boss):
		side_boss.request_show_spellcard.connect(start_spell_card)
		side_boss.request_hide_spellcard.connect(end_spell_card)
		side_boss.victory_achieved.connect(_victory_sequence)
		side_boss.request_fail_battle_forced.connect(_fail_battle_auto)
		side_boss.request_hud_pity.connect(_bonus_hud_activate)
		side_boss.request_platform_support.connect(call_for_platform_support)
		side_boss.request_delete_support.connect(func() -> void:
			if is_instance_valid(platform_support_object):
				platform_support_object.move_out()
			)
		side_boss.request_slow_time.connect(_set_slow_time_scale)
		side_boss.request_restore_time.connect(_restore_time_scale)
		
		if boss_music_jump_to_position.size() > 0:
			side_boss.offset_phase_index = -12
	# Music Sync
	if is_instance_valid(music_sync_node):
		music_sync_node.channel_to_check = boss_music_phase_change_channel
		music_sync_node.excluded_positions = boss_music_excluded_positions
		music_sync_node.note_to_check = boss_music_phase_change_note
		music_sync_node.progress_to_next_phase.connect(phase_progression)
		music_sync_node.force_end_battle.connect(_signal_force_boss_defeat)

func call_for_platform_support() -> void:
	if !is_instance_valid(platform_support_object):
		platform_support_object = PLATFORM_SUPPORT.instantiate()
		Scenes.current_scene.add_child(platform_support_object)
		platform_support_object.global_position = global_position - Vector2(320.0, 240.0)
		reset_physics_interpolation()

func _special_check_boss_name() -> void:
	trigger_boss_HUD.check_boss_name()

func _special_change_boss_name(type: int = 0) -> void:
	if !is_instance_valid(trigger_boss_HUD): return
	trigger_boss_HUD.change_boss_name(type)

func _physics_process(delta: float) -> void:
	var player: Player = Thunder._current_player
	if !player: return
	
	if !triggered: return
	_time_scale_process()
	_timer_process()
	
	if player.completed:
		var cam: Camera2D = Thunder._current_camera
		if cam && _cam_parent:
			cam.stop_blocking_edges = true
	#var view: Rect2 = Rect2(get_viewport_transform().affine_inverse().get_origin(), get_viewport_rect().size)
	if !triggered_boss && boss && boss.is_in_group(&"#finalboss"): # && view.has_point(boss.global_position):
		triggered_boss = true
		boss.trigger = self

func _timer_process() -> void:
	if phase_change_in_music_list.size() <= 0 or !is_instance_valid(trigger_boss_HUD) or music_playback_timestamp_index > phase_change_in_music_list.size(): return
	var timer_difference: float
	if !is_instance_valid(music_playback):
		if !Audio._music_channels.has(32) or !is_instance_valid(Audio._music_channels[32]): return
		music_playback = Audio._music_channels[32].get_stream_playback()
		return
	else:
		var correct_index_number: int = clampi(music_playback_timestamp_index, 0, phase_change_in_music_list.size() - 1)
		var timer_max: float = phase_change_in_music_list[correct_index_number]
		timer_difference = clampf(timer_max - music_playback.get_playback_position(), 0.0, 99.99)
		trigger_boss_HUD.update_time_counter(timer_difference)
		
		# Spellcard ring effect
		var timer_max_adjusted: float = timer_max - phase_change_in_music_list[clampi(correct_index_number - 1, 0, 99)]
		if is_instance_valid(boss):
			boss.current_playback_time = timer_difference
			boss.limit_playback_time = timer_max_adjusted
		if is_instance_valid(side_boss) and enable_secondary_boss:
			side_boss.current_playback_time = timer_difference
			side_boss.limit_playback_time = timer_max_adjusted
		
		if timer_difference <= 0.0:
			music_playback_timestamp_index += 1
			if is_instance_valid(boss): boss.limit_playback_time = timer_max_adjusted
			if is_instance_valid(side_boss) and enable_secondary_boss: side_boss.limit_playback_time = timer_max_adjusted

func _bonus_hud_activate() -> void:
	if !is_instance_valid(trigger_boss_HUD): return
	trigger_boss_HUD.spell_card_pity_bonus()

func start_boss_dialog() -> void:
	if is_in_dialog: return
	is_in_dialog = true
	var chosen_dialogue_tree
	if CharacterManager.get_character_display_name().to_lower() == "marisa":
		chosen_dialogue_tree = load("res://objects/boss_touhou/dialogue/vs_marisa.dialogue")
	elif CharacterManager.get_character_display_name().to_lower() == "reimu":
		chosen_dialogue_tree = load("res://objects/boss_touhou/dialogue/vs_reimu.dialogue")
	else:
		start_boss_fight()
		return
	Thunder._current_player.completed = true
	if !is_instance_valid(trigger_dialogue):
		trigger_dialogue = NEW_BALLOON.instantiate()
		Scenes.current_scene.add_child(trigger_dialogue)
	trigger_dialogue.start(chosen_dialogue_tree, "start", [self, FinalBossHandler.new()])
	#start_boss_fight()

func SPECIAL_move_boss_into_position() -> void:
	if !is_instance_valid(boss): return
	boss.move_boss(global_position + Vector2(170.0, -80.0), 2.0)
	await get_tree().create_timer(2.0, false).timeout
	SPECIAL_show_boss_title()
	allow_continue_dialog.emit()

func SPECIAL_show_boss_title() -> void:
	if !is_instance_valid(trigger_dialogue): return
	trigger_dialogue.show_boss_title()

func SPECIAL_start_fight() -> void:
	if is_instance_valid(trigger_dialogue):
		trigger_dialogue.hide_boss_title()
	await get_tree().create_timer(0.3, false).timeout
	Thunder._current_player.completed = false
	start_boss_fight()

func start_boss_fight() -> void:
	boss_fight_camera()
	boss_fight_music()
	boss_fight_logistics()

func boss_fight_camera() -> void:
	var cam: Camera2D = Thunder._current_camera
	if cam: 
		_cam_parent = cam.get_parent()
		cam.reparent(self)
		cam.par = cam.get_parent()
		cam.force_update_transform()
		cam.reset_physics_interpolation()
		cam.force_update_scroll()
		cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
		cam.stop_blocking_edges = false

func boss_fight_music() -> void:
	var boss_bgm = boss_music_song
	if boss_bgm:
		Audio.stop_all_musics(boss_music_fading)
		Audio.play_music(boss_bgm, 32, {
			start_from_sec = boss_music_start_from_sec,
			volume = boss_music_volume,
			ignore_pause = false,
		} if !boss_music_fading else {
			volume = -20,
			start_from_sec = boss_music_start_from_sec,
			fade_duration = 1.0,
			fade_to = boss_music_volume,
			fade_method = Tween.TransitionType.TRANS_EXPO,
			fade_ease = Tween.EaseType.EASE_OUT,
			ignore_pause = false,
		})
		
		# The following is a debug feature. Remove before the official release.
		await get_tree().create_timer(0.1, false).timeout
		if boss_music_jump_to_position.size() > 0:
			var mod: AudioStreamMPT
			if !Audio._music_channels.has(32): return
			if (is_instance_valid(Audio._music_channels[32]) &&
				Audio._music_channels[32].stream is AudioStreamMPT):
				mod = Audio._music_channels[32].stream
			if _null_check(mod): return
			var playback: AudioStreamPlaybackMPT = Audio._music_channels[32].get_stream_playback()
			if !is_instance_valid(playback): return
			playback.seek(boss_music_jump_to_position[0], boss_music_jump_to_position[1])
			# TODO: crutch for debugging, remove this when production rolls around
	if music_overlay:
		music_overlay.play(boss_music_overlay_index)

func _null_check(mod) -> bool:
	if !mod: return true
	if !is_instance_valid(mod): return true
	return false

func boss_fight_logistics() -> void:
	triggered = true
	music_sync_node._boss_show_up()
	final_boss_triggered.emit()
	if trigger_boss_HUD:
		trigger_boss_HUD.spell_card_changed(0)
		trigger_boss_HUD.appear_animation()
	if boss: boss.activate()
	if boss_music_jump_to_position.size() > 0:
		if is_instance_valid(side_boss):
			side_boss.activate()
			side_boss.trigger = self
			side_boss.offset_phase_index = 12
			enable_secondary_boss = true
			side_boss.current_spell_index = phase_index
	trigger_boss_borders.process_mode = Node.PROCESS_MODE_ALWAYS

func stop_music(fade: bool = true) -> void:
	Audio.stop_music_channel(32, fade)
	Thunder._current_hud.timer.paused = true

func battle_failed() -> void:
	var player: Player = Thunder._current_player
	if player: player.die()
	if boss:
		boss.failed_boss_fight()
		if is_instance_valid(side_boss) and enable_secondary_boss:
			side_boss.failed_boss_fight()
	force_end_due_to_player_death = true
	if trigger_boss_HUD:
		trigger_boss_HUD.disappear()
	_restore_time_scale()

func phase_progression() -> void:
	phase_index = clamp(phase_index + 1, 0, 50)
	if boss:
		if boss.next_attack_is_new: boss.end_spell_card()
		else: boss.current_spell_index = phase_index
		if phase_index > 0: boss.start_next_spell_card()
	if side_boss and enable_secondary_boss:
		if side_boss.next_attack_is_new: side_boss.end_spell_card()
		else: side_boss.current_spell_index = phase_index
		if phase_index > 0: side_boss.start_next_spell_card()

func start_spell_card() -> void:
	if !is_instance_valid(boss): return
	var spell_name: String = boss.current_spell_name
	if boss.current_spell_is_card and boss.next_attack_is_new and boss.player_should_get_pity:
		trigger_boss_HUD.spell_card_declare_name(spell_name)
		start_spell_card_bg()
	
	if !is_instance_valid(side_boss) or !enable_secondary_boss: return
	var spell_name_side: String = side_boss.current_spell_name
	if side_boss.current_spell_is_card and side_boss.next_attack_is_new and side_boss.player_should_get_pity:
		trigger_boss_HUD.spell_card_declare_name(spell_name_side)
		start_spell_card_bg()

func end_spell_card() -> void:
	if !boss or (!side_boss and enable_secondary_boss) or !trigger_boss_HUD: return
	if boss.current_spell_is_card and (boss.next_attack_is_new or boss.force_end_player_death):
		trigger_boss_HUD.spell_card_undeclare_name()
		if !boss.keep_sc_bg: end_spell_card_bg()
	if enable_secondary_boss:
		if side_boss.current_spell_is_card and (side_boss.next_attack_is_new or side_boss.force_end_player_death):
			trigger_boss_HUD.spell_card_undeclare_name()
			if !side_boss.keep_sc_bg: end_spell_card_bg()

func start_spell_card_bg() -> void:
	if !is_instance_valid(trigger_spellcard_background) or spellcard_background_enabled or force_end_due_to_player_death: return
	spellcard_background_enabled = true
	trigger_spellcard_background.bg_1.modulate.a = 0.0
	trigger_spellcard_background.bg_2.modulate.a = 0.0
	if tween_spellcard_bg:
		tween_spellcard_bg.kill()
	tween_spellcard_bg = get_tree().create_tween()
	tween_spellcard_bg.tween_property(trigger_spellcard_background.bg_1, "modulate:a", settings_scbg_marisa_layer_1_opacity, 0.6)
	tween_spellcard_bg.parallel().tween_property(trigger_spellcard_background.bg_2, "modulate:a", settings_scbg_marisa_layer_2_opacity, 0.6)

func end_spell_card_bg() -> void:
	if !trigger_spellcard_background or !spellcard_background_enabled: return
	spellcard_background_enabled = false
	trigger_spellcard_background.bg_1.modulate.a = settings_scbg_marisa_layer_1_opacity
	trigger_spellcard_background.bg_2.modulate.a = settings_scbg_marisa_layer_2_opacity
	if tween_spellcard_bg:
		tween_spellcard_bg.kill()
	tween_spellcard_bg = get_tree().create_tween()
	tween_spellcard_bg.tween_property(trigger_spellcard_background.bg_1, "modulate:a", 0.0, 0.3)
	tween_spellcard_bg.parallel().tween_property(trigger_spellcard_background.bg_2, "modulate:a", 0.0, 0.3)

# Time scale is only used when the bosses are defeated.
func _time_scale_process() -> void:
	if is_time_slow_active:
		if Engine.time_scale != 0.4: Engine.time_scale = 0.4
	else: _reset_time_scale()

func _reset_time_scale() -> void:
	var target_time_scale = SettingsManager.settings["game_speed"]
	if target_time_scale == null: target_time_scale = original_time_scale
	Engine.time_scale = target_time_scale

func _set_slow_time_scale() -> void:
	is_time_slow_active = true

func _restore_time_scale() -> void:
	is_time_slow_active = false

func _play_sound_interruptable(resource: AudioStream, volume: float = 0.0) -> void:
	if !resource: return
	if SFXPlayer.playing: SFXPlayer.stop()
	SFXPlayer.stream = resource
	SFXPlayer.play()

func _on_player_detector_body_entered(body: Node2D) -> void:
	var script = body.get_script()
	if script and script.get_global_name() == "Player" and !triggered:
		start_boss_dialog()

func _victory_sequence() -> void:
	if victory_seq_activated: return
	victory_seq_activated = true
	Scenes.current_scene.set_meta(&"boss_got_defeated", true)
	if is_instance_valid(trigger_boss_HUD):
		trigger_boss_HUD.disappear()
	stop_music(false)
	await get_tree().create_timer(1.2, false).timeout
	_restore_time_scale()
	var wait_time: float = 2.8
	if show_victory_screen:
		_custom_victory_screen()
		wait_time += 2.0
	await get_tree().create_timer(wait_time, false, false, true).timeout
	Scenes.current_scene.finish(true, complete_direction)
	trigger_boss_borders.process_mode = Node.PROCESS_MODE_DISABLED
	CustomGlobals.unlock_fancy_credits = true
	CustomGlobals.save_credits_status()
	ProfileManager.save_current_profile()

func _custom_victory_screen() -> void:
	if !is_instance_valid(white_background) or !is_instance_valid(you_win_text): return
	white_background.show()
	you_win_text.show()
	var tw = get_tree().create_tween()
	tw.tween_property(white_background, "self_modulate:a", 1.0, 2.0)
	await get_tree().create_timer(0.8, false, false, true).timeout
	var tw2 = get_tree().create_tween()
	tw2.tween_property(you_win_text, "self_modulate:a", 1.0, 1.5)

func _signal_force_boss_defeat() -> void:
	if !is_instance_valid(boss) or (!is_instance_valid(side_boss) and enable_secondary_boss): return
	if boss.defeated_boss_wander or (side_boss.defeated_boss_wander and enable_secondary_boss): return
	boss._battle_victory_sequence()
	side_boss._battle_victory_sequence()

func hide_photo_counter() -> void:
	trigger_boss_HUD.boss_photo_counter.disappear()
	trigger_boss_HUD.boss_photo_label.disappear()

func show_photo_counter() -> void:
	trigger_boss_HUD.boss_photo_counter.appear()
	trigger_boss_HUD.boss_photo_label.appear()

func _fail_battle_auto() -> void:
	if triggered:
		battle_failed()

func _on_player_died() -> void:
	_fail_battle_auto()
	is_time_slow_active = false
	#_reset_time_scale()
