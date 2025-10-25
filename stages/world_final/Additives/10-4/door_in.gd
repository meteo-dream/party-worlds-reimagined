extends "res://engine/objects/warps/door/door_in.gd"

const TELEPORT_SFX = preload("res://stages/world_final/Additives/10-4/sm64_warp.wav")

func teleport_somewhere() -> void:
	global_position = Vector2(-100.0, 0.0)
	reset_physics_interpolation()

func reset_position() -> void:
	modulate.a = 0.0
	global_position = Vector2(10768.0, 384.0)
	reset_physics_interpolation()
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.5)
	Audio.play_sound(TELEPORT_SFX, self)
