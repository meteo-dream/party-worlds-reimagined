extends AnimatedSprite2D

const trail = preload("res://engine/objects/effects/trail/trail.tscn")
@onready var onscreen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
var is_on_screen_sprite: bool = false
@export var use_trail: bool = false
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

func _physics_process(delta: float) -> void:
	if !is_instance_valid(player) or !use_trail or !is_on_screen_sprite or player.get_tree().paused: return
	# Trail effect
	if trail_timer > 0.0: trail_timer -= 1 * Thunder.get_delta(delta)
	if trail_timer <= 0.0:
		trail_timer = 1.5
		Effect.trail(
			self,
			self.sprite_frames.get_frame_texture(self.animation, self.frame),
			Vector2.ZERO,
			flip_h,
			flip_v,
			true,
			0.05,
			1.0,
			null,
			1,
			true,
			CanvasItem.TEXTURE_FILTER_NEAREST
		)
