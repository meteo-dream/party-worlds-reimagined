extends "res://engine/objects/enemies/spikes/spike.gd"

const TRIGGER_SFX = preload("res://objects/w8_invis_spike/sounds/smw_bubble_pop.wav")
const SPIKE_SFX = preload("res://objects/w8_invis_spike/sounds/smw_chuck_whistle.wav")

var _triggered: bool = false

func _on_body_entered(body: Node2D) -> void:
	if _triggered: return
	var script = body.get_script()
	if script and script.get_global_name() == "Player":
		_triggered = true
		Audio.play_sound(TRIGGER_SFX, self)
		modulate.s = 60

func _on_body_exited(body: Node2D) -> void:
	if modulate.a >= 255: return
	var script = body.get_script()
	if script and script.get_global_name() == "Player" and _triggered:
		Audio.play_sound(SPIKE_SFX, self)
		modulate.a = 255
		modulate.s = 0
		type = 1
