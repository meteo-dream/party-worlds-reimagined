extends GeneralMovementBody2D
const explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
const STUN = preload("res://engine/objects/projectiles/sounds/stun.wav")
var bounces: int
var check_for_speed: bool = false
@export var bounce_limit: int = 5
@onready var player: Player = Thunder._current_player
@onready var grabbable_modifier: Node = $GrabbableModifier

func process_bumping_blocks() -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.collision_mask = collision_mask
	query.motion = Vector2(clamp(speed_previous.x, -1, 1), clamp(speed_previous.y, -1, 1)).rotated(global_rotation)
	
	for i in get_shape_owners():
		query.transform = (shape_owner_get_owner(i) as Node2D).global_transform
		for j in shape_owner_get_shape_count(i):
			query.shape = shape_owner_get_shape(i, j)
			
			var cldata: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query)
			
			for k in cldata:
				var l: Object = k.get(&"collider", null)
				#var id: int = k.get(&"collider_id", 0)
				
				if l is StaticBumpingBlock:
					if l.has_method(&"got_bumped"):
						l.got_bumped.call_deferred(false)
					elif l.has_method(&"bricks_break"):
						l.bricks_break.call_deferred()

func _physics_process(delta: float):
	
	super(delta)
	speed.x = move_toward(speed.x, 0, 350 * delta)
	
	if is_instance_valid(player) && player.no_movement:
		speed.x = 0
		speed.y = 0
		
	if is_on_floor() && speed_previous.y > 100 && collision:
		speed.y = speed_previous.y * -0.75
		bounces += 1
		process_bumping_blocks()
		Audio.play_sound(STUN, self)
		NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform().call_method(func(node):
			node.position.y += 12
		)
		
	if is_on_wall() && collision:
		speed.x = speed_previous.x * -1
		bounces +=1
		process_bumping_blocks()
		Audio.play_sound(STUN, self)
		NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform().call_method(func(node):
			node.position.x += 12 * (1 if speed_previous.x > 0 else -1)
		)
		
	if bounces == bounce_limit:
		stop_collision()
	elif check_for_speed && is_on_floor() && abs(speed.y) < 30:
		stop_collision()
	
	
	Thunder.view.cam_border()
	if global_position.y > Thunder.view.border.end.y + 64:
		queue_free()

func stop_collision() -> void:
	collision = false
	remove_from_group(&"#top_grabbable")
	remove_from_group(&"#side_grabbable")

func _ungrabbed() -> void:
	check_for_speed = true
	bounces = 0
	set_deferred("collision_layer", 0b1100000)
