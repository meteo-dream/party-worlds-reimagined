extends GPUParticles2D
@onready var sound = $Sound
@export_category("Rain")
@export_group("Sounds", "sound_")
@export_range(0, 60, 0.001, "suffix:s") var sound_far_lightning_interval_base: float = 12
@export_range(0, 60, 0.001, "suffix:s") var sound_far_lightning_interval_extra: float = 18


func _ready():
	$Sound.playing = true
