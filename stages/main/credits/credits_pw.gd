extends CreditsScene
class_name CreditsSceneSpecial

const SWITCH_SFX = preload("res://modules/switch-block/sounds/switch.wav")
const CURTAIN_UP_SFX = preload("res://stages/main/credits/sounds/smas_menu.wav")
const CURTAIN_DOWN_SFX = preload("res://stages/main/credits/sounds/smas_menu_close.wav")
const PATH_SFX = preload("res://stages/main/credits/sounds/smw_new_path.wav")

@export var credits_section_list: Array[CreditsSection]
@export var start_on_section_id: int
@export var curtain_pull_time_sec: float = 1.2
var current_section_id: int
@onready var floor_layer: TileMapLayer = $Floor
@onready var curtain_layer: TileMapLayer = $Curtains
@onready var sound_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var skip_label: Label = $SkipLabel
@onready var end_label: Label = $EndLabel
@onready var the_end_label: Label = $TheEnd
var credits_started: bool = false
var credits_finished: bool = false
var curtain_tween: Tween

func _ready() -> void:
	super()
	skip_label.modulate.a = 0.0
	skip_label.show()
	current_section_id = start_on_section_id
	end_label.hide()
	end_label.modulate.a = 0.0
	the_end_label.hide()
	the_end_label.modulate.a = 0.0
	curtain_layer.show()
	_change_screen_modulate(Color.BLACK)
	start_credits()

func start_credits() -> void:
	var tw5 = get_tree().create_tween()
	tw5.tween_property(skip_label, "modulate:a", 1.0, 0.8)
	
	await _set_timer(0.5)
	_change_screen_modulate(Color8(31, 31, 31), 0.7)
	await _set_timer(2.5)
	Audio.stop_all_musics()
	_change_screen_modulate()
	_play_sound_effect(SWITCH_SFX)
	credits_started = true
	
	var tw = get_tree().create_tween()
	tw.tween_property(skip_label, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func() -> void: skip_label.queue_free())
	
	await _set_timer(1.0)
	_pull_up_curtains()
	_play_sound_effect(CURTAIN_UP_SFX)
	await _set_timer(curtain_pull_time_sec + 0.2)
	music_loader.index = 1
	music_loader.play_buffered.call_deferred()
	# Start credits rolling
	_load_credits_section(current_section_id)

func _load_credits_section(index: int = 0) -> void:
	# If true, credits has ended, should close curtains and stop.
	if index > credits_section_list.size() - 1:
		_end_credits()
		return
	# If not, see more credits.
	credits_section_list[index]._do_appear_animation()
	var total_wait_time: float = credits_section_list[index].appear_time_sec + credits_section_list[index].life_time_sec + credits_section_list[index].disappear_time_sec
	await _set_timer(total_wait_time + 0.05)
	current_section_id += 1
	_load_credits_section(current_section_id)

func _end_credits() -> void:
	if credits_finished: return
	credits_finished = true
	current_section_id = credits_section_list.size()
	_lower_curtains()
	if credits_section_list.size() > 0:
		for i in credits_section_list.size():
			credits_section_list[i].queue_free()
		credits_section_list.clear()

## Basic timer function that pauses everything after it until it's up.
func _set_timer(time: float = 1.0, ignore_time_scale: bool = false) -> void:
	await get_tree().create_timer(time, false, false, ignore_time_scale).timeout

func _change_screen_modulate(final_value: Color = Color.WHITE, time: float = 0.01) -> void:
	var tw = get_tree().create_tween()
	tw.tween_property(floor_layer, "modulate", final_value, time)
	tw.tween_property(curtain_layer, "modulate", final_value, time)

func _pull_up_curtains() -> void:
	if !is_instance_valid(curtain_layer): return
	if is_instance_valid(curtain_tween): curtain_tween.kill()
	curtain_tween = get_tree().create_tween()
	curtain_tween.tween_property(curtain_layer, "global_position:y", -480.0, curtain_pull_time_sec)

func _lower_curtains() -> void:
	if !is_instance_valid(curtain_layer): return
	if is_instance_valid(curtain_tween): curtain_tween.kill()
	_play_sound_effect(CURTAIN_DOWN_SFX)
	curtain_tween = get_tree().create_tween()
	curtain_tween.tween_property(curtain_layer, "global_position:y", 0, curtain_pull_time_sec + (curtain_pull_time_sec / 2.0))
	curtain_tween.tween_callback(func() -> void:
		end_label.show()
		the_end_label.show()
		var tw_mod = get_tree().create_tween()
		tw_mod.tween_property(the_end_label, "modulate:a", 1.0, 0.5)
		tw_mod.tween_interval(1.0)
		tw_mod.tween_property(end_label, "modulate:a", 1.0, 0.3)
		await _set_timer(1.5)
		_play_sound_effect(PATH_SFX)
		)

func _play_sound_effect(sound: AudioStream) -> void:
	if !is_instance_valid(sound_player): return
	sound_player.stream = sound
	sound_player.play()

func scene_exit() -> void:
	if is_exiting or !credits_started: return
	is_exiting = true
	Engine.time_scale = _original_time_scale
	Audio._target_music_bus_volume_db = _original_volume
	Data.technical_values.credits_cooldown = Time.get_ticks_msec() + 500
	if music_loader.channel_id in Audio._music_channels && is_instance_valid(Audio._music_channels[music_loader.channel_id]):
		Audio.stop_music_channel(music_loader.channel_id, false)
	## Do transition
	var _crossfade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)
	var scene_to_jump_to = ProjectSettings.get_setting("application/thunder_settings/save_game_room_path")
	if !_crossfade:
		TransitionManager.accept_transition(
			load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
				.instantiate()
				.with_speeds(0.04, -0.1)
				.with_pause()
				.on_player_after_middle(false)
		)
		await TransitionManager.transition_middle
		Scenes.goto_scene(scene_to_jump_to)
	else:
		TransitionManager.accept_transition(
			load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
				.instantiate()
				.with_scene(scene_to_jump_to)
		)

func _input(event: InputEvent) -> void:
	if Data.technical_values.get("credits_cooldown", 0.0) > Time.get_ticks_msec():
		return
	if _are_actions_pressed(event, [&"ui_accept"]):
		scene_exit()
