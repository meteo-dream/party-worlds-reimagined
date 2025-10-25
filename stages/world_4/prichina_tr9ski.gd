extends Node2D

@export var speed = 50
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta) -> void:
	var player = Thunder._current_player
	if global_position.y > 1888 && player:
		global_position.y -= speed * delta
