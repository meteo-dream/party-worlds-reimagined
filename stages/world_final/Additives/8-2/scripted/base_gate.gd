class_name GateCutscene8_2
extends StaticBody2D

@export_enum("Goes Down:0", "Goes Up:1") var gate_type: int
@onready var timer = $Timer
var distance_to_move: float = 160.0
var movement_time: float = 0.5
var initial_position: Vector2
var current_moved_distance: float = 0.0
signal finished_movement

func _ready() -> void:
	initial_position = position
	if !timer: return
	timer.timeout.connect(_on_timer_timeout)

func _physics_process(delta: float) -> void:
	if timer and !timer.is_stopped():
		position.y = initial_position.y + current_moved_distance

func execute_gate_movement() -> void:
	if !timer: return
	timer.start(movement_time)
	var final_var = distance_to_move
	if gate_type == 1: final_var = 0 - final_var
	var tw = get_tree().create_tween()
	tw.tween_property(self, "current_moved_distance", final_var, movement_time)

func _on_timer_timeout() -> void:
	finished_movement.emit()
