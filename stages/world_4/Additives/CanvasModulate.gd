extends CanvasModulate
@onready var generator = $"../generator"
var easer: bool = false
var is_black: bool = false
var state: int = 0
var counter: float = 1

var limits: Rect2i
var speed: float = 0.04
var function: Thunder.SmoothFunction = Thunder.SmoothFunction.EASE_IN_OUT

func _physics_process(delta: float) -> void:
	if easer:
		counter += speed * Thunder.get_delta(delta)
		counter = clamp(counter, 0, 1)
	
	var eased_counter: float
	eased_counter = Thunder.Math.ease_in_out(counter)
	
	color.v = max(-eased_counter + 1, 0.20) if is_black else max(eased_counter, 0.1)
	if counter == 1:
		easer = false

func _ready():
	visible = true
	color.v = 1
	await get_tree().physics_frame
	easer = false
	counter = 1
	color.v = 1


func _on_cam_area_view_section_changed(): # lower
	easer = true
	is_black = true
	counter = 0
	generator.active = true

func _on_camera_area_view_section_changed(): # upper
	easer = true
	is_black = false
	counter = 0
	await get_tree().physics_frame
	generator.active = false

func _on_cam_area_2_view_section_changed(): # upper2
	easer = true
	is_black = false
	counter = 0
	await get_tree().physics_frame
	generator.active = false
