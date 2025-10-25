extends Node2D
@export var sound: AudioStream
@onready var label_mister_earl = $"../Sign2/LabelMisterEarl"

func _on_area_2d_player_enter():
	Audio.play_sound(sound, self)
	Thunder.add_lives(1)
	label_mister_earl.text = String('very tasty!!! wow!!!!!')
	queue_free()
