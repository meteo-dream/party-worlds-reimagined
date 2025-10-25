extends RigidBody2D

var inv_counter: float
var colliding: bool = false

@onready var body: Area2D = $Body


func _ready() -> void:
	body.body_entered.connect(_breaker)


func _breaker(body: Node2D) -> void:
	if linear_velocity.length_squared() <= 250 ** 2:
		return
	
	if body is StaticBumpingBlock && body.has_method(&"bricks_break"):
		body.bricks_break()
	for i in body.get_children():
		if i.has_node(^"EnemyAttacked"):
			i.get_node(^"EnemyAttacked").got_killed(&"hammer")


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	$VisibleOnScreenEnabler2D.scale *= 24
