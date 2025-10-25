class_name GatePair
extends Node2D

@export var is_part_of_a_cutscene: bool = false
@export_group("Change Gate Details")
@export var gate_1_distance_offset: float = 0.0
@export var gate_1_time_offset: float = 0.0
@export var gate_2_distance_offset: float = 0.0
@export var gate_2_time_offset: float = 0.0
@onready var gate1 = $BaseGate
@onready var gate2 = $BaseGate2
var _triggered: bool = false
var gate1closed = false

signal player_entered
signal finish_first_movement

func _ready() -> void:
	gate_adjustments(gate_1_distance_offset, gate_1_time_offset, gate_2_distance_offset, gate_2_time_offset)

func _on_player_detector_body_entered(body: Node2D) -> void:
	var script = body.get_script()
	if script and script.get_global_name() == "Player":
		trigger_gates()

func trigger_gates() -> void:
	if _triggered: return
	player_entered.emit()
	gate1.execute_gate_movement()
	_triggered = true
	if is_part_of_a_cutscene: return
	gate2.execute_gate_movement()

func gate_adjustments(offset1: float, time1: float, offset2: float, time2: float) -> void:
	gate1.distance_to_move += offset1
	gate1.movement_time += time1
	gate2.distance_to_move += offset2
	gate2.movement_time += time2

func _on_base_gate_finished_movement() -> void:
	if !is_part_of_a_cutscene or gate1closed: return
	gate1closed = true
	finish_first_movement.emit()


func _on_acid_drown_cutscene_handler_open_second_gate() -> void:
	gate2.execute_gate_movement()


func _on_acid_drown_cutscene_handler_gate_adjustments(offset1: float, time1: float, offset2: float, time2: float) -> void:
	if !gate1 or !gate2: return
	gate_adjustments(offset1, time1, offset2, time2)
