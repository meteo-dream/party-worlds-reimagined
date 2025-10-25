extends MenuSelection

@export var preset_names: Array = [
	"mixed",
	"as in version 2.16 / 4.4",
	"as in version 5.0",
	"as in version 7.02",
]

@export var tweak_name: String
@export var default_value: bool
@export_multiline var tweak_description: String

var toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")
@onready var arrow_l: Label = $HBoxContainer/Value/arrow
@onready var arrow_r: Label = $HBoxContainer/HBoxContainer/arrow


func _handle_select(mouse_input: bool = false) -> void:
	if !focused || !get_parent().focused: return
	var tweak = SettingsManager.get_tweak(tweak_name, default_value)
	
	SettingsManager.set_tweak(tweak_name, wrapi(tweak + 1, 0, 4))
	_toggled_option(tweak)
	return


func _physics_process(delta: float) -> void:
	#  as in version
	var tweak = SettingsManager.get_tweak(tweak_name, default_value)
	$HBoxContainer/Value.text = preset_names[tweak]
	arrow_r.visible = focused
	arrow_l.visible = focused
	
	if !focused || !get_parent().focused: return
	
	if tweak == 0:
		arrow_l.visible = false
	elif tweak == 3:
		arrow_r.visible = false
	
	if Input.is_action_just_pressed("ui_right"):
		SettingsManager.set_tweak(tweak_name, clamp(tweak + 1, 0, 3))
		_toggled_option(tweak)
		
	if Input.is_action_just_pressed("ui_left"):
		SettingsManager.set_tweak(tweak_name, clamp(tweak - 1, 0, 3))
		_toggled_option(tweak)


func _toggled_option(old_value: Variant) -> void:
	var tweak = SettingsManager.get_tweak(tweak_name, default_value)
	if old_value != tweak:
		Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
		
