class_name Autoscroll_Tank
extends "res://engine/objects/players/player_camera_autoscroll.gd"

@export var speed_changes: Array[int] = [200, 300, 200, 300, 200, 100]
@export var use_markers_instead: bool = true
@export var speed_change_markers: Array[Marker2D]

var _cam_parent
var speed_up1: bool = false
var speed_up2: bool = false
var slow_down: bool = false
var speed_up3: bool = false
var stop_fetching_music: bool = false

signal speed_change

func _on_scroll_stopped() -> void:
	var cam: Camera2D = Thunder._current_camera
	if cam:
		_cam_parent = cam.get_parent()
		cam.reparent(Scenes.current_scene)
		cam.par = cam.get_parent()
		cam.force_update_transform()
		cam.reset_physics_interpolation()
		cam.force_update_scroll()
	var music: AudioStreamPlayer = Audio._music_channels.get(1)
	if !music: return
	Audio.fade_music_1d_player(music, -60, 2.8, Tween.TRANS_LINEAR, true)
	stop_fetching_music = true

func _physics_process(delta: float) -> void:
	super(delta)
	if stop_fetching_music: return
	var player_audio: AudioStreamPlayer = Audio._music_channels.get(1)
	if !player_audio: return
	if !speed_up1 and _speed_change_condition_check():
		tween_speed(speed_changes[0], 0.5)
		speed_change.emit(speed_changes[0])
		speed_up1 = true
	if !speed_up2 and _speed_change_condition_check(1):
		tween_speed(speed_changes[1], 0.8)
		speed_change.emit(speed_changes[1])
		speed_up2 = true
	if !slow_down and _speed_change_condition_check(2):
		tween_speed(speed_changes[2], 1.0)
		speed_change.emit(speed_changes[2])
		slow_down = true
	if !speed_up3 and _speed_change_condition_check(3):
		tween_speed(speed_changes[3], 0.8)
		speed_change.emit(speed_changes[3])
		speed_up3 = true
	if position.x >= 28000 and speed >= 400:
		tween_speed(speed_changes[4], 1.0)
		speed_change.emit(speed_changes[4])
	if position.x >= 29000 and speed >= 200:
		tween_speed(speed_changes[5], 1.0)
		speed_change.emit(speed_changes[5])

func _speed_change_condition_check(type: int = 0) -> bool:
	var result: bool = false
	var player_audio: AudioStreamPlayer = Audio._music_channels.get(1)
	if !player_audio: use_markers_instead = true
	if use_markers_instead and is_instance_valid(speed_change_markers[type]):
			if global_position.x >= speed_change_markers[type].global_position.x: result = true
	elif player_audio:
		match type:
			0: if player_audio.get_playback_position() >= 31.226: result = true
			1: if player_audio.get_playback_position() >= 40.687: result = true
			2: if player_audio.get_playback_position() >= 79.351: result = true
			3: if player_audio.get_playback_position() >= 88.852: result = true
			_:
				print("not valid input wtf")
				result = false
	return result

func tween_speed(new_speed: int, tween_time: float) -> void:
	var tw = get_tree().create_tween()
	tw.tween_property(self, "speed", new_speed, tween_time)
