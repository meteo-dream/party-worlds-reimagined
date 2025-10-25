class_name AcidDrownCutsceneHandler
extends Node2D

# Enemies corroding is baked straight into the signals.
# No easy way around that.
@export_group("Cutscene Settings - Acid Pool")
@export var acid_rise_distance: float = 320.0
@export var acid_rise_time: float = 3.0
@export var delay_before_acid_rises: bool = true
@export var delay_time: float = 2.0
@export var sound_effect: AudioStream
@export_group("Cutscene Settings - Gate Details")
@export var gate_1_distance_offset: float = 0.0
@export var gate_1_time_offset: float = 0.0
@export var gate_2_distance_offset: float = 0.0
@export var gate_2_time_offset: float = 0.0
@export_group("Cutscene Settings - Player")
@export var pause_player_movement: bool = true
@export var camera_scroll_to_x_coordinate: float = 6880.0
@export var trigger_sound_effect: AudioStream
@export var turn_off_dirty_camera_hack: bool = false

@onready var acid = $AcidCutscene
@onready var timer = $Timer
@onready var unneeded = $StaticBody2D
var moved_distance: int
var initial_position: Vector2
var cam_hack_shit: float
var _triggered: bool = false
var acid_rise: bool = true
var acid_stay: bool = false
var acid_recede: bool = false
var finish_cutscene: bool = false
var cutscene_in_progress: bool = false
signal gate_adjustments
signal enemy_corrosion
signal acid_receded
signal open_second_gate

func _ready() -> void:
	gate_adjustments.emit(gate_1_distance_offset, gate_1_time_offset, gate_2_distance_offset, gate_2_time_offset)
	if !acid or !timer: return
	initial_position = acid.position
	timer.timeout.connect(_on_timer_timeout)

func _physics_process(delta: float) -> void:
	if !_triggered or finish_cutscene: return
	acid.position.y = initial_position.y - moved_distance
	
	# crutch to stop the cam from going further than needed
	var camera = Thunder._current_camera
	if !camera or turn_off_dirty_camera_hack or !cutscene_in_progress: return
	if camera.position.x < camera_scroll_to_x_coordinate:
		cam_hack_shit = camera.offset.x
	else: camera.offset.x = camera_scroll_to_x_coordinate

func _on_gate_pair_finish_first_movement() -> void:
	if delay_before_acid_rises:
		acid_rise = false
		timer.start(delay_time)
	else:
		cause_acid_rise()

func cause_acid_rise() -> void:
	_triggered = true
	acid_rise = true
	commence_tween(acid_rise_distance, acid_rise_time)
	timer.start(acid_rise_time)

func _on_timer_timeout() -> void:
	if finish_cutscene: return
	if !_triggered:
		cause_acid_rise()
		return
	if acid_rise:
		timer.start(1.0)
		enemy_corrosion.emit()
		acid_rise = false
		acid_stay = true
		return
	if acid_stay:
		acid_receded.emit()
		commence_tween(0.0, acid_rise_time)
		timer.start(acid_rise_time)
		acid_stay = false
		acid_recede = true
		return
	if acid_recede:
		end_cutscene()
		return

func end_cutscene() -> void:
	open_second_gate.emit()
	finish_cutscene = true
	cutscene_in_progress = false
	player_exits_cutscene()
	if unneeded: unneeded.queue_free()

func commence_tween(final_val: float, duration: float) -> void:
	if sound_effect:
		Audio.play_sound(sound_effect, self)
	var tw = get_tree().create_tween()
	tw.tween_property(self, "moved_distance", final_val, duration)

func player_enters_cutscene() -> void:
	var player = Thunder._current_player
	if !player: return
	if pause_player_movement: player.completed = true
	cutscene_in_progress = true
	if trigger_sound_effect:
		Audio.play_sound(trigger_sound_effect, player)
	set_camera_offset(camera_scroll_to_x_coordinate)
	return

func set_camera_offset(new_x: float, reset_camera: bool = false) -> void:
	var camera = Thunder._current_camera
	if !camera: return
	var to_x = new_x - camera.position.x
	if reset_camera: to_x = 0.0
	var tw = get_tree().create_tween()
	tw.tween_property(camera, "offset", Vector2(to_x, 0.0), delay_before_acid_rises)

func player_exits_cutscene() -> void:
	var player = Thunder._current_player
	if player and pause_player_movement: player.completed = false
	var camera = Thunder._current_camera
	set_camera_offset(0.0, true)
	return

func _on_gate_pair_player_entered() -> void:
	player_enters_cutscene()
