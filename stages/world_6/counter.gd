extends Label
@onready var locker: Node2D = $"../../../locker"
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	text = str(locker.get_child_count())
	
	if text == "0":
			get_parent().modulate.a -= 3 * delta
