extends Node2D

@onready var mario_sprite: AnimatedSprite2D = $MarioSprite
@onready var goal_sprite: Sprite2D = $GoalSprite
var pathfollow
var mario_init_position: Vector2
var distance: float
var start_fading: bool = false
var stop_following: bool = false

func _ready() -> void:
	var current_scene = Scenes.current_scene
	var path2d = current_scene.get_child(2)
	if path2d: pathfollow = path2d.get_child(0)
	
	mario_init_position = mario_sprite.position
	distance = goal_sprite.position.x - mario_init_position.x
	mario_sprite.sprite_frames = SkinsManager.apply_player_skin(CharacterManager.get_suit("small"))
	mario_sprite.play(&"walk")

func _physics_process(delta: float) -> void:
	if !pathfollow: return
	if pathfollow._stopped: return
	
	mario_sprite.position.x = mario_init_position.x + (distance * pathfollow.progress_ratio)
	
	if pathfollow.progress_ratio >= 0.98 and !start_fading:
		var tw = get_tree().create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 2.0)
		start_fading = true
