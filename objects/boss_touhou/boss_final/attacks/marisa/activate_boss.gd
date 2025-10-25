extends BossSpellcardFinal

# Comes in at position 21, row 96
func easy_setup_boss_enter() -> void:
	change_boss_name(1)
	var old_pos = boss.starting_position
	if boss.boss_handler:
		old_pos = boss.boss_handler.global_position
	var new_x = 0.0
	var new_y = -150.0
	move_boss(old_pos + Vector2(new_x, new_y), 1.0)
	boss.finished_init = true
	await _set_timer(0.2)
	boss.magic_circle_effect.appear_animation()
	play_sound(boss.long_charge_up)
	await _set_timer(0.8)
	play_sound(boss.short_charge_up)
	leaf_gather_effect()
	await _set_timer(1.3)
