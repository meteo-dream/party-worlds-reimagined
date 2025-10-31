extends "res://modules/music_overlay/music_overlay.gd"

var touhou_song: String = tr("ZUN - YOUKAI MOUNTAIN ~ MYSTERIOUS MOUNTAIN (LINDH0LM SM64 COVER)")

func _ready() -> void:
	display_text = touhou_song

func play(index: int = 0) -> void:
	if index == 0: return
	super(index - 1)
