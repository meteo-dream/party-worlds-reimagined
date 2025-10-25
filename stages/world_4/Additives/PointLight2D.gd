extends PointLight2D
@export var rotate: bool
var frequency: float = randf_range(1.5, 3.5)
@export_range(-360, 360, 0.01, "suffix: °") var phase: float
@onready var center: Vector2 = position

func _ready():
	energy = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if energy > 0:
		energy -= 15 * delta
	if energy < 0:
		energy = 0
	if rotate == true:
		rotation = sin(phase + frequency * delta) / 1.5
		phase -= frequency * delta
