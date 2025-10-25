extends SpellCardCutin
class_name SpellCardCutinFinal

@export var alt_portrait: Resource
var use_alt_portrait: bool = false

func _ready() -> void:
	if use_alt_portrait and alt_portrait: texture = alt_portrait
	super()
