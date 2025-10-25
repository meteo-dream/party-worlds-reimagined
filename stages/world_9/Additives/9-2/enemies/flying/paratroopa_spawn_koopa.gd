extends "res://engine/objects/enemies/paratroopas/paratroopa_spawn_koopa.gd"

func _ready() -> void:
	super()
	if "life_time" in vars && node is GeneralMovementBody2D:
		node.life_time = vars.life_time
