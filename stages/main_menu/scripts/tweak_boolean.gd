extends MenuSelection

@export var tweak_name: String
@export var default_value: bool
#@export var lock_behind_story_mode: bool = false
@export_multiline var tweak_description: String

var toggle_off = preload("res://stages/main_menu/sounds/tweak_off.mp3")
@onready var toggle: TextureRect = $Toggle

var is_blocked: bool

func _ready() -> void:
	var tweak = SettingsManager.get_tweak(tweak_name, default_value)
	toggle.texture.region.position.y = 0 if tweak else 16
	
	#if lock_behind_story_mode:
		#var lab: Label = $Label as Label
		#lab.add_theme_color_override("font_color", Color.LIGHT_CORAL)
		#if !SecretsManager.is_endgame():
			#lab.text = "??????? (beat story mode to unlock!)"
			#is_blocked = true
			#tweak_description = "this tweak will be available after you complete the story mode!"


func _handle_focused(focus) -> void:
	super(focus)
	if !focus: return
	if tweak_description:
		$"../..".emit_signal(&"_tweak_desc", get_parent())


func _handle_select(mouse_input: bool = false) -> void:
	if is_blocked: return
	
	var tweak = SettingsManager.get_tweak(tweak_name, default_value)
	_handle_toggle(!tweak)
	if !tweak:
		super(mouse_input)
	else:
		Audio.play_1d_sound(toggle_off, true, { "ignore_pause": true, "bus": "1D Sound" })


func _physics_process(delta: float) -> void:
	super(delta)
	if !focused || !get_parent().focused: return
	
	if Input.is_action_just_pressed("ui_left"):
		var _set: bool = _handle_toggle(false)
		if _set:
			Audio.play_1d_sound(toggle_off, true, { "ignore_pause": true, "bus": "1D Sound" })
	elif Input.is_action_just_pressed("ui_right"):
		var _set: bool = _handle_toggle(true)
		if _set:
			Audio.play_1d_sound(selected_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
	elif Input.is_action_just_pressed(&"ui_select"):
		if tweak_description:
			$"../..".emit_signal(&"_show_desc", tweak_description, $Label.text)


func _handle_toggle(to_set: bool) -> bool:
	if is_blocked:
		return false
	var tweak = SettingsManager.get_tweak(tweak_name, default_value)
	if (to_set && !tweak) || (!to_set && tweak):
		SettingsManager.set_tweak(tweak_name, to_set)
		toggle.texture.region.position.y = 0 if to_set else 16
		return true
	return false
