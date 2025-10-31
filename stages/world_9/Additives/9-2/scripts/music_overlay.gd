extends "res://modules/music_overlay/music_overlay.gd"

var touhou_song: String = tr("ZUN - FALL OF FALL ~ AUTUMNAL WATERFALL (WAKANA SMW-STYLE COVER)")

func _ready() -> void:
	display_text = touhou_song
	super()
