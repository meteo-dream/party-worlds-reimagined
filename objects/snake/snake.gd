extends GravityBody2D

@export_category("Snake")
@export_group("Movement")
@export_subgroup("Detecting")
@export var resting_duration: float = 1.5
@export var detection_margin: float = 32
@export var detected_sound: AudioStream = preload("res://engine/objects/enemies/lakitus/sounds/lakitu_mek.ogg")
@export_subgroup("Attacking")
@export var jumping_speed: float = 500
@export_group("Attack", "attack_")
@export var attack_interval: float = 0.1
@export var attack_amount: int = 3
@export var attack_projectile: InstanceNode2D
@export var attack_projectile_speed: Vector2 = Vector2(400, 0)
@export var attack_sound: AudioStream = preload("res://engine/objects/projectiles/sounds/shoot.wav")

var tween: Tween
var player: Player

var dir: int:
	set(to):
		dir = to
		if !dir in [-1, 1]: dir = [-1, 1].pick_random()

var step: int # 0 = Detecting; 1, 2 = Attacking
var step_detect: int

@onready var y_speed: float = speed.y
@onready var grav: float = gravity_scale
@onready var pos: Vector2 = position + Vector2.DOWN.rotated(rotation) * 64

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var pos_attack: Marker2D = $PosAttack
@onready var timer_interval: Timer = $Interval
@onready var enemy_attacked: Node = $Body/EnemyAttacked
@onready var vision: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D


func _ready() -> void:
	position = pos
	speed = Vector2.ZERO
	gravity_scale = 0
	vision.scale.y = 16


func _physics_process(delta: float) -> void:
	player = Thunder._current_player
	if player:
		dir = Thunder.Math.look_at(global_position, player.global_position, global_transform)
		if dir != 0:
			sprite.flip_h = (dir > 0)
	
	_step(delta)


func _step(delta: float) -> void:
	match step:
		0:
			# Movement
			if !tween:
				tween = create_tween().set_loops()
				tween.tween_property(self, "position", pos + Vector2.UP.rotated(rotation) * 16, 16 / abs(y_speed))
				tween.tween_callback(
					func() -> void:
						enemy_attacked.stomping_enabled = true
						step_detect = 1
				)
				tween.tween_interval(resting_duration)
				tween.tween_property(self, "position", pos, 16 / abs(y_speed))
				tween.tween_callback(
					func() -> void:
						enemy_attacked.stomping_enabled = false
						if step_detect == 2:
							sprite.play(&"default")
							tween.kill()
							
							await get_tree().create_timer(0.5, false, true).timeout
							
							step = 1
							step_detect = 0
							enemy_attacked.stomping_enabled = true
							gravity_scale = grav
							tween = null
							jump(jumping_speed)
							return
						step_detect = 0
				)
				tween.tween_interval(resting_duration)
			# Detection
			if step_detect == 1 && player:
				var spos: Vector2 = global_transform.affine_inverse().basis_xform(global_position)
				var ppos: Vector2 = global_transform.affine_inverse().basis_xform(player.global_position)
				if ppos.y > spos.y - detection_margin && ppos.y < spos.y + detection_margin:
					tween.set_speed_scale(5)
					step_detect = 2
					sprite.play(&"alert")
					enemy_attacked.stomping_enabled = false
					Audio.play_sound(detected_sound, self, false)
		1, 2:
			motion_process(delta)
			
			if speed.y >= 0 && step == 1:
				step = 2
				var shoot: Tween = create_tween().set_loops(attack_amount)
				shoot.tween_callback(
					func() -> void:
						NodeCreator.prepare_ins_2d(attack_projectile, self).create_2d().call_method(
							func(proj: Node2D) -> void:
								proj.global_position = pos_attack.global_position
								if proj is Projectile: 
									proj.vel_set(attack_projectile_speed)
									proj.speed.x *= dir
									proj.belongs_to = Data.PROJECTILE_BELONGS.ENEMY
						)
						Audio.play_sound(attack_sound, self, false)
				)
				shoot.tween_interval(attack_interval)
			
			if speed.y > 0 && position.direction_to(pos).dot(up_direction) > 0:
				position = pos
				gravity_scale = 0
				speed = Vector2.ZERO
				step = 3
				enemy_attacked.stomping_enabled = false
				await get_tree().create_timer(1, false, true).timeout
				step = 0
		
