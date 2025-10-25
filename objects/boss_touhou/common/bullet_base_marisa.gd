extends BulletBase
class_name BulletBaseMarisa

# Marisa's rainbow bullets. Bullet erase color is determined
# by the field below, regardless of what it is set to in the editor.
@export var accelerate_at_start: bool = false
@export var accelerate_after_sec: float = 1.0
@export var accelerate_time_sec: float = 1.0
@export_category("Bullet Details - Extra")
@export_enum("Violet: 0", "Red: 1", "Gold: 2", "Lime Yellow: 3", "Green: 4", "Blue: 5", "Cyan: 6") var selected_color: int = 2
@export var color_list: Array[Color] = [Color.VIOLET, Color.RED, Color.GOLD, Color.YELLOW, Color.GREEN, Color.BLUE, Color.CYAN]
@export var sprite_anim_list: Array[int] = [4, 2, 14, 13, 11, 6, 8]
@export var appear_anim_list: Array[int] = [2, 1, 6, 6, 5, 3, 4]
@export var self_rotate_speed: float = 0.05
@export_enum("Right: 0", "Left: 1") var self_rotate_direction: int = 0

func _ready() -> void:
	super()
	bullet_erase_color = color_list[clamp(selected_color, 0, color_list.size() - 1)]
	bullet_sprite.frame_coords.x = sprite_anim_list[clamp(selected_color, 0, sprite_anim_list.size() - 1)]
	if is_instance_valid(appear_sprite): appear_sprite.frame_coords.x = appear_anim_list[clamp(selected_color, 0, appear_anim_list.size() - 1)]
	if accelerate_at_start:
		actual_vel = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if self_rotate_speed != 0.0:
		rotation += absf(self_rotate_speed) + (-1.0 * (self_rotate_speed * 2)) * self_rotate_direction
	super(delta)

func enable_movement() -> void:
	if !accelerate_at_start:
		super()
		return
	await get_tree().create_timer(accelerate_after_sec, false).timeout
	allow_movement = true
	var tw = get_tree().create_tween()
	tw.tween_property(self, "actual_vel", veloc, accelerate_time_sec)
