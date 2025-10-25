extends Area2D

const EXPLOSION = preload("res://engine/objects/effects/explosion/explosion.tscn")
const BOMB_EXPL = preload("res://stages/world_3/objects/chorniy_mario/bomb_expl.ogg")
const APPEAR = preload("res://stages/world_3/objects/chorniy_mario/appear.ogg")

@onready var mario = Thunder._current_player
@onready var sprite = $Sprite

var appear_triggered = false
var appear_interp: bool = false
@export var timer = 0.8

func _physics_process(_delta: float) -> void:
	if !is_instance_valid(mario) or mario.completed:
		_explode_png_logic()
		return
	
	if mario.global_position.x > 128 && !appear_triggered:
		appear_triggered = true
		await get_tree().create_timer(timer, false, true, false).timeout
		Audio.play_sound(APPEAR, self)
	
	if !appear_triggered: return
	
	var pos = mario.global_position + Vector2.ZERO
	var animation = mario.sprite.animation
	var frame = mario.sprite.frame
	var flip_h = mario.sprite.flip_h
	var frames = mario.sprite.sprite_frames
	
	await get_tree().create_timer(timer, false, true, false).timeout
	if !is_instance_valid(mario): return
	global_position = pos
	if !appear_interp:
		appear_interp = true
		reset_physics_interpolation()
	sprite.animation = animation
	sprite.frame = frame
	sprite.flip_h = flip_h
	sprite.sprite_frames = frames
	
	if overlaps_body(mario):
		mario.die()
		_explode_png_logic()

# kevin podokh
func _explode_png_logic() -> void:
	queue_free()
	var ex = EXPLOSION.instantiate()
	ex.global_position = global_position
	Scenes.current_scene.add_child(ex)
	Audio.play_1d_sound(BOMB_EXPL)
