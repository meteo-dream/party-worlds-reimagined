extends Node2D
@export var sound: AudioStream
@export_range(-5, 5, 0.5) var Volume: float

func _ready():
	Audio.play_sound(sound, self)
