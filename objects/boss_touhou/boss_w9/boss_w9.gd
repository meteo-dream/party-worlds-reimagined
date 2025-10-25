class_name W9Boss
extends GeneralMovementBody2D

const HATATE_SPRITES = preload("res://objects/boss_touhou/boss_w9/prefabs/hatate_himekaidou.tres")
const AYA_SPRITES = preload("res://objects/boss_touhou/boss_w9/prefabs/aya_shameimaru.tres")
const LEAF_EFFECT_SUMMON = preload("res://objects/boss_touhou/common/components/summon_leaf_effect.tscn")
const SPELL_RING_EFFECT = preload("res://objects/boss_touhou/common/components/spellcard_ring.tscn")
const _defeat_wander_speed: float = 0.5

@export_category("Custom Touhou Stuff")
@export_group("Sound Effects")
@export var battle_fail_sound: AudioStream
@export var camera_zoom: AudioStream
@export var camera_ready: AudioStream
@export var switch_to_vertical_viewfinder: AudioStream
@export var switch_to_sideways_viewfinder: AudioStream
@export var boss_defeat: AudioStream
@export var declare_spell_card: AudioStream
@export var short_charge_up: AudioStream
@export var long_charge_up: AudioStream
@export var burst_sound: AudioStream
@export var bullet_shoot_1: AudioStream
@export var bullet_twinkle: AudioStream
@export var bullet_erase: AudioStream
@export var nice_aura: AudioStream
@export var critical: AudioStream
@export var player_caught: AudioStream
@export var sfx_timeout0: AudioStream
@export var sfx_timeout1: AudioStream
@export_group("Battle Settings")
@export var max_number_of_spellcards: int = 4
@export var start_at_spellcard_number: int = 0
@export var disable_hurtbox: bool = false
@export var enable_alternate_boss: bool = true
@export_group("Reporter Specific Settings")
@export var max_number_of_pictures_allowed: int = 6
@export var max_number_of_pictures_allowed_alt: int = 4

@onready var boss_sprite: AnimatedSprite2D = $BossSprite
@onready var magic_circle_effect = $MagicCircleEff
@onready var sc_actual_timer: Timer = $AttackTimer
@onready var collision_area: Area2D = $Body
@onready var player = Thunder._current_player

var spellcard_ring: Sprite2D
var health_ring: Sprite2D

var current_spell_used: BossSpellcard
var current_spell_index: int = 0
var current_spell_name: String
var current_spell_max_time: float
var current_spell_is_card: bool
var current_pic_count: int = 0
var bullets_cleared: int = 0

var bullet_pool: Array
var hatate_mode: bool
var trigger: Node2D
var direction: int
var boss_mode_engaged: bool = false

var boss_handler: Node2D
var starting_position: Vector2
var force_end_player_death: bool
var finished_init: bool = false
var begin_proper_battle: bool = false
var attack_anim_ended: bool = false

# Variables set specifically for when a boss is defeated:
var keep_sc_bg: bool = false
var defeated_boss_wander: bool = false
var defeated_velocity: Vector2 = Vector2.ZERO

var movement_tween
var is_moving: bool = false

var last_player_angle: float

signal request_show_spellcard
signal request_hide_spellcard
signal victory_achieved
signal finished_movement
signal finished_entry_movement
signal request_fail_battle_forced
signal request_slow_time
signal request_restore_time
signal request_check_time
signal request_hud_pity

func _ready() -> void:
	current_spell_index = start_at_spellcard_number
	
	if player and enable_alternate_boss:
		hatate_mode = CustomGlobals.check_for_hatate_boss()
	
	if hatate_mode:
		boss_sprite.sprite_frames = HATATE_SPRITES
		boss_sprite.play(&"default")
	
	var children_list = get_parent().get_children()
	for i in children_list.size():
		if "bossw9handler" in children_list[i].name.to_lower():
			boss_handler = children_list[i]
			starting_position = boss_handler.global_position
	
	sc_actual_timer.timeout.connect(end_spell_card)

func _physics_process(delta: float) -> void:
	_animation_process(delta)
	if force_end_player_death: return
	_battle_process(delta)

func _animation_process(delta: float) -> void:
	if !boss_sprite: return
	
	if !hatate_mode:
		boss_sprite.flip_h = (direction < 0)
	else: boss_sprite.flip_h = (direction > 0)

func activate() -> void:
	boss_mode_engaged = true
	_start_first_spell_card()
	return

func failed_boss_fight() -> void:
	if is_instance_valid(current_spell_used):
		current_spell_used.force_end_attack()
		sc_actual_timer.paused = true
	move_boss(boss_handler.global_position + Vector2(800.0, -200.0), 5.0)
	if battle_fail_sound:
		Audio.play_sound(battle_fail_sound, self)
	force_end_player_death = true
	CustomGlobals.w9b_death_add(current_spell_index)
	request_hide_spellcard.emit()

func move_boss(destination: Vector2, duration: float = 1.0, tween_style: Tween.TransitionType = Tween.TRANS_CIRC, ease_style: Tween.EaseType = Tween.EASE_OUT, what: bool = false) -> void:
	if defeated_boss_wander: return
	adapt_direction(global_position.x - destination.x)
	start_move_anim()
	if movement_tween:
		movement_tween.kill()
	movement_tween = get_tree().create_tween()
	movement_tween.set_trans(tween_style)
	movement_tween.set_ease(ease_style)
	movement_tween.tween_property(self, "global_position", destination, duration)
	movement_tween.tween_callback(end_move_anim)
	movement_tween.parallel().emit_signal("finished_movement")

func move_boss_defeat() -> void:
	defeated_boss_wander = true

func start_move_anim() -> void:
	boss_sprite.play(&"move")
	is_moving = true

func end_move_anim() -> void:
	boss_sprite.play(&"stop")
	is_moving = false

func start_attack_anim() -> void:
	if hatate_mode:
		boss_sprite.play(&"attack_prep")
		return
	boss_sprite.play(&"attack")

func execute_attack_anim_hatate() -> void:
	boss_sprite.play(&"attack")

func reset_to_default_anim() -> void:
	boss_sprite.play(&"default")

func adapt_direction(vector_x: float, force_direction_to_take: bool = false, direction_to_take: int = 1) -> void:
	if force_direction_to_take:
		direction = direction_to_take
		return
	
	if vector_x < 0: direction = 1
	else: direction = -1

func _start_first_spell_card() -> void:
	begin_proper_battle = true
	start_next_spell_card(current_spell_index)

func start_next_spell_card(index: int = current_spell_index) -> void:
	if current_spell_index > max_number_of_spellcards:
		_battle_victory_sequence()
		return
	if force_end_player_death: return
	var sc_name_to_get = "sc_" + str(index)
	if hatate_mode: sc_name_to_get = sc_name_to_get + "_alt"
	current_spell_used = get_node_or_null(sc_name_to_get)
	assert(current_spell_used && current_spell_used is BossSpellcard, "Please attach a BossSpellcard node named " + sc_name_to_get + ".")
	if !current_spell_used is BossSpellcard:
		return
	
	current_spell_used._accept_attack(self)
	CustomGlobals.w9b_death_renew(current_spell_index)
	
	if sc_actual_timer:
		if !sc_actual_timer.is_stopped():
			sc_actual_timer.stop()
		sc_actual_timer.start(current_spell_used.spellcard_time)

func receive_spell_card_info(spellname: String, spelltime: float = 20.0, is_spell_card: bool = false) -> void:
	if force_end_player_death: return
	current_spell_name = spellname
	current_spell_max_time = spelltime
	current_spell_is_card = is_spell_card
	request_show_spellcard.emit()
	if !is_spell_card: return
	Audio.play_sound(declare_spell_card, self)

func end_spell_card() -> void:
	current_spell_index += 1
	if current_spell_used && current_spell_used is BossSpellcard:
		current_spell_used.end_attack()

func _on_boss_sprite_animation_finished() -> void:
	if boss_sprite.animation == &"stop":
		adapt_direction(0.0)
		boss_sprite.play(&"default")
		is_moving = false
	if boss_sprite.animation == &"attack":
		attack_anim_ended = true
	if boss_sprite.animation == &"attack_prep":
		attack_anim_ended = false

func _battle_process(delta: float) -> void:
	if player and !disable_hurtbox:
		if collision_area.overlaps_body(player):
			if !player.is_invincible(): player.hurt()
	
	# Timer checking for SFX
	request_check_time.emit()
	
	# Fail battle if the reporters got too many pictures in
	if (hatate_mode and current_pic_count >= max_number_of_pictures_allowed_alt) or (!hatate_mode and current_pic_count >= max_number_of_pictures_allowed):
		_force_end_battle()
	
	if defeated_boss_wander:
		global_position += defeated_velocity
		if !is_moving:
			var new_dir = 1
			if defeated_velocity.x < 0: new_dir = -1
			adapt_direction(0.0, true, new_dir)
			start_move_anim()

func spawn_spell_ring_effect() -> void:
	if is_instance_valid(spellcard_ring):
		spellcard_ring.queue_free()
	spellcard_ring = SPELL_RING_EFFECT.instantiate()
	spellcard_ring.ring_type = 0
	spellcard_ring.boss_node = self
	Scenes.current_scene.add_child(spellcard_ring)
	spellcard_ring.global_position = global_position
	spellcard_ring.reset_physics_interpolation()
	if is_instance_valid(health_ring):
		health_ring.queue_free()
	health_ring = SPELL_RING_EFFECT.instantiate()
	health_ring.ring_type = 1
	health_ring.post_appear_scale = Vector2(4.4, 4.4)
	health_ring.boss_node = self
	Scenes.current_scene.add_child(health_ring)
	health_ring.global_position = global_position
	health_ring.reset_physics_interpolation()

func delete_spell_ring_effect() -> void:
	if is_instance_valid(spellcard_ring): spellcard_ring.play_end_anim()
	if is_instance_valid(health_ring): health_ring.play_end_anim()

func _effect_timer_sfx_play(timer_value: float) -> void:
	if timer_value <= 2.0:
		if sfx_timeout0: Audio.play_sound(sfx_timeout0, self)
	elif timer_value <= 5.0:
		if sfx_timeout1: Audio.play_sound(sfx_timeout1, self)

func _force_end_battle() -> void:
	if !force_end_player_death: request_fail_battle_forced.emit()

func leaf_gather_effect(duration: float = 1.5, distance: float = 220.0, amount: int = 120, travel_time: float = 0.6, frequency: int = 1, effect_type: int = 0, endseq: bool = false, all_at_once: bool = false) -> void:
	var leaf_effect_control = LEAF_EFFECT_SUMMON.instantiate()
	if endseq: Scenes.current_scene.add_child(leaf_effect_control)
	else: add_child(leaf_effect_control)
	leaf_effect_control.global_position = global_position
	leaf_effect_control.reset_physics_interpolation()
	leaf_effect_control.z_index = z_index - 1
	leaf_effect_control.duration = duration
	leaf_effect_control.distance_from_center = distance
	leaf_effect_control.amount_of_effect_max = amount
	leaf_effect_control.effect_travel_time = travel_time
	leaf_effect_control.frequency = frequency
	leaf_effect_control.effect_type = effect_type
	leaf_effect_control.spawn_all_at_once = all_at_once
	leaf_effect_control.countdown_started = true

func _danmaku_clear_screen(should_tally_score: bool = true) -> void:
	if force_end_player_death: return
	if !bullet_pool.is_empty():
		for i in bullet_pool.size():
			if is_instance_valid(bullet_pool[i]):
				if should_tally_score:
					Data.add_score(10)
					ScoreText.new(str(10), bullet_pool[i])
				bullet_pool[i].delete_self()
				bullets_cleared += 1
		if should_tally_score: _danmaku_clear_tally(bullets_cleared)
		bullets_cleared = 0
		bullet_pool.clear()

func _danmaku_clear_tally(clear_count: int = 0) -> void:
	if clear_count >= 300: _reward_life()

func _reward_life() -> void:
	var player_cl = Thunder._current_player
	if !player_cl: return
	Data.add_lives(1)
	var _sfx = CharacterManager.get_sound_replace(Data.LIFE_SOUND, Data.LIFE_SOUND, "1up", false)
	ScoreTextLife.new("1UP", player_cl)
	Audio.play_sound(_sfx, player_cl)

func _alert_photo_taken() -> void:
	current_pic_count += 1
	if player_caught: Audio.play_sound(player_caught, self)
	var max_photo: int = max_number_of_pictures_allowed
	if hatate_mode: max_photo = max_number_of_pictures_allowed_alt
	if current_pic_count == max_photo - 1:
		if critical: Audio.play_sound(critical, self)

func _battle_victory_sequence() -> void:
	Audio.play_sound(boss_defeat, self)
	defeated_boss_wander = true
	player.completed = true
	var rand_angle: float = randf_range(0, PI*2)
	defeated_velocity = Vector2(_defeat_wander_speed * cos(rand_angle), _defeat_wander_speed * sin(rand_angle))
	await get_tree().create_timer(1.5, false).timeout
	if Thunder._current_camera.has_method(&"shock"):
		Thunder._current_camera.shock(0.5, Vector2.ONE * 20)
	keep_sc_bg = false
	request_hide_spellcard.emit()
	leaf_gather_effect(0.02, 220.0, 120, 0.6, 1, 1, true, true)
	Audio.play_sound(boss_defeat, self)
	_danmaku_clear_screen()
	if current_pic_count <= 0: _reward_life()
	CustomGlobals.w9b_death_reset()
	victory_achieved.emit()
	queue_free()
