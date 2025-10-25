extends Area2D

@export var new_speed: float
@export var speed_change_time: float
@export var the_truck: Node2D

func _ready() -> void:
	#$Text.queue_free()
	
	body_entered.connect(
		func(truck: Node2D) -> void:
			var tw = get_tree().create_tween()
			tw.tween_property(the_truck, "speed", new_speed, speed_change_time)
	)
