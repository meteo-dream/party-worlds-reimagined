extends Node2D

func _ready() -> void:
	Scenes.current_scene.get_node("MusicLoader").play_buffered()

var odd_frame: int
func _physics_process(delta: float) -> void:
	odd_frame += 1 # No delta because physics_process runs at fixed framerate
	if odd_frame % 2: return
	var mod: AudioStreamMPT
	if !Audio._music_channels.has(1): return
	if (is_instance_valid(Audio._music_channels[1]) &&
		Audio._music_channels[1].stream is AudioStreamMPT):
		mod = Audio._music_channels[1].stream
	if _null_check(mod): return
	var playback: AudioStreamPlaybackMPT = Audio._music_channels[1].get_stream_playback()
	var pattern: int = playback.get_current_pattern()
	var row: int = playback.get_current_row()
	
	#print(pattern)
	
	for i in range(mod.get_num_channels()):
		#var txt = mod.get_channel_string(pattern, i)
		#var cur_smp = txt.get_slice("\n", row).get_slice(" ", 1)
		var cur_smp: String = mod.format_pattern_row_channel_command(
			pattern, row, i, AudioStreamMPT.COMMAND_INSTRUMENT
		).to_upper()
		if i == 8 && cur_smp == "0B":
			_syncevent(1)
		if i == 0 && cur_smp == "01":
			_syncevent(2)
		if i == 5 && cur_smp == "0E":
			_syncevent(3)
		if i == 9 && cur_smp == "0B":
			_syncevent(4)
		if i == 10 && cur_smp == "0B":
			_syncevent(5)
		if i == 12 && (cur_smp == "11" || cur_smp == "0D"):
			_syncevent(6)


func _syncevent(which: int):
	for i in get_tree().get_nodes_in_group(&"sync" + str(which)):
		if i is PointLight2D:
			i.energy = 2
			i.color.s = 0.85
			i.color.h = randf_range(0, 1) 
		if i is ParallaxLayer:
			i.modulate.a = 0
		if i is Sprite2D:
			i.modulate.a = 1
			#print("sync" + str(which))
func _null_check(mod) -> bool:
	if !mod: return true
	if !is_instance_valid(mod): return true
	return false
