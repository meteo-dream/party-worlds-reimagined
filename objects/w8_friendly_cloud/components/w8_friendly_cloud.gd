extends Node2D

@export var bonus_to_drop: InstanceNode2D
@export var sounds: Array[AudioStream] = [
	preload("res://engine/objects/enemies/lakitus/sounds/lakitu_mek.ogg"),
	preload("res://engine/objects/enemies/lakitus/sounds/lakitu_myu.ogg"),
	preload("res://engine/objects/enemies/lakitus/sounds/lakitu_rek.ogg")
]

var pathfollow
var has_thrown_bonus: bool = false
signal bonus_delivered

func _ready() -> void:
	var current_scene = Scenes.current_scene
	var path2d = current_scene.get_child(2)
	if path2d: pathfollow = path2d.get_child(0)
	if pathfollow:
		global_position = Vector2(pathfollow.global_position.x + 408, 80)
	return

func _physics_process(delta: float) -> void:
	position.x -= 200.0 * delta
	if pathfollow:
		var tank_pos = pathfollow.global_position
		if global_position.x >= tank_pos.x and global_position.x <= tank_pos.x + 64 and !has_thrown_bonus:
			throw_bonus()
			has_thrown_bonus = true
			return
		if global_position.x < tank_pos.x - 500:
			queue_free()

func throw_bonus() -> void:
	NodeCreator.prepare_ins_2d(bonus_to_drop, self).create_2d().execute_instance_script()
	Audio.play_sound(sounds.pick_random(), self)
	bonus_delivered.emit()
