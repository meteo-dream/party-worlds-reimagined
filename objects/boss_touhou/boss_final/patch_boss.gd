extends AnimatedSprite2D
class_name PatchouliBoss

const LEAF_EFFECT_SUMMON = preload("res://objects/boss_touhou/common/components/summon_leaf_effect.tscn")

@export var short_charge_up: AudioStream
@export var is_used_in_cutscene: bool = false
@export_group("W1-4 Cutscene", "w14_")
@export var w14_move_to_position: Vector2 = Vector2.ZERO
@export_group("W3-4 Cutscene", "w34_")
@export var w34_spawn_leaf_elsewhere: bool = false
@export var w34_spawn_leaf_position: Vector2 = Vector2.ZERO

var movement_tween: Tween
var direction: int
var attack_anim_ended: bool
var is_moving: bool

signal summoned_sub_boss

func special_summon_sub_boss(sub_boss: Node2D) -> void:
	#if is_used_in_cutscene: return
	start_attack_anim()
	leaf_gather_effect(1.8)
	Audio.play_sound(short_charge_up, self)
	await get_tree().create_timer(2.0, false, false, true).timeout
	if is_instance_valid(sub_boss):
		sub_boss.global_position = global_position
		sub_boss.reset_physics_interpolation()
		sub_boss.summon_animation_and_process()
	summoned_sub_boss.emit()
	await get_tree().create_timer(0.5, false, false, true).timeout
	var target_destination = global_position - Vector2(450.0, -50.0)
	move_boss(target_destination, 1.2, Tween.TRANS_CIRC, Tween.EASE_IN)
	await get_tree().create_timer(1.8, false).timeout
	queue_free()

func SPECIAL_do_w1_cutscene() -> void:
	if !is_used_in_cutscene: return
	move_boss(w14_move_to_position, 2.0)
	await get_tree().create_timer(3.5, false, false).timeout
	move_boss(w14_move_to_position - Vector2(640.0, -90.0), 1.5, Tween.TRANS_CIRC, Tween.EASE_IN)

func SPECIAL_do_w3_cutscene(set_position: Vector2) -> void:
	if !is_used_in_cutscene: return
	move_boss(set_position, 2.0)
	await get_tree().create_timer(3.5, false, false).timeout
	start_attack_anim()
	Audio.play_sound(short_charge_up, self)
	leaf_gather_effect(1.2)

func _physics_process(delta: float) -> void:
	_animation_process(delta)

func _animation_process(delta: float) -> void:
	flip_h = (direction < 0)

func leaf_gather_effect(duration: float = 1.2, distance: float = 220.0, amount: int = 120, travel_time: float = 0.6, frequency: int = 1, effect_type: int = 0, endseq: bool = false, all_at_once: bool = false) -> void:
	var leaf_effect_control = LEAF_EFFECT_SUMMON.instantiate()
	if endseq or (w34_spawn_leaf_elsewhere and is_used_in_cutscene): Scenes.current_scene.add_child(leaf_effect_control)
	else: add_child(leaf_effect_control)
	leaf_effect_control.global_position = global_position
	if w34_spawn_leaf_elsewhere and is_used_in_cutscene:
		leaf_effect_control.global_position = w34_spawn_leaf_position
	leaf_effect_control.reset_physics_interpolation()
	leaf_effect_control.z_index = z_index - 1
	leaf_effect_control.duration = duration
	leaf_effect_control.distance_from_center = distance
	leaf_effect_control.amount_of_effect_max = amount
	leaf_effect_control.effect_travel_time = travel_time
	leaf_effect_control.frequency = frequency
	leaf_effect_control.effect_type = effect_type
	leaf_effect_control.spawn_all_at_once = all_at_once
	leaf_effect_control.countdown_started = true

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

func adapt_direction(vector_x: float, force_direction_to_take: bool = false, direction_to_take: int = 1) -> void:
	if force_direction_to_take:
		direction = direction_to_take
		return
	
	if vector_x < 0: direction = 1
	else: direction = -1

func start_move_anim() -> void:
	play(&"move")
	is_moving = true

func end_move_anim() -> void:
	play(&"stop")
	is_moving = false

func start_attack_anim() -> void:
	play(&"attack")

func reset_to_default_anim() -> void:
	play(&"default")

func _on_animation_finished() -> void:
	if animation == &"stop":
		adapt_direction(0.0)
		play(&"default")
		is_moving = false
	if animation == &"attack":
		attack_anim_ended = true
