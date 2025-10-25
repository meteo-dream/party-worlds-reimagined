extends BossSpellcard
class_name BossSpellcardFinal

@export var is_new_spell_card: bool = false
@export var next_attack_will_be_new: bool = false
@export var end_spell_card_afterwards: bool = false
@export var player_should_get_pity_afterwards: bool = false
var patchouli_sprite: PatchouliBoss

func start_attack() -> void:
	boss.receive_spell_card_info(spellcard_name, spellcard_time, is_spell_card, !is_new_spell_card)
	start.emit()
	if is_spell_card and is_new_spell_card: boss.spawn_spell_ring_effect()
	if boss.finished_init:
		middle_attack()
		return
	await easy_setup_boss_enter()
	middle_attack()

func middle_attack() -> void:
	boss.next_attack_is_new = next_attack_will_be_new
	boss.player_should_get_pity = player_should_get_pity_afterwards
	super()

func end_attack() -> void:
	restore_time()
	if boss.boss_sprite.animation == &"attack":
		reset_boss_anim()
	if boss.player_should_get_pity:
		boss._danmaku_clear_screen()
		player_gain_pity("green_lui")
	end_attack_global()
	end.emit()

func end_attack_global() -> void:
	if !boss.keep_sc_bg and end_spell_card_afterwards:
		boss.request_hide_spellcard.emit()
		boss.delete_spell_ring_effect()

func easy_setup_boss_enter() -> void:
	var old_pos = boss.starting_position
	if boss.boss_handler:
		old_pos = boss.boss_handler.global_position
	var new_x = 0.0
	var new_y = -150.0
	move_boss(old_pos + Vector2(new_x, new_y), 1.0)
	await _set_timer(0.2, true)
	boss.finished_init = true
	boss.magic_circle_effect.appear_animation()
	play_sound(boss.long_charge_up)
	await _set_timer(0.8, true)
	play_sound(boss.short_charge_up)
	leaf_gather_effect()
	await _set_timer(1.3)

func boss_to_default_start_pos() -> void:
	move_boss(boss.boss_handler.global_position + Vector2(0.0, -160.0))

func add_support_platforms() -> void:
	boss._summon_support_platforms()

func hide_support_platforms() -> void:
	boss._hide_support_platforms()

func change_boss_name(type: int = 0) -> void:
	boss._change_boss_name(type)

func move_boss_chase_narrow(init_pos: Vector2, flare_aura: bool = false) -> void:
	if _boss_attack_interrupt(): return
	if flare_aura: boss_nice_aura()
	var upper_bound = Vector2(120.0, -80.0)
	var lower_bound = Vector2(-120.0, -180.0)
	var anchor: Vector2 = boss.boss_handler.global_position
	if init_pos.x <= anchor.x:
		anchor.x -= 160.0
	else:
		anchor.x += 160.0
	move_boss_wander(Wander_Type.RANDOM, anchor, upper_bound, lower_bound, randf_range(90.0, 230.0), 1.2)
