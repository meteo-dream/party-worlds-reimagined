extends FinalBoss

@export var bullet_shoot_dimmed_sfx: AudioStream
var bat_mode: bool

func enable_bat_anim() -> void:
	bat_mode = true

func start_move_anim() -> void:
	if !bat_mode:
		super()
		return
	is_moving = true

func end_move_anim() -> void:
	if !bat_mode:
		super()
		return
	is_moving = false

func start_attack_anim() -> void:
	if !bat_mode:
		super()
		return

func stop_bat_anim() -> void:
	bat_mode = false

# TODO: remove this shit, idk where it's used
func DEBUG_activate_sideboss() -> void:
	return
