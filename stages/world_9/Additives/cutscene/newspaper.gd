extends Sprite2D

var velocity: float = 600.0
var angle: float
var travel_speed: Vector2

var stop_moving: bool = false

func _ready() -> void:
	travel_speed = Vector2(velocity * cos(angle), velocity * sin(angle))

func _physics_process(delta: float) -> void:
	if stop_moving: return
	global_position += travel_speed * delta
	rotation += deg_to_rad(1300.0) * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
