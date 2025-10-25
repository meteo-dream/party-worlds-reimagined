extends BulletBase
class_name SpawnerBullet

@export_group("Secondary Bullet Properties", "2bullet_")
@export var bullet_type: PackedScene
@export var bullet_move_final_speed: float = 250.0
@export var bullet_angle: float = 90.0
var boss: FinalBoss
@onready var interval_timer: Timer = $Timer
var sub_bullet_angle: float
var sub_bullet_move_final_speed: float
var actual_interval_time: float
var start_spawning_sub: bool = false

func _ready() -> void:
	sub_bullet_angle = deg_to_rad(bullet_angle)
	sub_bullet_move_final_speed = bullet_move_final_speed
	super()
	await get_tree().create_timer(0.2, false).timeout
	start_spawning_sub = true

func _physics_process(delta: float) -> void:
	super(delta)
	if !is_instance_valid(interval_timer) or !start_spawning_sub: return
	if interval_timer.time_left <= 0:
		interval_timer.start(0.33)
		if check_spawn_bounds():
			var new_velocity: Vector2 = Vector2(sub_bullet_move_final_speed * cos(sub_bullet_angle), sub_bullet_move_final_speed * sin(sub_bullet_angle))
			spawn_child_bullet(new_velocity)

func check_spawn_bounds() -> bool:
	if !is_instance_valid(boss):
		print("CANNOT DETECT BOUNDS")
		return false
	if global_position.x > boss.boss_handler.global_position.x + 320: return false
	if global_position.x < boss.boss_handler.global_position.x - 320: return false
	if global_position.y > boss.boss_handler.global_position.y + 240: return false
	if global_position.y < boss.boss_handler.global_position.y - 240: return false
	return true

func spawn_child_bullet(new_velocity: Vector2) -> void:
	if !is_instance_valid(bullet_type): return
	var bullet_shot = bullet_type.instantiate()
	bullet_shot.rotation = 0.0
	bullet_shot.target_velocity = new_velocity
	Scenes.current_scene.add_child(bullet_shot)
	if is_instance_valid(boss):
		boss.bullet_pool.append(bullet_shot)
	bullet_shot.appear_animation()
	bullet_shot.z_index = z_index
	bullet_shot.global_position = global_position
	bullet_shot.reset_physics_interpolation()
	bullet_shot.enable_movement()
