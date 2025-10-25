extends Area2D

const coin_effect: PackedScene = preload("res://stages/world_6/Additives/6-2/blu-coin-effect.tscn")
const effect: = preload("res://stages/world_6/Additives/6-2/effect.tres")

@export var sound: AudioStream = preload("res://engine/objects/items/coin/coin.wav")


func _from_bumping_block() -> void:
	Audio.play_sound(sound, self)
	NodeCreator.prepare_2d(coin_effect, self).create_2d().bind_global_transform()
	queue_free()


func _physics_process(delta):
	if !Thunder._current_player: return
	if overlaps_body(Thunder._current_player):
		collect()


func collect() -> void:
	Data.values.score += 500
	
	NodeCreator.prepare_2d(coin_effect, self).call_method( func(eff: Node2D) -> void:
		pass
	).create_2d().bind_global_transform()
	
	Audio.play_sound(sound, self, false)
	queue_free()
