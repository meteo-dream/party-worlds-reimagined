extends GeneralMovementBody2D

@onready var mario = Thunder._current_player
@onready var kevin_sprite: AnimatedSprite2D = $Sprite
var met_floor: bool = false
var run_process_once: bool = false

signal transform_into_marisa

func _ready() -> void:
	collided_floor.connect(func() -> void:
		met_floor = true)
	var tw = get_tree().create_tween()
	tw.tween_property(self, "speed:x", 0.0, 1.4)
	var local_player = Thunder._current_player
	if is_instance_valid(kevin_sprite) and is_instance_valid(local_player):
		kevin_sprite.sprite_frames = local_player.sprite.sprite_frames
		kevin_sprite.play(&"jump")
	super()

func _physics_process(delta: float) -> void:
	super(delta)
	if is_instance_valid(kevin_sprite):
		if met_floor:
			kevin_sprite.play(&"default")
			turn_sprite_around()
		elif speed.y > 0.0 and kevin_sprite.animation == &"jump":
			kevin_sprite.play(&"fall")

func turn_sprite_around() -> void:
	if run_process_once or !is_instance_valid(kevin_sprite): return
	run_process_once = true
	await get_tree().create_timer(1.0, false, false).timeout
	kevin_sprite.flip_h = true
	Audio.play_sound(load("res://objects/boss_touhou/cutscene/sounds/smas_camera.wav"), self)
	await get_tree().create_timer(0.5, false, false).timeout
	transform_into_marisa.emit()
