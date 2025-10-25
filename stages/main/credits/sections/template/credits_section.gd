extends Node2D
class_name CreditsSection

@export var appear_time_sec: float = 1.0
@export var life_time_sec: float = 7.0
@export var disappear_time_sec: float = 1.0

func _ready() -> void:
	hide()
	modulate.a = 0.0

## The main content of the section. This is essentially everything it'll do while on-screen.
func _do_appear_animation() -> void:
	show()
	var tw = get_tree().create_tween()
	tw.tween_property(self, "modulate:a", 1.0, appear_time_sec)
	await get_tree().create_timer(appear_time_sec + life_time_sec, false, false).timeout
	var tw2 = get_tree().create_tween()
	tw2.tween_property(self, "modulate:a", 0.0, disappear_time_sec)
