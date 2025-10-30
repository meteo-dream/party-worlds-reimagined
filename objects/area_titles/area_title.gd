extends Control

@export_multiline var name_of_area_text: String

var player_in: Player
var tween: Tween

@onready var area_name: Label = $HUD/AreaName


func _ready() -> void:
	area_name.text = name_of_area_text.to_upper()


func _physics_process(delta: float) -> void:
	if tween:
		return
	
	var player: Player = Thunder._current_player
	if !player || player.is_dying:
		return
	
	var is_player_in: bool = get_rect().has_point(player.global_position)
	if !player_in && is_player_in:
		area_name.modulate.a = 0
		# Animation
		tween = create_tween().set_parallel(true)
		tween.tween_property(area_name, ^"position:y", 80.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(area_name, ^"modulate:a", 1.0, 0.5)
		tween.tween_interval(2)
		tween.chain().tween_property(area_name, ^"position:y", 32.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(area_name, ^"modulate:a", 0.0, 0.5)
		await tween.finished
		tween = null
		player_in = player
	elif player_in && !is_player_in:
		player_in = null
