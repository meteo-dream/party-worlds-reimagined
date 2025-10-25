extends PathFollow2D
@onready var path_2d: Path2D = $".."
@export var move: bool
@export var speed: int = 65

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if path_2d.move == true:
		progress += speed * delta
	if progress_ratio < 0.1:
		reset_physics_interpolation()
