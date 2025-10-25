extends StaticBody2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func _on_path_follow_2d_scroll_stopped() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
