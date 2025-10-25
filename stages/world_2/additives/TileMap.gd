extends TileMap
@onready var objects_part_2 = $"../Objects-part2"
@onready var objects_part_1 = $"../Objects-part1"
var switch = false

func controller() -> void:
	switch = !switch
	if switch:
		print('switch')
		layer_disabled()
	else:
		layer_enabled()

func layer_enabled() -> void:
	set_layer_enabled(0, true)
	set_layer_enabled(1, false)
	set_layer_enabled(2, true)
	set_layer_enabled(3, false)
	set_layer_enabled(4, true)
	set_layer_enabled(5, false)
	objects_part_1.process_mode = PROCESS_MODE_INHERIT
	objects_part_1.visible = true
	objects_part_2.process_mode = PROCESS_MODE_DISABLED
	objects_part_2.visible = false

func layer_disabled() -> void:
	set_layer_enabled(0, false)
	set_layer_enabled(1, true)
	set_layer_enabled(2, false)
	set_layer_enabled(3, true)
	set_layer_enabled(4, false)
	set_layer_enabled(5, true)
	objects_part_2.process_mode = PROCESS_MODE_INHERIT
	objects_part_2.visible = true
	objects_part_1.process_mode = PROCESS_MODE_DISABLED
	objects_part_1.visible = false

func _ready():
	layer_enabled()
	set_layer_modulate(1, Color.WHITE)
	set_layer_modulate(3, Color.WHITE)
	set_layer_modulate(4, Color.YELLOW)
	objects_part_2.modulate = Color.WHITE
	set_layer_z_index(4, 0)
	set_layer_z_index(5, 0)
#func _input(event):
	#if event.is_pressed() && event is InputEventKey && event.keycode == KEY_F:
		#controller()

func brick_destroyed(brick) -> void:
	var brpos = brick.global_position
	#print('signal recieved')
	#print(brpos)
	#tile_set.tile_size
	if brick.get_parent().name=="Objects-part1":
		set_cell(5, brpos/32, -1)
		#print('terrain updated')
	if brick.get_parent().name=="Objects-part2":
		set_cell(4, brpos/32, -1)
		#print('terrain updated')
