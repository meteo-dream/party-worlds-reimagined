extends Area2D
class_name BulletBase

@export_category("Bullet")
@export_enum("Nothing: 0", "Hurt: 1", "Death: 2") var type: int = 1
@export var ignore_starman: bool = true

const ERASE_EFF = preload("res://objects/boss_touhou/common/components/bullet_erase_effect.tscn")
const ERASE_SFX = preload("res://objects/boss_touhou/common/sounds/se_etbreak.wav")

@export_category("Bullet Details")
@export var bullet_erase_color: Color = Color.RED
@export var bullet_erase_sound: AudioStream = ERASE_SFX
@export var bullet_erase_scale: float = 1.0
@export var ignore_modulate_alpha_for_collision: bool = false
@export var appear_animation_time: float = 0.5
@export var deletable_bullet: bool = true
var veloc: Vector2
var actual_vel: Vector2
var allow_movement: bool = false
var force_disable_collision: bool = false
var has_left_screen: bool = false

enum MovementDisableType {
	SLOWED_DOWN,
	INSTANT
}

@onready var bullet_sprite = $Sprite
@onready var appear_sprite: Sprite2D = $Sprite/AppearAnim

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	_movement_process(delta)
	var player: Player = Thunder._current_player
	if !player: return
	if player.is_starman() && ignore_starman: return
	if (bullet_sprite.self_modulate.a >= 1.0 or ignore_modulate_alpha_for_collision) and !force_disable_collision:
		if overlaps_body(player):
			match type:
				1 when !player.is_invincible(): player.hurt()
				2: player.die()
			if deletable_bullet: delete_self()

# Use this to write movement code.
func _movement_process(delta: float) -> void:
	if has_left_screen: delete_self(true, true)
	if !allow_movement: return
	global_position += actual_vel * delta

func enable_movement() -> void:
	actual_vel = veloc
	allow_movement = true

# Change bullet speed over time.
func tween_bullet_speed(new_velocity: float = 1.0, duration: float = 1.0):
	var init_angle = actual_vel.angle()
	var new_vector = Vector2(new_velocity * cos(init_angle), new_velocity * sin(init_angle))
	var speed_tween = get_tree().create_tween()
	speed_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	speed_tween.tween_property(self, "actual_vel", new_vector, duration)

# Appear animation
func appear_animation() -> void:
	bullet_sprite.self_modulate.a = 0.0
	var tw_bullet = get_tree().create_tween()
	tw_bullet.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw_bullet.tween_property(bullet_sprite, "self_modulate:a", 1.0, 0.15)
	allow_movement = true
	
	if !is_instance_valid(appear_sprite): return
	
	var init_scale = appear_sprite.scale
	appear_sprite.self_modulate.a = 0.0
	appear_sprite.scale += Vector2(2.0, 2.0)
	var tw = get_tree().create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(appear_sprite, "self_modulate:a", 1.0, 0.01)
	var tw2 = get_tree().create_tween()
	tw2.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw2.tween_property(appear_sprite, "self_modulate:a", 0.0, 0.15)
	tw2.parallel().tween_property(appear_sprite, "scale", init_scale, 0.3)

# If Disable Type is INSTANT, duration is unused.
func disable_movement(disable_type: MovementDisableType = MovementDisableType.INSTANT, duration: float = 1.0) -> void:
	match disable_type:
		MovementDisableType.INSTANT:
			actual_vel = Vector2.ZERO
			allow_movement = false
		MovementDisableType.SLOWED_DOWN:
			var tw = get_tree().create_tween()
			tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
			tw.tween_property(self, "actual_vel", Vector2.ZERO, duration)
			tw.tween_callback(func disablemov() -> void:
				allow_movement = false
				)

func delete_self(autodelete: bool = false, offscreen: bool = false) -> void:
	if !offscreen:
		var erase_effect = ERASE_EFF.instantiate()
		Scenes.current_scene.add_child(erase_effect)
		erase_effect.modulate = bullet_erase_color
		erase_effect.global_position = global_position
		erase_effect.scale = Vector2(bullet_erase_scale, bullet_erase_scale)
		erase_effect.reset_physics_interpolation()
	if bullet_erase_sound and !autodelete:
		Audio.play_sound(bullet_erase_sound, self)
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	has_left_screen = true

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	has_left_screen = false
