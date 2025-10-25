extends Node2D

@export var desired_x_scale: float = 32.0
@export var anchor_node: Node2D
@export var target_position: Vector2

func _ready() -> void:
	start_growing()

func start_growing() -> void:
	scale.x = 0.0
	var tw = get_tree().create_tween()
	tw.tween_property(self, "scale:x", desired_x_scale, 0.6)

func _physics_process(delta: float) -> void:
	global_rotation = global_position.angle_to_point(target_position)
	if is_instance_valid(anchor_node):
		global_position = anchor_node.global_position
		reset_physics_interpolation()

func delete_self() -> void:
	queue_free()
