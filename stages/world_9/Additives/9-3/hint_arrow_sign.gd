extends Sprite2D

func _ready() -> void:
	if !CustomGlobals.w9b_get_hint_visibility():
		queue_free()
		return
