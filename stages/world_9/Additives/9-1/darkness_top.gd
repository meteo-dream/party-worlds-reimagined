extends Sprite2D


func _on_camera_area_view_section_changed_with_section(section: Control) -> void:
	show()


func _on_camera_area_2_view_section_changed_with_section(section: Control) -> void:
	show()


func _on_camera_area_bonus_view_section_changed_with_section(section: Control) -> void:
	hide()
