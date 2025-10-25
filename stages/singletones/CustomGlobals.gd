extends Node
# Alt boss checker
var w9_alt_boss: bool

## Checks whether Hatate Himekaidou should be the boss for 9-3 or not.
func check_for_hatate_boss() -> bool:
	return (CharacterManager.get_character_name() != "Mario" && !w9_alt_boss) || (CharacterManager.get_character_name() == "Mario" && w9_alt_boss)

func save_boss_status_w9(new_status: bool) -> void:
	ProfileManager.current_profile.data.w9_alt_boss = new_status

func load_boss_status_w9() -> void:
	if ProfileManager.current_profile.data.get("w9_alt_boss") == null: return
	w9_alt_boss = ProfileManager.current_profile.data.get("w9_alt_boss") 

# W9 Boss Hint system
var w9b_death_count: int
var w9b_death_phase: int = -1
var w9b_show_hint: bool = false
const w9b_death_max: int = 10

func w9b_death_reset() -> void:
	w9b_death_count = 0
	w9b_death_phase = -1
	w9b_show_hint = false

func w9b_death_renew(current_phase: int = 0) -> void:
	if w9b_death_phase < current_phase:
		w9b_death_count = 0
		w9b_death_phase = current_phase

func w9b_death_add(current_phase: int = 0) -> void:
	w9b_death_count += 1
	#print("Player died on phase " + str(current_phase) + ". Current count: " + str(w9b_death_count))
	if w9b_death_count >= w9b_death_max:
		w9b_death_phase = current_phase
		w9b_show_hint = true
	#else: print(str(w9b_death_max - w9b_death_count) + " more until hint will be shown.")

func w9b_get_hint_visibility() -> bool:
	return w9b_show_hint and w9b_death_count >= w9b_death_max

# Unlockables - We've got the fancy credits so far.
var unlock_fancy_credits: bool = false

func load_unlockables_status() -> void:
	for key in ProfileManager.profiles:
		if key == "debug": return
		var chosen_profile = ProfileManager.profiles[key]
		if chosen_profile.data.get("unlock_fancy_credits") == null: continue
		unlock_fancy_credits = chosen_profile.data.get("unlock_fancy_credits")
		return

func save_credits_status() -> void:
	ProfileManager.current_profile.data.unlock_fancy_credits = unlock_fancy_credits
