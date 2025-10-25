extends "res://objects/boss_touhou/common/components/general_counter.gd"

var timer_value: float

func _check_timer() -> void:
	if timer_value <= 2.0:
		self.add_theme_color_override("font_color", Color.RED)
	elif timer_value <= 5.0:
		self.add_theme_color_override("font_color", Color.LIGHT_CORAL)
	else: self.add_theme_color_override("font_color", Color.WHITE)
