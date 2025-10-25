extends ColorRect
var freqrange: float
var timer: float
func _physics_process(delta):
	timer += delta
	freqrange = sin(timer) / 8
	material.set_shader_parameter("freq", freqrange + 0.9)
