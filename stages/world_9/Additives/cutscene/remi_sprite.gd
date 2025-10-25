extends Sprite2D

@export var amplitude: Vector2 = Vector2(0, 5)
@export_range(0, 360, 0.01, "suffix: °") var phase: float
@export var random_phase: bool:
	set(rph):
		random_phase = rph
		if random_phase:
			phase = randf_range(0, 360)
@export var frequency: float = 2

@onready var center: Vector2 = position
@onready var parent = get_parent()

var pause_hovering: bool = false

func _physics_process(delta: float) -> void:
	if pause_hovering: return
	position = Thunder.Math.oval(center, amplitude, deg_to_rad(phase))
	phase = wrapf(phase + frequency * Thunder.get_delta(delta), 0, 360)
