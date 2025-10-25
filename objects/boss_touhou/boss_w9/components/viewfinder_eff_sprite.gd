extends Sprite2D

@export_group("Viewfinder Pulse")
@export var scale_min: Vector2 = Vector2(1.2, 1.2)
@export var scale_max: Vector2 = Vector2(1.3, 1.3)
@export_range(0, 360, 0.01, "suffix: °") var phase: float
@export var random_phase: bool:
	set(rph):
		random_phase = rph
		if random_phase:
			phase = randf_range(0, 360)
@export var frequency: float = 4.0

func _physics_process(delta: float) -> void:
	var scale_calc = Thunder.Math.oval(scale_min, scale_max - scale_min, deg_to_rad(phase))
	scale = Vector2(scale_calc.x, scale_calc.x)
	phase = wrapf(phase + frequency * Thunder.get_delta(delta), 0, 360)
