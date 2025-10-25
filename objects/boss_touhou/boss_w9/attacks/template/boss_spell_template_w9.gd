extends BossSpellcard
class_name BossSpellcardW9

const VIEWFINDER_EFF = preload("res://objects/boss_touhou/boss_w9/components/viewfinder_eff.tscn")

var boss_viewfinder_warning: ViewfinderEff
var hatate_attack_anim_played: bool = false

func start_attack() -> void:
	if is_spell_card: boss.spawn_spell_ring_effect()
	if boss.finished_init:
		middle_attack()
		super()
		return
	await easy_setup_boss_enter()
	middle_attack()
	super()

# End pattern (normally)
func end_attack() -> void:
	restore_time()
	if boss.boss_sprite.animation == &"attack":
		reset_boss_anim()
	if boss.current_spell_index < boss.max_number_of_spellcards + 1:
		player_gain_pity()
	end_attack_global()
	end.emit()

# Forcibly end the pattern due to player death, etc.
func force_end_attack() -> void:
	boss.keep_sc_bg = false
	end_attack_global()
	forced_end.emit()

# Called by both methods of ending an attack
func end_attack_global() -> void:
	delete_aim_eff()
	boss.delete_spell_ring_effect()
	super()

func easy_setup_boss_enter() -> void:
	spellcard_time += 3.0
	var old_pos = boss.starting_position
	if boss.boss_handler:
		old_pos = boss.boss_handler.global_position
	var new_x = 0.0
	var new_y = -100.0
	if boss.hatate_mode and player:
		new_y = -120.0
		if player.global_position.x > boss.boss_handler.global_position.x: new_x = -160
		if player.global_position.x < boss.boss_handler.global_position.x: new_x = 160
	move_boss(old_pos + Vector2(new_x, new_y), 1.0)
	await _set_timer(0.2)
	boss.finished_init = true
	boss.magic_circle_effect.appear_animation()
	play_sound(boss.long_charge_up)
	await _set_timer(0.8)
	play_sound(boss.short_charge_up)
	leaf_gather_effect()
	await _set_timer(1.3)

func boss_to_default_start_pos() -> void:
	move_boss(boss.boss_handler.global_position + Vector2(0.0, -160.0))

func shoot_accel_ringed_bullet(bullet_type: PackedScene, init_position: Vector2 = Vector2.ZERO, init_velocity: Vector2 = Vector2(50.0, 50.0), init_wait: float = 1.0, b_velocity: float = 30.0, angle: float = 0.0, rotation: float = 0.0) -> void:
	if !check_if_within_playfield(init_position): return
	var bullet_shot = bullet_type.instantiate()
	bullet_shot.rotation = rotation
	bullet_shot.slow_then_speed = true
	bullet_shot.slow_then_speed_time = init_wait
	bullet_shot.slow_then_speed_veloc = b_velocity
	bullet_shot.slow_then_speed_angle = angle
	bullet_shot.veloc = init_velocity
	Scenes.current_scene.add_child(bullet_shot)
	boss.bullet_pool.append(bullet_shot)
	bullet_shot.z_index = boss.z_index + 1
	bullet_shot.global_position = init_position
	bullet_shot.reset_physics_interpolation()
	bullet_shot.enable_movement()

func shoot_ringed_accel_bullet_from_position(bullet_type: PackedScene, start_pos: Vector2, init_speed: float = 50.0, init_wait: float = 1.0, init_angle: float = 0.0, b_velocity: float = 50.0, b_angle: float = 0.0, rotation: float = 0.0) -> void:
	var result_velocity = Vector2(init_speed * cos(init_angle), init_speed * sin(init_angle))
	shoot_accel_ringed_bullet(bullet_type, start_pos, result_velocity, init_wait, b_velocity, b_angle, rotation)

func _hatate_attack_anim() -> void:
	if !boss: return
	hatate_attack_anim_played = true
	boss.execute_attack_anim_hatate()

func reset_boss_anim_from_attack() -> void:
	if !boss: return
	if boss.boss_sprite.animation == &"attack" and boss.attack_anim_ended:
		reset_boss_anim()

func goto_next_spell() -> void:
	if !boss: return
	if boss.force_end_player_death: return
	await _set_timer(0.1)
	boss.start_next_spell_card(boss.current_spell_index)

func hide_photo_counter() -> void:
	boss.boss_handler.hide_photo_counter()

func show_photo_counter() -> void:
	boss.boss_handler.show_photo_counter()

func spawn_aim_eff(distance: float = 85.0, rotate_off: float = 0.0, init_scale: float = 1.5, interp_travel: bool = true, homing: bool = true) -> void:
	if !is_instance_valid(boss): return
	if is_instance_valid(boss_viewfinder_warning):
		boss_viewfinder_warning.queue_free()
	boss_viewfinder_warning = VIEWFINDER_EFF.instantiate()
	boss_viewfinder_warning.distance = distance
	boss_viewfinder_warning.rotation_offset = rotate_off
	boss_viewfinder_warning.interp_travel = interp_travel
	boss_viewfinder_warning.track_player = homing
	boss_viewfinder_warning.alt_sprite = boss.hatate_mode
	boss_viewfinder_warning.boss = boss
	boss_viewfinder_warning.scale = Vector2(init_scale, init_scale)
	Scenes.current_scene.add_child(boss_viewfinder_warning)
	boss_viewfinder_warning.global_position = boss.global_position
	boss_viewfinder_warning.reset_physics_interpolation()
	play_sound(boss.camera_ready)

func delete_aim_eff(is_instant: bool = false) -> void:
	if !is_instance_valid(boss_viewfinder_warning): return
	boss_viewfinder_warning._disappear_anim(is_instant)
