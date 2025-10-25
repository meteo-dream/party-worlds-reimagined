extends Node

func _on__level_completed() -> void:
	CustomGlobals.save_boss_status_w9(CustomGlobals.w9_alt_boss)
