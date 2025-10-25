extends "res://engine/scripts/nodes/general_movement/circle_movement.gd"

@onready var EnemyAttacked = $Body/EnemyAttacked

func _ready() -> void:
	if !EnemyAttacked: return
	EnemyAttacked.killing_enabled = false

func _on_acid_drown_cutscene_handler_enemy_corrosion() -> void:
	queue_free()
