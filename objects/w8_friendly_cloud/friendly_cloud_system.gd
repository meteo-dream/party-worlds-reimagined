extends CanvasLayer

@onready var counter = $Counter
@onready var bonus_sprite = $AnimatedSprite2D
@onready var spawn_point = $SpawnPoint
@onready var timer = $Timer
@export var initial_bonus_amount: int
@export var bonus_spawning_cloud: InstanceNode2D
var bonus_amount
var spawned_bonus: bool = false
var pathfollow
var stop_dropping_bonus: bool = false

func _ready() -> void:
	bonus_amount = clampi(initial_bonus_amount, 0, 9999)
	
	var current_scene = Scenes.current_scene
	var path2d = current_scene.get_child(2)
	if path2d: pathfollow = path2d.get_child(0)
	
	if !timer:
		return
	timer.timeout.connect(deploy_another_bonus)

func _physics_process(delta: float) -> void:
	counter.text = "~ %s" % bonus_amount
	if stop_dropping_bonus: return
	if pathfollow:
		if spawn_point:
			spawn_point.global_position.x = pathfollow.global_position.x + 500
		if pathfollow._stopped and !stop_dropping_bonus:
			var tw = get_tree().create_tween()
			tw.tween_property(bonus_sprite, "modulate:a", 0.0, 1.5)
			var tw2 = get_tree().create_tween()
			tw2.tween_property(counter, "modulate:a", 0.0, 1.5)
			stop_dropping_bonus = true
	if !Thunder.is_player_power(Data.PLAYER_POWER.SMALL) and spawned_bonus:
		spawned_bonus = false
	if timer:
		if spawned_bonus and Thunder.is_player_power(Data.PLAYER_POWER.SMALL) and timer.is_stopped():
			timer.start(7.0)
	if bonus_amount <= 0 or !Thunder.is_player_power(Data.PLAYER_POWER.SMALL): return
	if !spawned_bonus:
		if timer: timer.stop()
		
		spawn_bonus()

func spawn_bonus() -> void:
	bonus_amount -= 1
	NodeCreator.prepare_ins_2d(bonus_spawning_cloud, spawn_point).create_2d().execute_instance_script()
	spawned_bonus = true

func deploy_another_bonus() -> void:
	if bonus_amount <= 0 or !Thunder.is_player_power(Data.PLAYER_POWER.SMALL): return
	spawn_bonus()
