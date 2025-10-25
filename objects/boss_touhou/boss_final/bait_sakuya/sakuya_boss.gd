extends GravityBody2D
class_name SakuyaBoss

signal hide_door
signal reveal_door
signal sakuya_does_not_exist

var movement_tween: Tween
var direction: int
var attack_anim_ended: bool
var is_moving: bool

@export var sprite: NodePath
@onready var sprite_node: Node2D = get_node_or_null(sprite)

func _ready() -> void:
	if CharacterManager.get_character_display_name().to_lower() != "reimu":
		sakuya_does_not_exist.emit()
		queue_free()
	else:
		hide_door.emit()

func _physics_process(delta: float) -> void:
	_animation_process(delta)

func _animation_process(delta: float) -> void:
	sprite_node.flip_h = (direction < 0)

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

func move_boss_predefined() -> void:
	move_boss(Vector2(10840.0, 344.0), 1.5)

func adapt_direction(vector_x: float, force_direction_to_take: bool = false, direction_to_take: int = 1) -> void:
	if force_direction_to_take:
		direction = direction_to_take
		return
	
	if vector_x < 0: direction = 1
	else: direction = -1

func start_move_anim() -> void:
	sprite_node.play(&"move")
	is_moving = true

func end_move_anim() -> void:
	sprite_node.play(&"stop")
	is_moving = false

func start_attack_anim() -> void:
	sprite_node.play(&"attack")

func reset_to_default_anim() -> void:
	sprite_node.play(&"default")

func purged_sakuya() -> void:
	reveal_door.emit()
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		move_boss_predefined()


func _on_sprite_animation_finished() -> void:
	if sprite_node.animation == &"stop":
		adapt_direction(0.0)
		sprite_node.play(&"default")
		is_moving = false
	if sprite_node.animation == &"attack":
		attack_anim_ended = true
