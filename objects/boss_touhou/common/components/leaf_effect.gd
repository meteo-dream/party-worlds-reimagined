extends Sprite2D

## The Vector2 where it stops.
@export var destination: Vector2
@export var duration: float = 1.0
@export_enum("Gather:0", "Spread:1") var effect_type: int = 0
var direction: int = 1
const small_scale = Vector2(0.05, 0.05)

func _ready() -> void:
	visible = false
	modulate.a = 0.0

func do_movement() -> void:
	visible = true
	if destination.x < global_position.x: direction = -1
	
	if effect_type == 0:
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 0.2)
		tw.parallel().tween_property(self, "global_position", destination, duration)
		tw.tween_property(self, "modulate:a", 0.0, 0.1)
		tw.tween_callback(queue_free)
		var tw2 = create_tween()
		tw2.set_trans(Tween.TRANS_EXPO)
		tw2.set_ease(Tween.EASE_IN)
		tw2.tween_property(self, "scale", small_scale, duration)
	else:
		var new_scale = scale
		scale = small_scale
		modulate.a = 1.0
		var tw = create_tween()
		tw.tween_property(self, "global_position", destination, duration)
		tw.parallel().tween_property(self, "modulate:a", 0.0, duration / 2)
		tw.tween_callback(queue_free)
		var tw2 = create_tween()
		tw2.set_trans(Tween.TRANS_EXPO)
		tw2.set_ease(Tween.EASE_OUT)
		tw2.tween_property(self, "scale", new_scale, duration)

func _physics_process(delta: float) -> void:
	rotate(0.15 * direction)
