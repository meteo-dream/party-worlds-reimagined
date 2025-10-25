@tool
extends StaticBumpingBlock

@export_category("Switch Block")
@export_group("General")
@export var id: int = 0:
	set(to):
		id = to
		if Engine.is_editor_hint() || (!Engine.is_editor_hint() && _is_ready):
			$Sprites/AnimatedSprite2D.material.set_shader_parameter(&"hue", wrapf(float(id) * 0.02, -1, 1))

@onready var _is_ready: bool = true
@onready var sprite: AnimatedSprite2D = $Sprites/AnimatedSprite2D
@onready var shader: ShaderMaterial = sprite.material
signal tile_layers


func _ready() -> void:
	shader.set_shader_parameter(&"hue", wrapf(float(id) * 0.02, -1, 1))


func _physics_process(_delta) -> void:
	if Engine.is_editor_hint(): return
	super(_delta)


func got_bumped(by_player: bool = false) -> void:
	if _triggered: return
	bump(false)
	tile_layers.emit()
