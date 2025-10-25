extends Node2D
const BEETROOT_GRAB = preload("res://modules/beetroot-grab/beetroot-grab.tscn")
var beetroot_instance

func _ready() -> void:
	visible = false

func _physics_process(delta: float) -> void:
	if !is_instance_valid(beetroot_instance):
		spawner()

func spawner():
	var instance = BEETROOT_GRAB.instantiate()
	instance.global_position = global_position + Vector2(0, 32)
	Scenes.current_scene.add_child.call_deferred(instance)
	instance.collision = false
	instance.z_index = -1
	var initial_gravity = instance.gravity_scale
	instance.gravity_scale = 0
	beetroot_instance = instance
	var tween = create_tween()
	tween.tween_property(instance, "global_position:y", global_position.y, 1)
	await tween.finished
	instance.collision = true
	instance.gravity_scale = initial_gravity
	instance.z_index = 0
