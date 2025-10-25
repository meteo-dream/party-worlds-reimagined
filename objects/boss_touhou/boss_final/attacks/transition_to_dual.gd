extends BossSpellcardFinal

const offset_vector: Vector2 = Vector2(192.0, -110.0)

@export var is_side_boss: bool = false
@export var move_time_sec: float = 1.5
@export var prep_For_final: bool = false

func start_attack() -> void:
	super()
	move_boss_predefined()
	
	if !is_side_boss:
		boss.finished_init = true
		if !prep_For_final: change_boss_name(3)
		await _set_timer(0.5, true)
		boss.magic_circle_effect.appear_animation()
		play_sound(boss.long_charge_up)
		await _set_timer(0.8, true)
		play_sound(boss.short_charge_up, boss, true)
		leaf_gather_effect()
		await _set_timer(1.2)
		if !prep_For_final: boss.boss_handler.phase_progression()
	else:
		await _set_timer(1.3, true)
		play_sound(boss.short_charge_up, boss, true)
		leaf_gather_effect()
		await _set_timer(1.2)

func move_boss_predefined() -> void:
	var anchor: Vector2 = boss.boss_handler.global_position
	var new_pos: Vector2 = anchor + offset_vector
	
	var the_player = Thunder._current_player
	if the_player.global_position.x <= anchor.x:
		if !is_side_boss:
			new_pos.x = anchor.x + offset_vector.x
		else:
			new_pos.x = anchor.x - offset_vector.x
	if the_player.global_position.x > anchor.x:
		if !is_side_boss:
			new_pos.x = anchor.x - offset_vector.x
		else:
			new_pos.x = anchor.x + offset_vector.x
	
	move_boss(new_pos, move_time_sec, Tween.TransitionType.TRANS_CIRC, Tween.EaseType.EASE_OUT, true)

func DEBUG_announce_music() -> void:
	var mod: AudioStreamMPT
	if !Audio._music_channels.has(32): return
	if (is_instance_valid(Audio._music_channels[32]) &&
		Audio._music_channels[32].stream is AudioStreamMPT):
		mod = Audio._music_channels[32].stream
	if _null_check(mod): return
	var playback: AudioStreamPlaybackMPT = Audio._music_channels[32].get_stream_playback()
	#if !playback or !is_instance_valid(playback): return
	if !is_instance_valid(playback): return
	print("Position: " + str(playback.get_current_order()) + "and row: " + str(playback.get_current_row()))

func _null_check(mod) -> bool:
	if !mod: return true
	if !is_instance_valid(mod): return true
	return false
