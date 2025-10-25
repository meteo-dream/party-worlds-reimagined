class_name W7Barricade
extends Node2D

var triggered
var init_position: Vector2 = position

func _physics_process(delta) -> void:
	if !triggered: return
	position -= Vector2(0.0, 1.0)
	if position.y <= -672: #use a better checking method next time, this is good enough for now
		queue_free()
