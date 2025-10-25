extends BulletBaseMarisa

@export var use_as_warning: bool = false
@export var desired_scale: float = 1.0
@export var wait_time: float = 0.5
@export var resize_time: float = 0.5
@export var life_time: float = 1.0
@export var disappear_time: float = 0.5

func _ready() -> void:
	force_disable_collision = true
	bullet_erase_color = color_list[clamp(selected_color, 0, color_list.size() - 1)]
	bullet_sprite.region_rect.position.x = 16.0 * sprite_anim_list[clamp(selected_color, 0, sprite_anim_list.size() - 1)]
	scale.x = 0.05
	if !use_as_warning:
		appear_animation()
	else:
		await get_tree().create_timer(life_time, false).timeout
		disappear_animation(true)

func appear_animation() -> void:
	await get_tree().create_timer(wait_time, false).timeout
	var tw = get_tree().create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(self, "scale:x", desired_scale, resize_time)
	tw.tween_callback(activate_laser)

func disappear_animation(use_alt_anim: bool = false) -> void:
	var tw = get_tree().create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	if !use_as_warning:
		tw.tween_property(self, "scale:x", 0.0, disappear_time)
	else:
		tw.tween_property(self, "modulate:a", 0.0, disappear_time)
	tw.tween_callback(delete_self_laser)

func activate_laser() -> void:
	force_disable_collision = false
	await get_tree().create_timer(life_time, false).timeout
	force_disable_collision = true
	disappear_animation()

func delete_self_laser() -> void:
	queue_free()
