extends "res://modules/music_overlay/music_overlay.gd"

func play(index: int = 0) -> void:
	if index == 0:
		display_text = tr("Banana (Christof Mühlan) - Echoing (Looper231 Cover)")
	else:
		display_text = tr("Koji Kondo - Athletic (Yoshi's Island)")
	
	super(index)

func play_bonus() -> void:
	play(1)

func play_normal() -> void:
	play(0)
