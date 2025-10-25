extends MenuSelection

func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
	GlobalViewport.vp.get_camera_2d().position.y -= 480
	GlobalViewport.vp.get_camera_2d().position.x += 640
	GlobalViewport.vp.get_camera_2d().reset_physics_interpolation()
	await get_tree().physics_frame
	get_parent().move_selector(0)
	Scenes.current_scene.get_node("Menu/MainMenuControls").focused = true
	Scenes.current_scene.get_node("Tweaks/SubViewportContainer/SubViewport/Tweaks/Tweaks").focused = false
	
	var _tex: String = SkinsManager.load_external_textures()
	print(_tex)
	SettingsManager.save_tweaks()
	SettingsManager.save_settings()
