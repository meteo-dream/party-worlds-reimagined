extends GeneralMovementBody2D

@export var goomba_creation: InstanceNode2D
@export var rotation_speed: float = 22.5

@onready var solid_checker: Area2D = $SolidChecker
@onready var col: CollisionShape2D = $Collision
@onready var visible_on_screen_enabler_2d: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D

var collision_enabled: bool = false
var _is_ready: bool = false

func _ready() -> void:
	for i in 2:
		await get_tree().physics_frame
	_is_ready = true

func _physics_process(delta: float) -> void:
	super(delta)
	get_node(sprite).rotation_degrees += rotation_speed * Thunder.get_delta(delta)
	if !_is_ready: return
	
	if !collision_enabled:
		if solid_checker.get_overlapping_bodies().size() == 0 && speed.y > 0:
			collision_enabled = true
			col.set_deferred(&"disabled", false)
	
	if collision_enabled && is_on_floor():
		NodeCreator.prepare_ins_2d(goomba_creation, self).create_2d()
		queue_free()
