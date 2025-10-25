extends Node

@export var sound = preload("res://engine/objects/core/checkpoint/sounds/switch.wav")
@onready var locker_base: Node = $"../locker-base"

var has_killed_all: bool

func _physics_process(delta: float) -> void:
	var has_enemies: bool = false
	for i in get_children():
		if is_instance_valid(i):
			has_enemies = true
	
	if !has_enemies && !has_killed_all:
		has_killed_all = true
		Audio.play_1d_sound(sound)
		locker_base.queue_free()
