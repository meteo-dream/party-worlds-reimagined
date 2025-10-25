extends Command

# Only usable when W9 Boss exists
static func register() -> Command:
	return new().set_name("toggle_alt_boss").set_description("[W9 Boss Only] Forces the secret boss to appear for the current character. Not available if the battle has already started")

func execute(args:Array) -> Command.ExecuteResult:
	var boss
	var boss_handler
	var children_list = Scenes.current_scene.get_children(false)
	for i in children_list.size():
		if "bossw9" in children_list[i].name.to_lower():
			boss = children_list[i]
		if "bossw9handler" in children_list[i].name.to_lower():
			boss_handler = children_list[i]
	if !boss or !boss_handler: return Command.ExecuteResult.new("W9 Boss does not exist here!")
	if boss.boss_mode_engaged: return Command.ExecuteResult.new("The battle has already started. Cannot change boss!")
	CustomGlobals.w9_alt_boss = !CustomGlobals.w9_alt_boss
	boss.hatate_mode = CustomGlobals.check_for_hatate_boss()
	if boss.hatate_mode:
		boss.boss_sprite.sprite_frames = boss.HATATE_SPRITES
	else: boss.boss_sprite.sprite_frames = boss.AYA_SPRITES
	boss.boss_sprite.play(&"default")
	boss_handler._special_check_boss_name()
	
	var console_msg: String
	if !CustomGlobals.check_for_hatate_boss(): console_msg = "Opponent: AYA SHAMEIMARU"
	else: console_msg = "Opponent: HATATE HIMEKAIDOU"
	
	return Command.ExecuteResult.new(console_msg)
