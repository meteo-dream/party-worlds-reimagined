extends Sprite2D
class_name SpellCardCutin

var starting_pos: Vector2
var target_pos: Vector2
var disappear_eff: bool = false

func _ready() -> void:
	position = starting_pos
	reset_physics_interpolation()
	var original_alpha = modulate.a
	modulate.a = 0.0
	var tw_mod = get_tree().create_tween()
	tw_mod.tween_property(self, "modulate:a", original_alpha, 0.4)
	var tw = get_tree().create_tween()
	tw.set_trans(Tween.TRANS_CIRC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", target_pos, 0.6)
	await get_tree().create_timer(0.8, false).timeout
	disappear_eff = true
	var tw2 = get_tree().create_tween()
	tw2.tween_property(self, "modulate:a", 0.0, 0.5)
	tw2.tween_callback(_delete_self)

func _physics_process(delta: float) -> void:
	if disappear_eff:
		scale += Vector2(0.02, 0.02)

func _delete_self() -> void: queue_free()
