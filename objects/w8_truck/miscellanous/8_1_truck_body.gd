class_name W8TruckBody
extends Node2D

@export var collision_enabled: bool = false
@export var stop_wheels_on_scene_start: bool = false
var wheels: Array

func _ready() -> void:
	var children_list: Array = get_children(false)
	for i in children_list.size():
		var children_script = children_list[i].get_script()
		if children_script and children_script.get_global_name() == "TankWheel":
			wheels.append(children_list[i])
		elif children_list[i].get_class() == "TileMapLayer":
			children_list[i].collision_enabled = collision_enabled
	
	if stop_wheels_on_scene_start: stop_truck()

func speed_up_truck() -> void:
	for i in wheels.size():
		wheels[i].speed_up()

func slow_down_truck() -> void:
	for i in wheels.size():
		wheels[i].slow_down()

func reset_truck_speed() -> void:
	for i in wheels.size():
		wheels[i].reset_speed()

func stop_truck() -> void:
	if wheels:
		for i in wheels.size():
			wheels[i].stop_rolling()
