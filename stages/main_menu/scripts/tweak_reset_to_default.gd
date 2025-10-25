extends MenuSelection

@onready var valu = get_node_or_null(^"Value")
var _timer: float

func _physics_process(delta: float) -> void:
	super(delta)
	if !valu:
		return
	if focused:
		_timer += delta * 10
		valu.modulate.a = min((cos(_timer) / 2.5) + 0.6, 1.0)
	else:
		valu.modulate.a = 0.0

func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
