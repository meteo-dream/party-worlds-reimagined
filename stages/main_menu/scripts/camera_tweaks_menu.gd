extends "res://engine/scenes/main_menu/scripts/opt_camera_2d.gd"

@export var margin: int = 24

func _ready() -> void:
	super()
	@warning_ignore("narrowing_conversion")
	limit_bottom = (margin * 2) + menu_controller.size.y


func update_limit() -> void:
	@warning_ignore("narrowing_conversion")
	limit_bottom = (margin * 2) + menu_controller.size.y
