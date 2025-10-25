extends "res://stages/world_final/Additives/8-1/left_jumping_cheeps_generator.gd"

var pathfollow

func _ready() -> void:
	super()
	var current_scene = Scenes.current_scene
	var path2d = current_scene.get_child(2)
	if path2d: pathfollow = path2d.get_child(0)

func _physics_process(delta: float) -> void:
	if pathfollow.progress_ratio >= 0.98:
		disable()
		return
	
	var player_audio = Audio._music_channels.get(1)
	if !player_audio or !pathfollow: return
	if !enabled and player_audio.get_playback_position() >= 20.0 and pathfollow.progress_ratio < 0.98:
		enable()


func _on_path_follow_2d_speed_change(new_speed: int) -> void:
	speed_min.x = new_speed + 6
	speed_max.x = speed_min.x + 300
