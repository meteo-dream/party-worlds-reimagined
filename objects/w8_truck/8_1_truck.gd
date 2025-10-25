class_name W8Truck
extends "res://engine/objects/platform/platform_path.gd"

@onready var internal_block = $Block
var truck_body

func _ready() -> void:
	var children_list: Array = internal_block.get_children(false)
	for i in children_list.size():
		var children_script = children_list[i].get_script()
		if children_script and children_script.get_global_name() == "W8TruckBody":
			truck_body = children_list[i]

func speed_up_truck() -> void:
	truck_body.speed_up_truck()

func slow_down_truck() -> void:
	truck_body.slow_down_truck()

func reset_truck_speed() -> void:
	truck_body.reset_truck_speed()

func stop_truck() -> void:
	speed = 0.0
	truck_body.stop_truck()
