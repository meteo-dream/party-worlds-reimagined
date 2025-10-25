extends GeneralMovementBody2D

const DEFAULT_APPEARING_SOUND = preload("res://engine/objects/bumping_blocks/_sounds/appear.wav")
const DEFAULT_POWERUP_SOUND = preload("res://engine/objects/players/prefabs/sounds/powerup.wav")
const DEFAULT_NEUTRAL_SOUND = preload("res://engine/objects/players/prefabs/sounds/powerup.wav")

signal collected
signal collected_changed_suit

@export var spiny_creation: InstanceNode2D
@export var rotation_speed: float = 25.0
@export var free_offscreen: bool = false

@onready var solid_checker: Area2D = $SolidChecker
@onready var col: CollisionShape2D = $Collision
@onready var visible_on_screen_enabler_2d: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D
@onready var body: Area2D = $Body

@export_group("Powerup Settings")
@export var to_suit: String = "super"
@export var force_powerup_state: bool = false
@export var appear_distance: float = 32
@export var appear_speed: float = 0.5
@export var appear_visible: float = 27
@export var appear_collectable: float = 20
@export var score: int = 1000


@export_group("SFX")
@export_subgroup("Sounds")
@export var appearing_sound: AudioStream = DEFAULT_APPEARING_SOUND
@export var pickup_powerup_sound: AudioStream = DEFAULT_POWERUP_SOUND
@export var pickup_neutral_sound: AudioStream = DEFAULT_NEUTRAL_SOUND
@export_subgroup("Sound Settings")
@export var sound_pitch: float = 1.0

var collision_enabled: bool = false
var _is_ready: bool = false

func _ready() -> void:
	if free_offscreen:
		visible_on_screen_enabler_2d.screen_exited.connect(queue_free)
	for i in 2:
		await get_tree().physics_frame
	_is_ready = true

func _physics_process(delta: float) -> void:
	super(delta)
	get_node(sprite).rotation_degrees += rotation_speed * Thunder.get_delta(delta)
	if !_is_ready: return
	
	if !collision_enabled:
		if solid_checker.get_overlapping_bodies().size() == 0:
			collision_enabled = true
			col.set_deferred(&"disabled", false)
	
	if collision_enabled && is_on_floor():
		_create_spiny.call_deferred()
	
	var player: Player = Thunder._current_player
	if !player: return
	var overlaps: bool = body.overlaps_body(player)
	if overlaps: collect()

func collect() -> void:
	_change_state_logic(force_powerup_state)

	if score > 0:
		ScoreText.new(str(score), self)
		Data.add_score(score)

	queue_free()

func _change_state_logic(force_powerup: bool) -> void:
	var player: Player = Thunder._current_player
	var to: PlayerSuit = CharacterManager.get_suit(to_suit)
	if !to: return
	
	var powerup_sfx: AudioStream
	var neutral_sfx := CharacterManager.get_sound_replace(pickup_neutral_sound, DEFAULT_NEUTRAL_SOUND, "powerup_no_transform", true)
	
	if force_powerup:
		if to.name != Thunder._current_player_state.name:
			player.change_suit(to)
			powerup_sfx = CharacterManager.get_sound_replace(pickup_powerup_sound, pickup_powerup_sound, "powerup", true)
			Audio.play_sound(powerup_sfx, self, false, {pitch = sound_pitch, ignore_pause = true})
			collected_changed_suit.emit()
		collected.emit()
		return

	if (
		to.type > Thunder._current_player_state.type || (
			to.name != Thunder._current_player_state.name &&
			to.type == Thunder._current_player_state.type
		)
	):
		if Thunder._current_player_state.type < to.type - 1:
			player.change_suit(to.gets_hurt_to)
		else:
			player.change_suit(to)
		powerup_sfx = CharacterManager.get_sound_replace(pickup_powerup_sound, pickup_powerup_sound, "powerup", true)
		Audio.play_sound(powerup_sfx, self, false, {pitch = sound_pitch, ignore_pause = true})
		collected_changed_suit.emit()
	else:
		Audio.play_sound(neutral_sfx, self, false, {pitch = sound_pitch})
	collected.emit()

func _create_spiny() -> void:
	if is_queued_for_deletion():
		#print("Spiny egg queued for deletion, cancelling spiny creation!")
		return
	NodeCreator.prepare_ins_2d(spiny_creation, self).create_2d().call_method(func(node):
		pass)
	queue_free()
