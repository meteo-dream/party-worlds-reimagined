extends "res://engine/components/hud/hud.gd"

func time_countdown(_first_time: bool = true) -> void:
	if _first_time: _time_countdown_sound_loop()
	
	if SettingsManager.get_tweak("faster_end_timer", false):
		if Data.values.time > 500:
			Data.values.time -= 500
			Data.add_score(5000)
		elif Data.values.time > 100:
			Data.values.time -= 100
			Data.add_score(1000)
		elif Data.values.time > 20:
			Data.values.time -= 20
			Data.add_score(200)
		elif Data.values.time > 10:
			Data.values.time -= 10
			Data.add_score(100)
		else: default_countdown()
	else: default_countdown()
	
	if Data.values.time > 0:
		Data.values.time -= 1
		Data.add_score(10)
		
		#incredibly fast but idk if I should implement this
		#if SettingsManager.get_tweak("faster_timer", false):
		#	Data.add_score(Data.values.time * 10)
		#	Data.values.time = 0
		
		await get_tree().create_timer(0.01, false, true).timeout
		time_countdown(false)
	else:
		time_countdown_finished.emit()

func default_countdown() -> void:
	if Data.values.time > 6:
		Data.values.time -= 3
		Data.add_score(30)
