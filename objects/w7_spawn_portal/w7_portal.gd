class_name W7Portal
extends Node2D

var smoke_effect = preload("res://objects/w7_spawn_portal/smoke_effect.tscn")
@onready var animated_sprite_2d = $AnimatedSprite2D
@export var spawn_table: Array[InstanceNode2D]
@export var sounds: AudioStream

func _ready():
	animated_sprite_2d.frame = randi_range(0, 3)

func spawn_enemy() -> void:
	var enemy
	
	if spawn_table:
		enemy = spawn_table[randi_range(1, spawn_table.size() - 1)]
		NodeCreator.prepare_ins_2d(enemy, self).create_2d().execute_instance_script()
	NodeCreator.prepare_ins_2d(spawn_table[0], self).create_2d().execute_instance_script()
	Audio.play_sound(sounds, self)
