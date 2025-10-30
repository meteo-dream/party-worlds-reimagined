@tool
extends CanvasLayer

var now_playing_text: String = tr('NOW PLAYING: \n%s')

enum DisplayingMode {
	ROLL_IN_OUT,
	TYPER
}

@export var displaying_mode: DisplayingMode = DisplayingMode.ROLL_IN_OUT
@export var display_text: String

var current_scene

var id: int = 0

@onready var music_text: Label = $MusicText
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if Engine.is_editor_hint(): return
	current_scene = Scenes.current_scene
	
	if current_scene is Map2D:
		current_scene.player_entered_level.connect(
			func():
				animation_player.speed_scale = 10
				var tw: Tween = create_tween().set_trans(Tween.TRANS_SINE)
				tw.tween_property(music_text, ^"modulate:a", 0, 1.0)
		)
	
	play(0)


func play(index: int = 0) -> void:
	if is_instance_valid(music_text):
		music_text.text = now_playing_text % display_text
	while is_inside_tree() && !animation_player:
		await get_tree().physics_frame
	animation_player.play(
		&"showing_roll" if displaying_mode == DisplayingMode.ROLL_IN_OUT else &"showing_typer"
	)
