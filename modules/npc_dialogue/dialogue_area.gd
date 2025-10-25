extends Area2D

signal dialogued
signal dialogue_changed(to: int)
signal dialogue_finished

@export_multiline var dialogues: Array[String] = [""]
@export var dialogue_completion_seconds: Array[float] = [2]
@export var dialogue_display_duration: Array[float] = [5]
@export var dialogue_sound: Array[AudioStream]
@export var dialogue_fade_out: bool = true
@export var icon: Texture

var player: Player
var tween: Tween

@onready var dialogue: Label = $Dialogue


func _ready() -> void:
	body_entered.connect(
		func(body: Node2D) -> void:
			if body != Thunder._current_player:
				return
			player = body
	)
	body_exited.connect(
		func(body: Node2D) -> void:
			if body != Thunder._current_player:
				return
			player = null
			if tween:
				tween.kill()
				tween = null
			dialogue.text = ""
			dialogue.visible_ratio = 0
			dialogue_finished.emit()
	)


func _input(event: InputEvent) -> void:
	if player && event.is_action_pressed(player.control.up):
		if tween:
			tween.kill()
		
		dialogued.emit()
		dialogue.visible_ratio = 0
		dialogue.text = dialogues[0]
		if !dialogue_sound.is_empty() && dialogue_sound[0]:
			Audio.play_sound(dialogue_sound[0], self, false)
		
		tween = create_tween()
		for i in dialogues.size():
			tween.tween_callback(
				func() -> void:
					dialogue_changed.emit(i)
			)
			tween.tween_property(dialogue, "visible_ratio", 1, dialogue_completion_seconds[i])
			tween.tween_interval(dialogue_display_duration[i])
			tween.tween_callback(
				func() -> void:
					if i < dialogues.size() - 1:
						dialogue.text = dialogues[i + 1]
						dialogue.visible_ratio = 0
						if !dialogue_sound.is_empty() && dialogue_sound[i + 1]:
							Audio.play_sound(dialogue_sound[i], self, false)
					elif dialogue_fade_out:
						dialogue.text = ""
						tween.kill()
						tween = null
						dialogue_finished.emit()
			)
