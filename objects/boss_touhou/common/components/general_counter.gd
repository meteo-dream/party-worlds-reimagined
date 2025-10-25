extends Label

var text_template: String

func _ready() -> void:
	modulate.a = 0.0
	text_template = text

func appear() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func disappear() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
