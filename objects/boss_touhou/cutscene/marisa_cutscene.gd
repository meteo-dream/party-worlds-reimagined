extends AnimatedSprite2D

const SMOKE_EFF = preload("res://objects/w7_spawn_portal/smoke_effect.tscn")

var spawn_smoke_effect: bool = false

var direction: int
var is_moving: bool
var attack_anim_ended: bool
var movement_tween: Tween

func _physics_process(delta: float) -> void:
	_animation_process(delta)
	
	if spawn_smoke_effect:
		spawn_smoke_effect = false
		spawn_smoke_effect_func()

func spawn_smoke_effect_func() -> void:
	var smoke_eff = SMOKE_EFF.instantiate()
	Scenes.current_scene.add_child(smoke_eff)
	smoke_eff.z_index = z_index - 1
	smoke_eff.global_position = global_position
	smoke_eff.reset_physics_interpolation()
	await get_tree().create_timer(0.1, false, false).timeout
	spawn_smoke_effect_func()

func move_boss(destination: Vector2, duration: float = 1.0, tween_style: Tween.TransitionType = Tween.TRANS_CIRC, ease_style: Tween.EaseType = Tween.EASE_OUT) -> void:
	adapt_direction(global_position.x - destination.x)
	start_move_anim()
	if movement_tween:
		movement_tween.kill()
	movement_tween = get_tree().create_tween()
	movement_tween.set_trans(tween_style)
	movement_tween.set_ease(ease_style)
	movement_tween.set_ignore_time_scale(true)
	movement_tween.tween_property(self, "global_position", destination, duration)
	movement_tween.tween_callback(end_move_anim)
	movement_tween.parallel().emit_signal("finished_movement")

# Positive is left, negative is right
func _animation_process(delta: float) -> void:
	flip_h = false

func start_move_anim() -> void:
	if direction < 0:
		play(&"move_left")
	else:
		play(&"move_right")
	is_moving = true

func end_move_anim() -> void:
	if direction < 0:
		play(&"stop_left")
	else:
		play(&"stop_right")
	is_moving = false

func _on_boss_sprite_animation_finished() -> void:
	if animation == &"stop_left" or animation == &"stop_right":
		adapt_direction(0.0)
		play(&"default")
		is_moving = false
	if animation == &"attack":
		attack_anim_ended = true
	if animation == &"attack_prep":
		attack_anim_ended = false

func adapt_direction(vector_x: float, force_direction_to_take: bool = false, direction_to_take: int = 1) -> void:
	if force_direction_to_take:
		direction = direction_to_take
		return
	if vector_x < 0: direction = 1
	else: direction = -1
