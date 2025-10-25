extends Node

@onready var player: Player = Thunder._current_player
@onready var marker = $DisappearMarker
@export var cutscene_player_speed: float = 200
var start_trans: bool = false

func _ready() -> void:
	await get_parent().ready
	player = Thunder._current_player
	player.completed = true

func _physics_process(delta: float) -> void:
	player.speed.x = cutscene_player_speed
	
	if !start_trans and player.global_position.x > marker.global_position.x:
		var tw = get_tree().create_tween()
		tw.tween_property(player, "modulate:a", 0.0, 0.2)
		start_trans = true
	
	if player.global_position.x > 256:
		cutscene_player_speed = move_toward(cutscene_player_speed, 10, delta * 80)
	if player.global_position.x > 640:
		Scenes.current_scene._start_transition()
