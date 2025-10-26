extends Powerup

@export var luigi_spriteframes: SpriteFrames
@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	if CharacterManager.get_character_name() == "Luigi":
		sprite.sprite_frames = luigi_spriteframes
		sprite.play()
		gravity_scale = 0.5
		collided_wall.connect(turn_x)
	super()
