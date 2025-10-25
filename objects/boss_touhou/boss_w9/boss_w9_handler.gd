extends Node2D

# This handles various things related to the boss fight, including:
# Nonspells and spells, boss triggering, victory sequence
signal boss_w9_triggered

@export_category("VS Aya Shameimaru / Hatate Himekaidou")
@export_group("Trigger", "trigger_")
@export var trigger_boss: W9Boss
@export var trigger_boss_borders: StaticBody2D
@export var trigger_spellcard_background: ParallaxBackground
@export var trigger_boss_HUD: W9BossHUD
@export var trigger_boss_HUD_Y_offset: float = 0.0
@export_enum("Left: -1", "Right: 1") var complete_direction: int = 1
@export_group("Misc. Settings", "settings_")
@export var settings_spellcard_background_layer_1_opacity = 0.65
@export var settings_spellcard_background_layer_2_opacity = 0.45
@export_group("Music")
@export var boss_music: Resource
@export var alternative_boss_music: Resource
@export var boss_music_fading: bool = true
@export var boss_music_start_from_sec: float = 0
@export var boss_music_volume: float = 0

@onready var original_time_scale = Engine.time_scale

var max_spells: int
var music_overlay: CanvasLayer
var _cam_parent: Node
var tween_spellcard_bg

var triggered: bool
var triggered_boss: bool
var current_attack: int = 0
var current_attack_timer: Timer
var spellcard_background_enabled: bool = false
var force_end_due_to_player_death: bool = false
var is_time_slow_active: bool = false

@onready var SFXPlayer: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	var children_list = get_parent().get_children()
	for i in children_list.size():
		if "musicoverlay" in children_list[i].name.to_lower():
			music_overlay = children_list[i]
	if trigger_spellcard_background:
		trigger_spellcard_background.bg_1.modulate.a = 0.0
		trigger_spellcard_background.bg_2.modulate.a = 0.0
	if !trigger_boss_HUD:
		add_sibling.call_deferred(trigger_boss_HUD)
	trigger_boss_HUD.boss_entity = self
	trigger_boss_HUD.y_offset = trigger_boss_HUD_Y_offset
	if !trigger_boss: return
	trigger_boss.request_show_spellcard.connect(start_spell_card)
	trigger_boss.request_hide_spellcard.connect(end_spell_card)
	trigger_boss.victory_achieved.connect(_victory_sequence)
	trigger_boss.request_fail_battle_forced.connect(_fail_battle_auto)
	max_spells = trigger_boss.max_number_of_spellcards
	trigger_boss.request_slow_time.connect(_set_slow_time_scale)
	trigger_boss.request_restore_time.connect(_restore_time_scale)
	trigger_boss.request_check_time.connect(_time_counter_check_time)
	trigger_boss.request_hud_pity.connect(_bonus_hud_activate)

func _special_check_boss_name() -> void:
	trigger_boss_HUD.check_boss_name()

func _physics_process(delta: float) -> void:
	var player: Player = Thunder._current_player
	if !player: return
	
	if !triggered: return
	_time_scale_process()
	
	if player.completed:
		var cam: Camera2D = Thunder._current_camera
		if cam && _cam_parent:
			cam.stop_blocking_edges = true
	#var view: Rect2 = Rect2(get_viewport_transform().affine_inverse().get_origin(), get_viewport_rect().size)
	if !triggered_boss && trigger_boss && trigger_boss.is_in_group(&"#w9boss"): # && view.has_point(trigger_boss.global_position):
		triggered_boss = true
		trigger_boss.trigger = self
		trigger_boss.activate()
	
	if trigger_boss_HUD and trigger_boss:
		if trigger_boss_HUD.spellcard_timecounter and trigger_boss.sc_actual_timer:
			trigger_boss_HUD.spellcard_timecounter.text = trigger_boss_HUD.spellcard_timecounter.text_template % trigger_boss.sc_actual_timer.time_left
			trigger_boss_HUD.spellcard_timecounter.timer_value = trigger_boss.sc_actual_timer.time_left
		if trigger_boss_HUD.boss_photo_counter and trigger_boss:
			var max_pics = trigger_boss.max_number_of_pictures_allowed
			if trigger_boss.hatate_mode: max_pics = trigger_boss.max_number_of_pictures_allowed_alt
			trigger_boss_HUD.boss_photo_counter.text = trigger_boss_HUD.boss_photo_counter.text_template % [trigger_boss.current_pic_count, max_pics]

func _time_counter_check_time() -> void:
	if trigger_boss_HUD:
		trigger_boss_HUD.spellcard_timecounter._check_timer()

func _bonus_hud_activate() -> void:
	if trigger_boss_HUD: trigger_boss_HUD.spell_card_pity_bonus()

func start_boss_dialog() -> void:
	start_boss_fight()

func start_boss_fight() -> void:
	boss_fight_camera()
	boss_fight_music()
	boss_fight_logistics()
	return

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
	var boss_bgm = boss_music
	if is_instance_valid(trigger_boss) and alternative_boss_music:
		if trigger_boss.hatate_mode:
			boss_bgm = alternative_boss_music
	if boss_bgm:
		Audio.stop_all_musics(boss_music_fading)
		Audio.play_music(boss_bgm, 32, {
			start_from_sec = boss_music_start_from_sec,
			volume = boss_music_volume,
			ignore_pause = true,
		} if !boss_music_fading else {
			volume = -20,
			start_from_sec = boss_music_start_from_sec,
			fade_duration = 1.0,
			fade_to = boss_music_volume,
			fade_method = Tween.TransitionType.TRANS_EXPO,
			fade_ease = Tween.EaseType.EASE_OUT,
			ignore_pause = true,
		})
	if music_overlay:
		music_overlay.play(1)

func boss_fight_logistics() -> void:
	triggered = true
	boss_w9_triggered.emit()
	if trigger_boss_HUD and trigger_boss:
		trigger_boss_HUD.spell_card_changed(trigger_boss.max_number_of_spellcards - trigger_boss.current_spell_index)
		trigger_boss_HUD.appear_animation()
	trigger_boss_borders.process_mode = Node.PROCESS_MODE_ALWAYS

func stop_music(fade: bool = true) -> void:
	Audio.stop_music_channel(32, true)
	Thunder._current_hud.timer.paused = true

func battle_failed() -> void:
	var player: Player = Thunder._current_player
	if player: player.die()
	if trigger_boss:
		trigger_boss.failed_boss_fight()
	force_end_due_to_player_death = true
	if trigger_boss_HUD:
		trigger_boss_HUD.disappear()
	_restore_time_scale()

func start_spell_card(index: int = 1) -> void:
	if !trigger_boss: return
	var spell_name: String = trigger_boss.current_spell_name
	if trigger_boss.current_spell_is_card:
		trigger_boss_HUD.spell_card_declare_name(spell_name)
		start_spell_card_bg()

func end_spell_card() -> void:
	if !trigger_boss or !trigger_boss_HUD: return
	trigger_boss_HUD.spell_card_changed(clamp(max_spells - trigger_boss.current_spell_index, 0, max_spells))
	
	if trigger_boss.current_spell_is_card:
		trigger_boss_HUD.spell_card_undeclare_name()
		if !trigger_boss.keep_sc_bg: end_spell_card_bg()

func start_spell_card_bg() -> void:
	if !trigger_spellcard_background or spellcard_background_enabled or force_end_due_to_player_death: return
	spellcard_background_enabled = true
	trigger_spellcard_background.bg_1.modulate.a = 0.0
	trigger_spellcard_background.bg_2.modulate.a = 0.0
	if tween_spellcard_bg:
		tween_spellcard_bg.kill()
	tween_spellcard_bg = get_tree().create_tween()
	tween_spellcard_bg.tween_property(trigger_spellcard_background.bg_1, "modulate:a", settings_spellcard_background_layer_1_opacity, 0.6)
	tween_spellcard_bg.parallel().tween_property(trigger_spellcard_background.bg_2, "modulate:a", settings_spellcard_background_layer_2_opacity, 0.6)

func end_spell_card_bg() -> void:
	if !trigger_spellcard_background or !spellcard_background_enabled: return
	spellcard_background_enabled = false
	trigger_spellcard_background.bg_1.modulate.a = settings_spellcard_background_layer_1_opacity
	trigger_spellcard_background.bg_2.modulate.a = settings_spellcard_background_layer_2_opacity
	if tween_spellcard_bg:
		tween_spellcard_bg.kill()
	tween_spellcard_bg = get_tree().create_tween()
	tween_spellcard_bg.tween_property(trigger_spellcard_background.bg_1, "modulate:a", 0.0, 0.3)
	tween_spellcard_bg.parallel().tween_property(trigger_spellcard_background.bg_2, "modulate:a", 0.0, 0.3)

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
	Scenes.current_scene.set_meta(&"boss_got_defeated", true)
	if is_instance_valid(trigger_boss_HUD):
		trigger_boss_HUD.disappear()
	# start post battle dialog here or something
	await get_tree().create_timer(4.0, false).timeout
	Scenes.current_scene.finish(true, complete_direction)
	trigger_boss_borders.process_mode = Node.PROCESS_MODE_DISABLED

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
	_reset_time_scale()
