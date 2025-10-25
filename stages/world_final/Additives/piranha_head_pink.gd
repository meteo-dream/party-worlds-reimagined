extends "res://engine/objects/enemies/piranha_plants/piranha_head.gd"

@export var custom_vars: Dictionary
@export var custom_script: Script

@export var attack_interval: float = 0.5
@export var attack_thrower: InstanceNode2D
@export var attack_amount: int = 1
@export var attack_times: int = 1
@export var attack_sound: AudioStream
@export var projectile_remove_from_top: bool = false
@export var projectile_collision: bool = false
@export var projectile_speed_min: Vector2 = Vector2(-200.0, -250.0)
@export var projectile_speed_max: Vector2 = Vector2(200.0, -550.0)
@export var projectile_gravity_scale: float = 0.2
@export var projectile_speed_correction: bool = true
@export var projectile_offscreen_time: float = 3.0

@onready var timer: Timer = $Fire
var attacked_times
var visible_on_screen: bool = false
var timer_started: bool = false

func _ready() -> void:
	if !timer:
		print("there's no timer stfu")
		return
	timer.timeout.connect(_shoot)

func _physics_process(delta: float) -> void:
	super(delta)
	if visible_on_screen and !timer_started:
		timer.start(attack_interval)
		timer_started = true

func _shoot() -> void:
	timer_started = false
	
	for i in attack_amount:
		NodeCreator.prepare_ins_2d(attack_thrower, self).call_method(func(ball: Node2D) -> void:
			if ball is GravityBody2D:
				var speed_corrected: Vector2 = Vector2.ONE
				if projectile_speed_correction:
					speed_corrected.x = cos(rotation) / 2 + 0.5
					speed_corrected.y = cos(rotation) / 4 + 0.75
				
				var ball_speed: Vector2
				if get("projectile_integer_speed"):
					ball_speed = Vector2(
						Thunder.rng.get_randi_range(
							floori(projectile_speed_min.x / 50),
							floori(projectile_speed_max.x / 50),
						),
						Thunder.rng.get_randi_range(
							floori((projectile_speed_min.y * speed_corrected.x) / 50),
							floori((projectile_speed_max.y * speed_corrected.y) / 50)
						),
					) * 50
				else:
					ball_speed = Vector2(
						Thunder.rng.get_randf_range(
							projectile_speed_min.x,
							projectile_speed_max.x
						),
						Thunder.rng.get_randf_range(
							projectile_speed_min.y * speed_corrected.x,
							projectile_speed_max.y * speed_corrected.y
						),
					)
				
				ball.rotation = 0.0
				ball.speed = ball_speed.rotated(rotation)
				ball.gravity_scale = projectile_gravity_scale
			
			if &"belongs_to" in ball: ball.belongs_to = Data.PROJECTILE_BELONGS.ENEMY
			
			if !projectile_collision && ball is CollisionObject2D:
				ball.set_collision_mask_value(7, false)
			
			if &"vision" in ball:
				ball.expand_vision(Vector2(8, 8))
			if projectile_offscreen_time && "remove_offscreen_after" in ball:
				ball.remove_offscreen_after = projectile_offscreen_time
			if projectile_remove_from_top && "remove_top_offscreen" in ball:
				ball.remove_top_offscreen = projectile_remove_from_top
		).create_2d()
	
	Audio.play_sound(attack_sound, self, false)


func _on_vision_screen_entered() -> void:
	visible_on_screen = true


func _on_vision_screen_exited() -> void:
	visible_on_screen = false
