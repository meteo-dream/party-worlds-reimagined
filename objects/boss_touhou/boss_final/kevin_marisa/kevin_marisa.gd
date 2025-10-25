extends FinalBoss

const EXPLOSION = preload("res://engine/objects/effects/explosion/explosion.tscn")

@export_group("Sound Effects - Marisa")
@export var bullet_laser_small: AudioStream
@export var bullet_master_spark: AudioStream
@export var prepare_master_spark: AudioStream
@export var summon_minion: AudioStream
@export_group("Kevin", "kevin_")
@export var kevin_appear: AudioStream
@export var kevin_explode: AudioStream

func _ready() -> void:
	super()

func summon_animation_and_process() -> void:
	Audio.play_sound(kevin_appear, self)
	move_boss(boss_handler.global_position + Vector2(150.0, -50.0), 1.0)
	await get_tree().create_timer(1.0, false, false, true).timeout
	if is_instance_valid(boss_handler):
		offset_phase_index = boss_handler.phase_index
		boss_handler.enable_secondary_boss = true
		trigger = boss_handler
		current_spell_index = boss_handler.phase_index
	activate()
	start_next_spell_card()

# Positive is left, negative is right
func _animation_process(delta: float) -> void:
	if !boss_sprite: return
	else: boss_sprite.flip_h = false

func start_move_anim() -> void:
	if direction < 0:
		boss_sprite.play(&"move_left")
	else:
		boss_sprite.play(&"move_right")
	is_moving = true

func end_move_anim() -> void:
	if direction < 0:
		boss_sprite.play(&"stop_left")
	else:
		boss_sprite.play(&"stop_right")
	is_moving = false

func _on_boss_sprite_animation_finished() -> void:
	if boss_sprite.animation == &"stop_left" or boss_sprite.animation == &"stop_right":
		adapt_direction(0.0)
		boss_sprite.play(&"default")
		is_moving = false
	if boss_sprite.animation == &"attack":
		attack_anim_ended = true
	if boss_sprite.animation == &"attack_prep":
		attack_anim_ended = false

func adapt_direction(vector_x: float, force_direction_to_take: bool = false, direction_to_take: int = 1) -> void:
	if force_direction_to_take:
		direction = direction_to_take
		return
	if vector_x < 0: direction = 1
	else: direction = -1

func _bonus_effect_post_defeat() -> void:
	var explosion_eff = EXPLOSION.instantiate()
	explosion_eff.scale = Vector2(8.0, 8.0)
	Audio.play_sound(kevin_explode, boss_handler)
	Scenes.current_scene.add_child(explosion_eff)
	explosion_eff.z_index = z_index + 50
	explosion_eff.global_position = global_position
	explosion_eff.reset_physics_interpolation()

func _set_defeat_velocity() -> void:
	return
