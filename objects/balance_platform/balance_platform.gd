extends AnimatableBody2D

@export_category("Balance Platform")
@export var player_gravity_weight: float = 1.0 # Determines how heavy the player is and will affect the angular acceleration
@export var balance_weight: float = 75.0 # Determines how important a unit of length that one object offsets from the center affects the matrix of force
@export var rotation_damp: float = 1.0 # Determines the angular deceleration when no objects on the stick
@export var gravity_affection: float = 50.0 # 1 gravity scale => n angular acceleration
@export var angle_max: Vector2 = Vector2(-45.0, 45.0) # The maximum that the stick can rotate, x for left, y for right sides

var objects_on: Array[Node]
var rotation_accleration: float

@onready var detector: ShapeCast2D = $ShapeCast2D


func _physics_process(delta: float) -> void:
	_balance(delta)
	_damp(delta)
	
	rotation += deg_to_rad(rotation_accleration)
	rotation = clampf(rotation, deg_to_rad(angle_max.x), deg_to_rad(angle_max.y) )
	global_rotation = global_rotation


func _balance(delta: float) -> void:
	var average_offset := 0.0
	var average_gravity := 0.0
	var player: Player = Thunder._current_player
	
	objects_on.clear()
	
	for i in detector.get_collision_count():
		var collider: Node2D = detector.get_collider(i)
		if collider == player || (collider is GravityBody2D && collider.is_on_floor()) || (collider is RigidBody2D):
			objects_on.append(collider)
	
	if !objects_on.is_empty():
		for i in objects_on:
			if !is_instance_valid(i):
				continue
			average_offset += i.position.x - position.x
			if i is GravityBody2D:
				average_gravity += i.gravity_scale
			elif i is RigidBody2D:
				average_gravity += clamp(average_gravity, i.mass * 0.01, INF) * gravity_affection
			elif i == player:
				average_gravity += player_gravity_weight
		average_offset /= objects_on.size()
		average_gravity /= objects_on.size()
	
	if !objects_on.is_empty():
		rotation_accleration = lerpf(rotation_accleration, abs(average_gravity) * average_offset * (1 / balance_weight) * gravity_affection * delta, 0.125)


func _damp(delta:float) -> void:
	if !objects_on.is_empty(): return
	rotation_accleration = move_toward(rotation_accleration,0,rotation_damp * delta)
