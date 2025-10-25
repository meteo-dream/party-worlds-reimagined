extends BulletBase

@export var bouncy: bool = false
@export var bounce_once: bool = false
var anchor_for_bounce: Vector2 = Vector2.ZERO
var bounce_range_min: Vector2
var bounce_range_max: Vector2

func _ready() -> void:
	super()
	bounce_range_min = Vector2(anchor_for_bounce.x - 320.0, anchor_for_bounce.y - 240.0)
	bounce_range_max = Vector2(anchor_for_bounce.x + 320.0, anchor_for_bounce.y + 240.0)

func _physics_process(delta: float) -> void:
	super(delta)
	if !allow_movement or !bouncy: return
	if global_position.x <= bounce_range_min.x:
		actual_vel.x = absf(actual_vel.x)
		_bounce_triggered()
	if global_position.x >= bounce_range_max.x:
		actual_vel.x = absf(actual_vel.x) * -1.0
		_bounce_triggered()
	if global_position.y <= bounce_range_min.y:
		actual_vel.y = absf(actual_vel.y)
		_bounce_triggered(true)

func _bounce_triggered(hit_ceiling: bool = false) -> void:
	if bounce_once and !hit_ceiling: bouncy = false
