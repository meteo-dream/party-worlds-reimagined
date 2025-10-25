extends Node2D
class_name ViewfinderEff

@export var interp_travel: bool = true
@export var distance: float = 0.0
@export var distance_travel_time: float = 0.5
@export var track_player: bool = true
@export var lock_rotation: bool = false
@export var angle: float = 0.0
@export var rotation_offset: float = 0.0
@export var alt_sprite: bool = false
var actual_distance: float
var boss: W9Boss
@onready var viewfinder_sprite: Sprite2D = $Viewfinder
@onready var circle_ring_sprite: Sprite2D = $Circle

func _ready() -> void:
	if !interp_travel: actual_distance = distance
	else: _appear_interp()
	
	if !alt_sprite:
		viewfinder_sprite.region_rect = Rect2(0, 0, 46, 62)
		rotation_offset -= deg_to_rad(90)
	else:
		viewfinder_sprite.region_rect = Rect2(46, 0, 68, 44)

func _appear_interp() -> void:
	modulate.a = 0.0
	var tw_trans = get_tree().create_tween()
	tw_trans.tween_property(self, "modulate:a", 1.0, 0.3)
	var tw = get_tree().create_tween()
	tw.set_trans(Tween.TRANS_CIRC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "actual_distance", distance, distance_travel_time)

func _physics_process(delta: float) -> void:
	global_rotation = angle + rotation_offset
	if !is_instance_valid(boss):
		delete_self()
		return
	if track_player and !lock_rotation: angle = boss.current_spell_used.aim_at_player()
	var distance_vector = Vector2(actual_distance * cos(angle), actual_distance * sin(angle))
	global_position = boss.global_position + distance_vector

func lock_aim() -> void:
	lock_rotation = true
	if is_instance_valid(circle_ring_sprite): circle_ring_sprite.stop_spin = true

func _disappear_anim(is_instant: bool = false) -> void:
	var disappear_time: float = 0.3
	if is_instant: disappear_time = 0.05
	var tw = get_tree().create_tween()
	tw.tween_property(self, "modulate:a", 0.0, disappear_time)
	tw.tween_callback(delete_self)

func delete_self() -> void:
	queue_free()
