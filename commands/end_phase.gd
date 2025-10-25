extends Command

# Only usable when W9 Boss exists
static func register() -> Command:
	return new().set_name("end_phase").set_description("[W9 Boss Only] Ends the current boss phase")

func execute(args:Array) -> Command.ExecuteResult:
	var boss
	var children_list = Scenes.current_scene.get_children(false)
	for i in children_list.size():
		if "bossw9" in children_list[i].name.to_lower():
			boss = children_list[i]
	if !boss: return Command.ExecuteResult.new("W9 Boss does not exist here!")
	if !boss.sc_actual_timer.is_stopped():
		if boss.current_spell_used:
			boss.current_spell_used.FORCE_END_SPELLCARD = true
		boss.sc_actual_timer.stop()
		boss.end_spell_card()
		return Command.ExecuteResult.new("Success")
	else: return Command.ExecuteResult.new("Spellcard hasn't begun yet!")
