extends BossSpellcardFinal

func start_attack() -> void:
	move_boss(boss.boss_handler.global_position + Vector2(-400, -400), 1.0)
