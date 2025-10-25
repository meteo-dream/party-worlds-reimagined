extends "res://engine/scripts/nodes/general_movement/circle_movement.gd"

@onready var spawn_point = $"../IdiotPoint1"
@onready var EnemyAttacked = $Body/EnemyAttacked

func _ready() -> void:
	if !EnemyAttacked: return
	EnemyAttacked.killing_enabled = false

func teleport_to_point() -> void:
	if !spawn_point: return
	center = spawn_point.position
	spawn_point.queue_free()

func _on_acid_drown_cutscene_handler_enemy_corrosion() -> void:
	teleport_to_point()


func _on_acid_drown_cutscene_handler_acid_receded() -> void:
	if !EnemyAttacked: return
	EnemyAttacked.killing_enabled = true
