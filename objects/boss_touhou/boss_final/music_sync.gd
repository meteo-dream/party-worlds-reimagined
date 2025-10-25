extends Node
class_name MusicSync

const end_battle_position: int = 43
var excluded_positions: Array[int]
var channel_to_check: int
var note_to_check: String = "C-05"
var old_position: int = 0
var is_boss_here: bool = false

signal progress_to_next_phase
signal force_end_battle

func _boss_show_up() -> void:
	is_boss_here = true

func _physics_process(delta: float) -> void:
	if !is_boss_here: return
	
	var mod: AudioStreamMPT
	if !Audio._music_channels.has(32): return
	if (is_instance_valid(Audio._music_channels[32]) &&
		Audio._music_channels[32].stream is AudioStreamMPT):
		mod = Audio._music_channels[32].stream
	if _null_check(mod): return
	var playback: AudioStreamPlaybackMPT = Audio._music_channels[32].get_stream_playback()
	#if !playback or !is_instance_valid(playback): return
	if !is_instance_valid(playback): return
	if _music_phase_change_check(mod, playback):
		progress_to_next_phase.emit()

func _music_phase_change_check(mod: AudioStreamMPT, playback: AudioStreamPlaybackMPT) -> bool:
	var pattern = playback.get_current_pattern()
	var row = playback.get_current_row()
	var mod_position = playback.get_current_order()
	if mod_position >= end_battle_position:
		force_end_battle.emit()
		return false
	var cur_smp: String
	if channel_to_check > 0:
		for i in range(mod.get_num_channels()):
			cur_smp = mod.format_pattern_row_channel_command(
				pattern, row, i, AudioStreamMPT.COMMAND_NOTE
				).to_upper()
	
	# Position exclusion.
	if excluded_positions.has(mod_position): return false
	if cur_smp == note_to_check: # Using channel for more precise checking
		if old_position < mod_position:
			old_position = mod_position
		return true
	elif old_position < mod_position:
		old_position = mod_position
		return true
	return false

func _null_check(mod) -> bool:
	if !mod: return true
	if !is_instance_valid(mod): return true
	return false
