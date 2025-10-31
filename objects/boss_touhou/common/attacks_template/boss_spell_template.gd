extends Node
class_name BossSpellcard

signal start
signal middle
signal end
signal forced_end

const RED_MUSHROOM = preload("res://engine/objects/powerups/red_mushroom/red_mushroom.tscn")
const NICE_AURA = preload("res://objects/boss_touhou/common/components/nice_aura.tscn")
const DEFAULT_POWERUP_SOUND = preload("res://engine/objects/players/prefabs/sounds/powerup.wav")
const DEFAULT_NEUTRAL_SOUND = preload("res://engine/objects/players/prefabs/sounds/powerup.wav")

@export_category("Spell Card Attack Settings")
@export var is_spell_card: bool = false # Nonspell (F) or spell (T)?
@export var spellcard_name_text: String = ""
@export var spellcard_time: float = 20.0
@export var spellcard_score_bonus: int = 8000
@onready var spellcard_name: String = spellcard_name_text
var boss: Node2D
var begin_attack: bool = false
var FORCE_END_SPELLCARD: bool = false
var pickup_powerup_sound: AudioStream = DEFAULT_POWERUP_SOUND
var pickup_neutral_sound: AudioStream = DEFAULT_NEUTRAL_SOUND

var last_player_angle: float

enum Wander_Type {
	MOVE_X_TOWARDS_PLAYER,
	MOVE_Y_TOWARDS_PLAYER,
	MOVE_TOWARDS_PLAYER,
	RANDOM
}

@onready var player = Thunder._current_player

func _accept_attack(node) -> void:
	boss = node
	start_attack()

# Preparations
func start_attack() -> void:
	boss.receive_spell_card_info(spellcard_name, spellcard_time, is_spell_card)
	start.emit()

# Repeatable pattern
func middle_attack() -> void:
	middle.emit()

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
	if !boss.keep_sc_bg:
		boss.request_hide_spellcard.emit()

# Check if the boss should still be attacking
func _boss_attack_interrupt() -> bool:
	return !begin_attack or boss.force_end_player_death or FORCE_END_SPELLCARD

func boss_to_default_start_pos() -> void:
	move_boss(boss.boss_handler.global_position + Vector2(0.0, -160.0))

func leaf_gather_effect(duration: float = 1.2, distance: float = 220.0, amount: int = 120, travel_time: float = 0.6, frequency: int = 1, effect_type: int = 0) -> void:
	if !boss: return
	boss.leaf_gather_effect(duration, distance, amount, travel_time, frequency)

func shoot_simple_bullet(bullet_type: PackedScene, init_position: Vector2 = Vector2.ZERO, b_velocity: Vector2 = Vector2(50.0, 50.0), rotation: float = 0.0) -> void:
	if !check_if_within_playfield(init_position): return
	var bullet_shot = bullet_type.instantiate()
	bullet_shot.rotation = rotation
	bullet_shot.veloc = b_velocity
	Scenes.current_scene.add_child(bullet_shot)
	boss.bullet_pool.append(bullet_shot)
	bullet_shot.appear_animation()
	bullet_shot.z_index = boss.z_index + 1
	bullet_shot.global_position = init_position
	bullet_shot.reset_physics_interpolation()
	bullet_shot.enable_movement()

func aim_at_player() -> float:
	if !is_instance_valid(boss): return 0.0
	player = Thunder._current_player
	if !boss.force_end_player_death and is_instance_valid(player):
		boss.last_player_angle = boss.global_position.angle_to_point(player.global_position)
	return boss.last_player_angle

func shoot_bullet(bullet_type: PackedScene, b_speed: float = 50.0, angle: float = 0.0, rotation: float = 0.0, distance: float = 0.0) -> void:
	var shoot_position = Vector2(boss.global_position.x + distance * cos(angle), boss.global_position.y + distance * sin(angle))
	var result_velocity = Vector2(b_speed * cos(angle), b_speed * sin(angle))
	shoot_simple_bullet(bullet_type, shoot_position, result_velocity, rotation)
	return

func shoot_bullet_from_position(bullet_type: PackedScene, start_pos: Vector2, b_speed: float = 50.0, angle: float = 0.0, rotation: float = 0.0) -> void:
	var result_velocity = Vector2(b_speed * cos(angle), b_speed * sin(angle))
	shoot_simple_bullet(bullet_type, start_pos, result_velocity, rotation)
	return

func shoot_at_distance(bullet_type: PackedScene, b_speed: float = 100.0, distance: float = 20.0, angle: float = 0.0, rotation: float = 0.0) -> void:
	var final_position: Vector2 = boss.global_position + Vector2(distance * cos(angle), distance * sin(angle))
	shoot_bullet_from_position(bullet_type, final_position, b_speed, angle, rotation)

func move_boss(destination: Vector2, duration: float = 1.0, tween_style: Tween.TransitionType = Tween.TRANS_CIRC, ease_style: Tween.EaseType = Tween.EASE_OUT, ignore_time_scale: bool = false) -> void:
	if !boss: return
	boss.move_boss(destination, duration, tween_style, ease_style, ignore_time_scale)

# Not recommended to use the boss as the origin point.
func move_boss_wander(wander_style: Wander_Type, origin_point: Vector2, upper_bound: Vector2, lower_bound: Vector2, distance: float = 100.0, duration: float = 2.5, tween_style: Tween.TransitionType = Tween.TRANS_CIRC, ease_style: Tween.EaseType = Tween.EASE_OUT) -> void:
	if !boss: return
	var rand_angle: float = randf_range(0, PI*2)
	var player_angle: float = aim_at_player()
	var destination: Vector2
	var move_vector: Vector2
	match wander_style:
		Wander_Type.RANDOM:
			move_vector = Vector2(distance * cos(rand_angle), distance * sin(rand_angle))
		Wander_Type.MOVE_X_TOWARDS_PLAYER:
			if player:
				if boss.global_position.x > player.global_position.x:
					player_angle = deg_to_rad(-180)
					rand_angle = -randf_range(0, PI)
				if boss.global_position.x < player.global_position.x:
					player_angle = deg_to_rad(0)
					rand_angle = randf_range(0, PI)
			move_vector = Vector2(distance * cos(player_angle), distance * sin(rand_angle))
		Wander_Type.MOVE_Y_TOWARDS_PLAYER:
			if player:
				if boss.global_position.y > player.global_position.y:
					player_angle = deg_to_rad(-90)
					rand_angle = randf_range(-(PI / 2), (PI / 2))
				if boss.global_position.y < player.global_position.y:
					player_angle = deg_to_rad(90)
					rand_angle = randf_range((PI/2), (PI/2)*3)
			move_vector = Vector2(distance * cos(rand_angle), distance * sin(player_angle))
		Wander_Type.MOVE_TOWARDS_PLAYER:
			move_vector = Vector2(distance * cos(player_angle), distance * sin(player_angle))
	# corrections phase
	destination = origin_point + move_vector
	destination.x = clamp(destination.x, origin_point.x + lower_bound.x, origin_point.x + upper_bound.x)
	destination.y = clamp(destination.y, origin_point.y + lower_bound.y, origin_point.y + upper_bound.y)
	boss.move_boss(destination, duration, tween_style, ease_style)

func boss_play_attack_anim() -> void:
	if !boss: return
	boss.start_attack_anim()

func reset_boss_anim() -> void:
	if !boss: return
	boss.reset_to_default_anim()

func reset_boss_anim_from_attack() -> void:
	if !boss: return
	if boss.boss_sprite.animation == &"attack" and boss.attack_anim_ended:
		reset_boss_anim()

func boss_nice_aura() -> void:
	play_sound(boss.nice_aura)
	_spawn_nice_aura()

func _spawn_nice_aura() -> void:
	if SettingsManager.settings.quality == SettingsManager.QUALITY.MIN: return
	var nice_aura = NICE_AURA.instantiate()
	Scenes.current_scene.add_child(nice_aura)
	if boss:
		nice_aura.anchor_node = boss
		nice_aura.z_index = boss.z_index - 1

func goto_next_spell() -> void:
	if !boss: return
	if boss.force_end_player_death: return
	await _set_timer(0.1)
	boss.start_next_spell_card(boss.current_spell_index)

func _set_timer(t: float, ignore_time_scale: bool = false) -> void:
	await get_tree().create_timer(t, false, false, ignore_time_scale).timeout

func player_gain_score(amount: int) -> void:
	if amount > 0:
		Data.add_score(amount)
		if player:
			ScoreText.new(str(amount), player)

func player_gain_pity(to_suit: String = "super", conditional: bool = true) -> void:
	if boss.force_end_player_death: return
	if conditional and !Thunder.is_player_power(Data.PLAYER_POWER.SMALL): return
	# Pity policy goes here.
	var to: PlayerSuit = CharacterManager.get_suit(to_suit)
	if !to or !player: return
	
	boss.request_hud_pity.emit()
	
	var powerup_sfx: AudioStream
	var neutral_sfx := CharacterManager.get_sound_replace(pickup_neutral_sound, DEFAULT_NEUTRAL_SOUND, "powerup_no_transform", true)
	if to.name != Thunder._current_player_state.name:
		player.change_suit(to)
		powerup_sfx = CharacterManager.get_sound_replace(pickup_powerup_sound, pickup_powerup_sound, "powerup", true)
		Audio.play_sound(powerup_sfx, player, false, {pitch = 1.0, ignore_pause = true})
		return

func bullet_screen_clear(should_score: bool = true) -> void:
	boss._danmaku_clear_screen(should_score)

func play_sound(sfx: AudioStream, source: Node2D = null, interruptable: bool = false) -> void:
	if !source and boss:
		if !boss: return
		source = boss
	if !interruptable:
		Audio.play_sound(sfx, source)
	elif sfx:
		boss.boss_handler._play_sound_interruptable(sfx)

func slow_time() -> void:
	boss.request_slow_time.emit()

func restore_time() -> void:
	boss.request_restore_time.emit()

func check_if_within_playfield(position_to_check: Vector2) -> bool:
	if !boss: return false
	if position_to_check.x < boss.boss_handler.global_position.x - 320: return false
	if position_to_check.x > boss.boss_handler.global_position.x + 320: return false
	if position_to_check.y < boss.boss_handler.global_position.y - 240: return false
	if position_to_check.y > boss.boss_handler.global_position.y + 240: return false
	return true

func do_screen_shake(duration: float = 0.2, amplitude: int = 6, interval: float = 0.01) -> void:
	if Thunder._current_camera.has_method(&"shock"):
		Thunder._current_camera.shock(duration, Vector2.ONE * amplitude, interval)
