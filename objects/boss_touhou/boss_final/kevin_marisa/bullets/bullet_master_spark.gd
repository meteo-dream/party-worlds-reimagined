extends BulletBase

var desired_scale: Vector2 = Vector2(1.0, 1.0)
var allow_offscreen_cull: bool = false

func _ready() -> void:
	super()
	appear_animation()

func appear_animation() -> void:
	scale = Vector2(0.0, 0.0)
	var tw = get_tree().create_tween()
	tw.tween_property(self, "scale", desired_scale, 0.01)
	await get_tree().create_timer(4.0, false).timeout
	allow_offscreen_cull = true

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	allow_offscreen_cull = true
	super()

func delete_self(autodelete: bool = false, offscreen: bool = false) -> void:
	if autodelete and !allow_offscreen_cull: return
	super(autodelete, offscreen)
