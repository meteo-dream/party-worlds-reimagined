class_name TankWheel
extends StaticBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func speed_up() -> void:
	animated_sprite.speed_scale += 0.5

func slow_down() -> void:
	animated_sprite.speed_scale -= 0.5

func reset_speed() -> void:
	animated_sprite.speed_scale = 1.0

func stop_rolling() -> void:
	animated_sprite.speed_scale = 0.0
