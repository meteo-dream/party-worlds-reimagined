extends BossSpellcardFinal

const BUBBLE_RED = preload("res://objects/boss_touhou/boss_final/remilia/bullets/bullet_big_bubble_red.tscn")

# Remilia
const final_shoot_amount: int = 35
const final_shoot_angle: float = PI / 2
const final_shoot_range: float = 330.0
const final_shoot_speed: float = 200.0
const final_shoot_interval: float = 0.1
@onready var interval_timer: Timer = $Interval

func middle_attack() -> void:
	var anchor: Vector2 = boss.boss_handler.global_position
	var destination: Vector2 = anchor - Vector2(0.0, 225.0)
	move_boss(destination, 1.0)
	await _set_timer(2.0)
	#begin_attack = true
	super()

func _physics_process(delta: float) -> void:
	if _boss_attack_interrupt(): return
	if interval_timer.time_left <= 0.0:
		interval_timer.start(final_shoot_interval)
		play_sound(boss.bullet_twinkle, boss, true)
		do_spread_attack()

func do_spread_attack() -> void:
	var final_shoot_offset: float = ((PI*2) - deg_to_rad(final_shoot_range)) / 2
	var final_shoot_diff: float = deg_to_rad(final_shoot_range) / final_shoot_amount
	for i in final_shoot_amount:
		var used_angle: float = final_shoot_angle + final_shoot_offset + (final_shoot_diff * i)
		var final_velocity: Vector2 = Vector2(final_shoot_speed * cos(used_angle), final_shoot_speed * sin(used_angle))
		shoot_simple_bullet(BUBBLE_RED, boss.global_position, final_velocity, used_angle)

func end_attack_global() -> void:
	begin_attack = false
	super()
