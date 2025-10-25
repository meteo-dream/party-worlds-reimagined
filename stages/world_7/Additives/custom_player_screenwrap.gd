extends Node

@export var screenwrap_height: int = 512
@export var screen_top: int = -16

# I don't know how to properly implement screenwrap so a crutch it is
# If there's proper vertical screenwrap implemented,
# remove the ceiling tiles spammed all over the place.
func _physics_process(delta: float) -> void:
	var player: Player = Thunder._current_player
	var has_wrapped: bool = false
	var modified_screen_top = screen_top - 2
	if !player: return
	
	if Thunder.is_player_power(Data.PLAYER_POWER.SMALL):
		if player.position.y < modified_screen_top:
			player.position.y += screenwrap_height + 6
			has_wrapped = true
		elif player.position.y >= screen_top - 1 + screenwrap_height:
			player.position.y -= screenwrap_height
			has_wrapped = true
	else:
		if player.position.y <= screen_top * 2:
			player.position.y += screenwrap_height + absi(screen_top * 2)
			has_wrapped = true
		elif player.position.y >= screenwrap_height + absi(screen_top):
			player.position.y -= screenwrap_height + absi(screen_top)
			has_wrapped = true
	
	if has_wrapped: player.reset_physics_interpolation()
