extends W9BossHUD
class_name FinalBossHUD

# Main Boss Name is used for the first boss.
# Secret Boss Name is used for the second.
# Transition Boss Name is for the purple bitch that shows up.
# Final phase is self-explanatory.
const SPELL_CUTIN_FINAL = preload("res://objects/boss_touhou/boss_final/spell_cutin_final.tscn")

@export_category("Final Boss Settings")
@export var transition_boss_name = "PATCHOULI KNOWLEDGE"
@export var final_phase_name = "REMILIA & MARISA?"
@export var show_spell_count: bool = false
var force_end_disappear: bool = false
var current_boss_phase: int = 0

func _ready() -> void:
	if !show_spell_count: spellcard_count.hide()
	if is_instance_valid(spellcard_count): spellcard_count.queue_free()
	super()

func update_time_counter(timer: float = 0.0) -> void:
	if !is_instance_valid(spellcard_timecounter): return
	spellcard_timecounter.timer_value = clampf(timer, 0.0, 99.99)
	spellcard_timecounter.text = spellcard_timecounter.text_template % spellcard_timecounter.timer_value
	spellcard_timecounter._check_timer()

func check_boss_name() -> void:
	boss_name_label.text = main_boss_name

func change_boss_name(phase: int = 0) -> void:
	boss_name_label.disappear()
	await get_tree().create_timer(0.2, false).timeout
	var new_boss_name: String
	match phase:
		0:
			new_boss_name = main_boss_name
			current_boss_phase = 0
		1:
			new_boss_name = secret_boss_name
			current_boss_phase = 1
		2: new_boss_name = transition_boss_name
		3:
			new_boss_name = final_phase_name
			current_boss_phase = 2
		_: pass
	boss_name_label.text = new_boss_name
	if force_end_disappear: return
	boss_name_label.appear()

func spell_card_declare_name(the_name: String = "Default Sign \"Default Name\"", do_cutin: bool = true) -> void:
	#print("Spellcard: " + the_name)
	if do_cutin: _spell_cutin_anim(clamp(current_boss_phase, 0, 2))
	_spell_name_anim(the_name)

func _spell_cutin_anim(type: int = 0) -> void:
	match type:
		0: _the_actual_cutin()
		1: _the_actual_cutin(true)
		2:
			_the_actual_cutin(false, true)
			_the_actual_cutin(true, true)

func _the_actual_cutin(alt_portrait: bool = false, together: bool = false) -> void:
	if !alt_portrait and together:
		var spell_cutin_portrait2 = SPELL_CUTIN_FINAL.instantiate()
		spell_cutin_portrait2.starting_pos = Vector2(1280.0, 300.0)
		spell_cutin_portrait2.target_pos = Vector2(500.0, 300.0)
		spell_cutin_portrait2.use_alt_portrait = alt_portrait
		add_child(spell_cutin_portrait2)
		spell_cutin_portrait2.z_index = -49
		return
	
	if is_instance_valid(spell_cutin_portrait):
		spell_cutin_portrait.queue_free()
	spell_cutin_portrait = SPELL_CUTIN_FINAL.instantiate()
	spell_cutin_portrait.starting_pos = Vector2(1280.0, 300.0)
	spell_cutin_portrait.target_pos = Vector2(500.0, 300.0)
	if together: spell_cutin_portrait.target_pos -= Vector2(270.0, 0.0)
	if alt_portrait: spell_cutin_portrait.target_pos -= Vector2(0.0, 30.0)
	spell_cutin_portrait.use_alt_portrait = alt_portrait
	add_child(spell_cutin_portrait)
	spell_cutin_portrait.z_index = -50
