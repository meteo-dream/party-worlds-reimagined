extends CanvasLayer
class_name TouhouDialogueBalloon
## A basic dialogue balloon for use with Dialogue Manager.

## The action to use for advancing the dialogue
@export var next_action: StringName = &"m_jump"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"m_jump"

## The action to use to skip the entire dialogue
@export var skip_dialogue: StringName = &"m_extra"

@export var dialogue_action_sound: AudioStream

## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()

var is_in_dialogue_mode: bool = false

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			hide_balloon()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

@onready var balloon_bg: Sprite2D = $Sprite2D
@onready var skip_text: Label = $Label
@onready var boss_title: RichTextLabel = $RemiTitle
var boss_title_hiding: bool = false

func _ready() -> void:
	balloon.hide()
	balloon_bg.hide()
	skip_text.hide()
	boss_title.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)
	
	is_in_dialogue_mode = false


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	balloon.grab_focus()
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio = dialogue_label.visible_ratio
		self.dialogue_line = await resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	show_balloon(0.3)
	is_in_dialogue_mode = true
	await get_tree().create_timer(0.25, false).timeout
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for input
	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	if !is_in_dialogue_mode: return
	
	var skip_dialog_pressed: bool = event.is_action_pressed(skip_dialogue)
	if skip_dialog_pressed:
		get_viewport().set_input_as_handled()
		hide_boss_title()
		var skip_to_line: String = "27"
		if CharacterManager.get_character_display_name().to_lower() == "reimu":
			skip_to_line = "28"
		next(skip_to_line)
		return
	
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
		Audio.play_sound(dialogue_action_sound, Thunder._current_player)
		return
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)
		Audio.play_sound(dialogue_action_sound, Thunder._current_player)
		return


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)

func show_balloon(time: float = 0.5) -> void:
	if !is_instance_valid(balloon_bg): return
	balloon_bg.show()
	var tw = get_tree().create_tween()
	tw.tween_property(balloon_bg, "scale:x", 2.1, time)
	if is_instance_valid(skip_text):
		skip_text.modulate.a = 0.0
		skip_text.show()
		tw.parallel().tween_property(skip_text, "modulate:a", 1.0, time)

func hide_balloon() -> void:
	is_in_dialogue_mode = false
	if !is_instance_valid(balloon_bg): delete_self()
	var tw = get_tree().create_tween()
	tw.tween_property(balloon_bg, "scale:x", 0.0, 0.15)
	if is_instance_valid(skip_text):
		tw.parallel().tween_property(skip_text, "modulate:a", 0.0, 0.15)
	tw.tween_callback(delete_self)

func delete_self() -> void:
	queue_free()

func show_boss_title() -> void:
	if !is_instance_valid(boss_title): return
	boss_title.modulate.a = 0.0
	boss_title.show()
	var tw = get_tree().create_tween()
	tw.tween_property(boss_title, "modulate:a", 1.0, 0.5)
	tw.tween_interval(5.0)
	tw.tween_callback(hide_boss_title)

func hide_boss_title() -> void:
	if boss_title_hiding or !is_instance_valid(boss_title): return
	boss_title_hiding = true
	var tw = get_tree().create_tween()
	tw.tween_property(boss_title, "modulate:a", 0.0, 0.3)

#endregion
