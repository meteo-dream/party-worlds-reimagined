extends Area2D
class_name CameraViewfinder

@export_category("Camera Viewfinder Bullet")
@export_group("Settings")
@export_enum("Nothing: 0", "Hurt: 1", "Death: 2", "Photo Counted: 3") var type: int = 3
@export var ignore_starman: bool = true
@export var life_time: float = 3.0
@export var velocity: Vector2
@export var use_destination_vector_instead: bool = true
@export var destination: Vector2
@export var homing: bool = false
@export var homing_speed: float = 5.0
@export var instant_flash: bool = false
@export var camera_flash: bool = false
@export var hatate_camera: bool = false
@export_group("Sound Effects")
@export var player_in_camera: AudioStream
@export var camera_shutter: AudioStream

@onready var viewfinder_sprite: Sprite2D = $Sprite2D
@onready var instant_flash_sprite: Sprite2D = $Sprite2D/FlashEffect
@onready var lifetime_timer: Timer = $LifeTime
@onready var collision_box: CollisionShape2D = $CollisionShape2D
var w9_boss: W9Boss
var player_spotted: Player = null
var tw: Tween
var scale_tween: Tween
var photo_taken: bool = false
var start_moving: bool = false
var disappear_eff: bool = false
var homing_angle: float
var camera_rotate_offset: float = 0.0
var camera_flash_growth: float = 0.003
var player: Player

func _ready() -> void:
	if instant_flash:
		camera_flash = true
		if is_instance_valid(instant_flash_sprite):
			instant_flash_sprite.self_modulate.a = 1.0
	if !camera_flash and instant_flash_sprite:
		instant_flash_sprite.queue_free()
	viewfinder_sprite.self_modulate.a = 0.0
	body_entered.connect(func(entity: Node2D) -> void:
		if player_spotted == null and entity.get_script().get_global_name() == "Player":
			player_spotted = entity
		)
	body_exited.connect(func(entity: Node2D) -> void:
		if player_spotted != null and entity.get_script().get_global_name() == "Player":
			player_spotted = null
		)
	lifetime_timer.timeout.connect(func() -> void:
		take_picture()
		)
	rotate(camera_rotate_offset)

# movement code here
func _physics_process(delta: float) -> void:
	if is_instance_valid(instant_flash_sprite) and photo_taken:
		instant_flash_sprite.scale += Vector2(camera_flash_growth, camera_flash_growth)
	#if disappear_eff and viewfinder_sprite.self_modulate.a <= 0.0 and is_instance_valid(self):
	#	queue_free()
	if photo_taken: return
	if lifetime_timer.is_stopped():
		lifetime_timer.start(life_time)
	if (photo_taken and !hatate_camera) or !start_moving: return
	
	var actual_velocity: Vector2 = velocity
	if use_destination_vector_instead:
		_movement_dest_vector()
		return
	if homing:
		player = Thunder._current_player
		if player:
			homing_angle = global_position.angle_to_point(player.global_position)
			var boss_cone: float = global_position.angle_to_point(w9_boss.global_position)
			var speed_calc: float = homing_speed
			if homing_angle > boss_cone + deg_to_rad(-45) and homing_angle < boss_cone + deg_to_rad(45):
				speed_calc /= 2.5
			actual_velocity = Vector2(speed_calc * cos(homing_angle), speed_calc * sin(homing_angle))
			global_rotation = w9_boss.global_position.angle_to_point(global_position) + camera_rotate_offset
	global_position += actual_velocity * delta

func _movement_dest_vector() -> void:
	if tw: return
	tw = get_tree().create_tween()
	tw.set_trans(Tween.TRANS_EXPO)
	tw.set_ease(Tween.EASE_IN)
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(self, "global_position", destination, life_time)
	tw.call_deferred("take_picture")

func take_picture() -> void:
	if photo_taken: return
	photo_taken = true
	if scale_tween: scale_tween.kill()
	camera_shutter_damage()
	Audio.play_sound(camera_shutter, self)
	if camera_flash: flash_disappear_anim()
	viewfinder_sprite.frame = 1
	await get_tree().create_timer(0.3, false).timeout
	disappear_anim()

func homing_slow_down_over_time() -> void:
	var tw2 = get_tree().create_tween()
	tw2.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw2.tween_property(self, "homing_speed", 0.5, life_time + 0.8)

func _hatate_slow_down() -> void:
	var tw2 = get_tree().create_tween()
	tw2.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw2.tween_property(self, "velocity", Vector2(0.0, 0.0), life_time - 0.3)

func shrink_over_time() -> void:
	scale_tween = get_tree().create_tween()
	scale_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	scale_tween.tween_property(self, "scale", Vector2(0.0, 0.0), life_time + 0.5)

func appear_anim(use_scale: bool = false, init_scale_y: float = 1.0) -> void:
	if use_scale:
		viewfinder_sprite.self_modulate.a = 1.0
		scale.y = 0.0
		var tw2 = get_tree().create_tween()
		tw2.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tw2.tween_property(self, "scale:y", init_scale_y, 0.3)
		return
	if instant_flash:
		viewfinder_sprite.self_modulate.a = 0.7
		lifetime_timer.start(life_time)
		return
	var tw3 = get_tree().create_tween()
	tw3.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw3.tween_property(viewfinder_sprite, "self_modulate:a", 1.0, 0.4)

func disappear_anim() -> void:
	disappear_eff = true
	var tw2 = get_tree().create_tween()
	tw2.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw2.tween_property(viewfinder_sprite, "self_modulate:a", 0.0, 0.3)
	await get_tree().create_timer(0.3).timeout
	queue_free()

func flash_disappear_anim() -> void:
	if camera_flash and is_instance_valid(instant_flash_sprite):
		instant_flash_sprite.self_modulate.a = 1.0
		var flash_tween = get_tree().create_tween()
		flash_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		flash_tween.tween_property(instant_flash_sprite, "self_modulate:a", 0.0, 0.3)

func camera_shutter_damage() -> void:
	player = Thunder._current_player
	if !is_instance_valid(player): return
	if overlaps_body(player) or player_spotted != null:
		Audio.play_sound(player_in_camera, self)
		match type:
				1 when !player.is_invincible(): player.hurt()
				2: player.die()
				3: add_to_photo_counter()

func add_to_photo_counter() -> void:
	if !is_instance_valid(w9_boss): return
	w9_boss._alert_photo_taken()

func get_rect() -> Rect2:
	return collision_box.shape.get_rect()

func delete_self() -> void:
	photo_taken = true
	start_moving = false
	if scale_tween: scale_tween.kill()
	if is_instance_valid(instant_flash_sprite): instant_flash_sprite.queue_free()
	var tw2 = get_tree().create_tween()
	tw2.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw2.tween_property(viewfinder_sprite, "modulate:a", 0.0, 0.2)
	await get_tree().create_timer(0.2).timeout
	queue_free()
