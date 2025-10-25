extends LevelCutscene

const NEWSPAPER = preload("res://stages/world_9/Additives/cutscene/newspaper.tscn")
const EXPLOSION = preload("res://engine/objects/effects/explosion/explosion.tscn")
const REACTION_TEXT = preload("res://stages/world_9/Additives/cutscene/react_label.tscn")

const AYA_SPRITE = preload("res://stages/world_9/Additives/cutscene/aya_sprite.tscn")
const HATATE_SPRITE = preload("res://stages/world_9/Additives/cutscene/hatate_sprite.tscn")

const SOUND_DASH = preload("res://stages/world_9/Additives/cutscene/se_slash.wav")
const SOUND_THROW = preload("res://engine/objects/projectiles/sounds/throw.wav")
const SOUND_STUN = preload("res://engine/objects/projectiles/sounds/stun.wav")
const SOUND_WHAT = preload("res://stages/world_9/Additives/cutscene/what.wav")
const SOUND_PICK_UP = preload("res://stages/world_9/Additives/cutscene/se_ok00.wav")
const SOUND_SHOW_NEWS = preload("res://engine/objects/bumping_blocks/message_block/message_block.wav")
const SOUND_SHOCK = preload("res://stages/world_9/Additives/cutscene/warning.wav")
const SOUND_TURN = preload("res://objects/boss_touhou/cutscene/sounds/smas_camera.wav")

const AYA_START_POSITION = Vector2(7000.0, 96.0)
const AYA_END_POSITION = Vector2(-7000.0, 96.0)
const HATATE_START_POSITION = Vector2(800.0, 64.0)
const HATATE_END_POSITION = Vector2(-150.0, 192.0)


@onready var skip_label: Label = $SkipLabel
@onready var newspaper_target: Marker2D = $NewspaperLanding
@onready var remi_node = $RemiSprite
@onready var news_interval: Timer = $NewsInterval
var use_hatate_for_cutscene: bool = false
var targeted_news_bullet: Node2D
var start_shooting_news: bool = false
var start_detecting_targeted_news: bool = false
var play_dash_sound: bool = false
var reporter_node: Node2D

func _ready() -> void:
	if ProfileManager.current_profile.has_completed_world("9"):
		ProfileManager.current_profile.data.current_world = goto_path
		ProfileManager.save_current_profile()
	
	player.completed = true
	skippable = true
	CustomGlobals.load_boss_status_w9()
	use_hatate_for_cutscene = !CustomGlobals.check_for_hatate_boss()
	disappear_label()
	super()
	await _set_timer(4.0, true)
	# Cutscene actually starts here.
	if !use_hatate_for_cutscene:
		reporter_node = AYA_SPRITE.instantiate()
		Scenes.current_scene.add_child(reporter_node)
		reporter_node.global_position = AYA_START_POSITION
		reporter_node.reset_physics_interpolation()
		var tw = get_tree().create_tween()
		tw.tween_property(reporter_node, "global_position", AYA_END_POSITION, 5.0)
		tw.tween_callback(func() -> void:
			if is_instance_valid(reporter_node): reporter_node.queue_free())
		start_shooting_news = true
	else:
		reporter_node = HATATE_SPRITE.instantiate()
		Scenes.current_scene.add_child(reporter_node)
		reporter_node.global_position = HATATE_START_POSITION
		reporter_node.reset_physics_interpolation()
		var tw = get_tree().create_tween()
		tw.tween_property(reporter_node, "global_position", HATATE_END_POSITION, 1.4)
		tw.tween_callback(func() -> void:
			reporter_node.queue_free())
		await _set_timer(0.6)
		Audio.play_sound(SOUND_THROW, reporter_node)
		shoot_newspaper(reporter_node, 900.0, -100)
		await _set_timer(1.1)
		shoot_targeted_newspaper(0.58, newspaper_target)

## Shoot the newspaper at random angles.
func shoot_newspaper(origin: Node2D, speed: float, angle: float) -> void:
	var news_bullet = NEWSPAPER.instantiate()
	news_bullet.velocity = speed
	news_bullet.angle = deg_to_rad(angle)
	Scenes.current_scene.add_child(news_bullet)
	news_bullet.z_index = 57
	news_bullet.global_position = origin.global_position
	news_bullet.reset_physics_interpolation()

## Shoot the newspaper at a specific point.
func shoot_targeted_newspaper(time: float, target: Node2D) -> void:
	if is_instance_valid(targeted_news_bullet): return
	targeted_news_bullet = NEWSPAPER.instantiate()
	targeted_news_bullet.velocity = 0.0
	targeted_news_bullet.angle = 0.0
	Scenes.current_scene.add_child(targeted_news_bullet)
	targeted_news_bullet.global_position = target.global_position - Vector2(0.0, 600.0)
	targeted_news_bullet.reset_physics_interpolation()
	await _set_timer(1.0)
	var tw = get_tree().create_tween()
	tw.tween_property(targeted_news_bullet, "global_position", target.global_position, time)
	tw.tween_callback(play_sound_news_landing)

## Spawn the explosion and play the stun sound when the newspaper lands.
func play_sound_news_landing() -> void:
	if !is_instance_valid(targeted_news_bullet): return
	Audio.play_sound(SOUND_STUN, targeted_news_bullet)
	targeted_news_bullet.stop_moving = true
	var explosion = EXPLOSION.instantiate()
	Scenes.current_scene.add_child(explosion)
	explosion.global_position = targeted_news_bullet.global_position
	explosion.reset_physics_interpolation()
	for i in 90:
		if targeted_news_bullet.rotation > PI*2:
			targeted_news_bullet.rotation -= PI*2
		else: break
	await _set_timer(1.0)
	pick_up_news()

## Remilia picks up the newspaper.
func pick_up_news() -> void:
	spawn_reaction_text(0)
	Audio.play_sound(SOUND_TURN, remi_node)
	await _set_timer(1.2)
	remi_node.flip_h = true
	await _set_timer(0.5)
	Audio.play_sound(SOUND_PICK_UP, remi_node)
	var tw_move = get_tree().create_tween()
	tw_move.tween_property(targeted_news_bullet, "global_position:y", remi_node.global_position.y - 10.0, 0.5)
	tw_move.parallel().tween_property(targeted_news_bullet, "rotation", 0.0, 0.5)
	await _set_timer(1.4)
	spawn_reaction_text(1)
	await _set_timer(1.0)
	_start_transition()

func _physics_process(delta: float) -> void:
	if is_instance_valid(reporter_node):
		if start_shooting_news and !use_hatate_for_cutscene:
			news_interval.start(0.0001)
			Audio.play_sound(SOUND_THROW, reporter_node)
			if reporter_node.is_on_screen():
				if !play_dash_sound:
					play_dash_sound = true
					Audio.play_sound(SOUND_DASH, self)
					do_screen_shake(0.7, 50)
				for i in 4:
					shoot_newspaper(reporter_node, randf_range(800.0, 1300.0), randf_range(0.0, 360.0))
			if !start_detecting_targeted_news and is_instance_valid(newspaper_target):
				if reporter_node.global_position.x < newspaper_target.global_position.x:
					shoot_targeted_newspaper(0.58, newspaper_target)
	
	if skippable: _cutscene_skip_logic()

func disappear_label() -> void:
	if !is_instance_valid(skip_label): return
	await _set_timer(4.0, true)
	var tw = get_tree().create_tween()
	tw.tween_property(skip_label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		skip_label.queue_free())

func spawn_reaction_text(type: int = 0) -> void:
	var used_string: String = "?"
	if type == 0:
		Audio.play_sound(SOUND_WHAT, remi_node)
	else:
		Audio.play_sound(SOUND_SHOCK, remi_node)
		used_string = "!"
	
	var new_reaction = REACTION_TEXT.instantiate()
	new_reaction.start_position = remi_node.global_position
	new_reaction.text = used_string
	Scenes.current_scene.add_child(new_reaction)

## Set timer with timeout.
func _set_timer(time: float = 1.0, ignore_scale: bool = false) -> void:
	await get_tree().create_timer(time, false, false, ignore_scale).timeout

## Shakes the screen.
func do_screen_shake(duration: float = 0.2, amplitude: int = 6, interval: float = 0.01) -> void:
	if Thunder._current_camera.has_method(&"shock"):
		Thunder._current_camera.shock(duration, Vector2.ONE * amplitude, interval)
