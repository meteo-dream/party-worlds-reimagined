extends "res://engine/scripts/classes/level_cutscene/cutscenes/water_cutscene.gd"

func _physics_process(delta: float) -> void:
	super(delta)
	if player.global_position.x > 660:
		Scenes.current_scene._start_transition()
