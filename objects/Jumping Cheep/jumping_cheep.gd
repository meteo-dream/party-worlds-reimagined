@tool
extends GeneralMovementBody2D
var player: Player
var stop_shooting_radius: int = 64
var triggered: bool
@export_range(0, 400, 1) var jump_strength: float = 150
@onready var initial_pos = position
const SWIM = preload("res://engine/objects/players/prefabs/sounds/swim.wav")
const WATER_SPRAY = preload("res://engine/objects/effects/sprays/water_spray.tscn")

func _physics_process(delta):
	if Engine.is_editor_hint():
		queue_redraw()
		return
	player = Thunder._current_player
	update_dir()
	if turn_sprite && sprite_node && is_instance_valid(sprite_node):
		sprite_node.flip_h = dir < 0
	if triggered:
		motion_process(delta)
		if position.y > initial_pos.y:
			position.y = initial_pos.y
			var splash = WATER_SPRAY.instantiate()
			splash.position = position + Vector2(0, -24)
			Scenes.current_scene.add_child(splash)
			triggered = false
		return
	if !player:
		return
	var jump_trigger := absf(global_transform.affine_inverse().basis_xform(player.global_position).x - global_transform.affine_inverse().basis_xform(global_position).x) <= stop_shooting_radius
	if jump_trigger:
		var gravity: float = gravity_scale * GRAVITY
		var _speed: float = sqrt(2 * gravity * jump_strength)
		jump(_speed)
		triggered = true
		Audio.play_sound(SWIM, self)
		var splash = WATER_SPRAY.instantiate()
		splash.position = position + Vector2(0, -24)
		Scenes.current_scene.add_child(splash)

func _draw() -> void:
	if !Engine.is_editor_hint(): return
	if !owner: return
	if !Thunder.View.shows_tool(self): return
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE / global_scale)
	draw_line(Vector2.ZERO, Vector2.UP * jump_strength, Color.DARK_ORANGE, 4)
