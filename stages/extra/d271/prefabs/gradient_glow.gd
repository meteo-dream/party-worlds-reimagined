extends Sprite2D

var timer: float
var _off: float

func _ready() -> void:
	_set_offset()

func _physics_process(delta: float) -> void:
	timer += 4 * delta
	modulate.s = (cos(timer / 3) / 2.5) + 0.4
	modulate.a = clamp((cos(timer) / 2.5) + 0.6 + _off, 0.2, 1.0)


func _set_offset() -> void:
	_off = randf_range(-0.08, 0.08)
	await get_tree().create_timer(0.02, false).timeout
	_set_offset()
