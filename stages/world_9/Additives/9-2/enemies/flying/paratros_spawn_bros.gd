extends "res://engine/objects/enemies/hammer_paratros/paratros_spawn_bros.gd"

func _ready() -> void:
	super()
	if "life_time" in vars && node is GeneralMovementBody2D:
		node.life_time = vars.life_time
