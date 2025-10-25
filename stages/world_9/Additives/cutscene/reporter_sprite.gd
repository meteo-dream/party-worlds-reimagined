extends Sprite2D
class_name CutsceneReporter

const trail = preload("res://engine/objects/effects/trail/trail.tscn")
@onready var onscreen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
var is_on_screen_sprite: bool = false
var trail_timer: float
var player: Player

func _ready() -> void:
	onscreen_notifier.screen_entered.connect(func() -> void:
		is_on_screen_sprite = true)
	onscreen_notifier.screen_exited.connect(func() -> void:
		is_on_screen_sprite = false)
	player = Thunder._current_player

# Checks if this sprite is currently on-screen.
func is_on_screen() -> bool: return is_on_screen_sprite
