extends "res://objects/boss_touhou/boss_final/kevin_marisa/minion/magic_circle_orbit_option.gd"

# Manual control magic circle.
@export var forced_shoot_angle: float = 0.0

func _ready() -> void:
	disable_secondary_shot = true
	super()

func _shoot_wait(time: float) -> void:
	return

func do_orbit_escape() -> void:
	return

func _get_bullet_angle() -> float:
	return forced_shoot_angle

func turn_on_shooting() -> void:
	begin_shooting = true

func turn_off_shooting() -> void:
	begin_shooting = false

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	has_left_the_screen = false
