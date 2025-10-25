extends Node

@onready var player = Thunder._current_player
@onready var hitbox = $Sprite2D
@onready var hitbox_deco = $Sprite2D/Sprite2D2
var disable_hitbox: bool = true
var hitbox_hidden: bool = false
var tw: Tween

func _ready() -> void:
	if !player or !hitbox: return
	hitbox.z_index = player.z_index + 6
	player.died.connect(delete_hitbox)

func _physics_process(delta: float) -> void:
	if !player or !hitbox or disable_hitbox: return
	hitbox.global_position = player.global_position
	hitbox.reset_physics_interpolation()
	hitbox.rotate(0.05)
	hitbox_deco.rotate(-0.1)
	
	if player.running and !hitbox_hidden:
		hitbox_hidden = true
		hide_hitbox()
	if !player.running and hitbox_hidden:
		hitbox_hidden = false
		show_hitbox()

func delete_hitbox() -> void:
	queue_free()

func hide_hitbox() -> void:
	if tw: tw.kill()
	tw = create_tween()
	tw.tween_property(hitbox, "modulate:a", 0.0, 0.2)
	return

func show_hitbox() -> void:
	if tw: tw.kill()
	tw = create_tween()
	tw.tween_property(hitbox, "modulate:a", 1.0, 0.2)
	return
