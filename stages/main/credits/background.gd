extends Node2D

func _ready():
	modulate.a = 0

func _physics_process(delta):
	if modulate.a <= 255:
		modulate.a += 2
