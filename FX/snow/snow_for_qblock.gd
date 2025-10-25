extends Area2D
const SOUND_EFFECT = preload("res://FX/snow/sounds/snow.wav")

var qblock: StaticBody2D

func _ready():
	await get_tree().physics_frame

func _physics_process(delta):
	if qblock:
		if !is_instance_valid(qblock):
			qblock_bumped()
			qblock = null
		return
	
	for i in get_overlapping_bodies():
		if i is StaticBody2D:
			qblock = i
			qblock.bumped.connect(qblock_bumped)
			
			

func qblock_bumped() -> void:
	var speeds = [Vector2(2, -3), Vector2(-2, -3)]#, Vector2(-2, -8), Vector2(-4, -7)]
	Audio.play_sound(SOUND_EFFECT, self)
	queue_free()
