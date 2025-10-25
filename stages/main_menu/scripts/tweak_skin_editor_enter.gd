extends MenuSelection

var STRING: Array = [
	"Mario",
	"Luigi",
]

var toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")

@onready var value: Label = $HBoxContainer/Value
@onready var arrow_l: Label = $HBoxContainer/Value/arrow
@onready var arrow_r: Label = $HBoxContainer/HBoxContainer/arrow

func _ready():
	_update_string.call_deferred()


func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
	if !focused || !get_parent().focused: return
	var old_value = SettingsManager.settings.character
	
	if old_value == STRING[0]:
		SettingsManager.settings.character = STRING[1]
	elif old_value == STRING[1]:
		SettingsManager.settings.character = STRING[0]
	_toggled_option(old_value, SettingsManager.settings.character)
	#Scenes.current_scene.get_node("Window").visible = true


func _physics_process(delta: float) -> void:
	super(delta)
	
	arrow_r.visible = focused
	arrow_l.visible = focused
	
	if !get_parent().focused: return
	
	if !focused: return
	
	var old_value = SettingsManager.settings.character
	
	if Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("ui_left"):
		if old_value == STRING[0]:
			SettingsManager.settings.character = STRING[1]
		elif old_value == STRING[1]:
			SettingsManager.settings.character = STRING[0]
		_toggled_option(old_value, SettingsManager.settings.character)


func _toggled_option(old_val, new_val) -> void:
	if old_val == new_val: return
	Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
	SettingsManager._process_settings()
	_update_string()


func _update_string() -> void:
	value.text = SettingsManager.settings.character
