@tool
extends AnimatableBody2D

@export_category("Switch Block")
@export var id: int:
	set(to):
		id = to
		if Engine.is_editor_hint() || (!Engine.is_editor_hint() && _is_ready):
			$Sprites/AnimatedSprite2D.material.set_shader_parameter(&"hue", wrapf(float(id) * 0.02, -1, 1))
@export var off: bool:
	set(to):
		off = to
		_status()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Sprites/AnimatedSprite2D
@onready var shader: ShaderMaterial = sprite.material

@onready var _is_ready: bool = true


func _ready() -> void:
	_status()
	if Engine.is_editor_hint(): return
	add_to_group("switch_" + str(id))
	shader.set_shader_parameter(&"hue", wrapf(float(id) * 0.02, -1, 1))


func _status() -> void:
	if !Engine.is_editor_hint() && !_is_ready: return
	$Sprites/AnimatedSprite2D.play(&"default" if !off else &"disabled")
	if !Engine.is_editor_hint(): collision_shape.set_deferred(&"disabled", off)


func switch() -> void:
	off = !off
	_status()
