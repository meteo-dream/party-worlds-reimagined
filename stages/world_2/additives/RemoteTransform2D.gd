extends RemoteTransform2D

const ENEMYOUTLINE = preload("res://stages/world_2/additives/enemyoutline.tscn")

@export var remove_on_stomp: bool = true

@onready var objects_part_1 = Scenes.current_scene.get_node('Objects-part1')
@onready var objects_part_2 = Scenes.current_scene.get_node('Objects-part2')
@onready var from = $'../..'

var to
var outline

func _ready():
	var enemy_attacked: Node = get_node('../Body/EnemyAttacked')
	
	outline = ENEMYOUTLINE.instantiate()
	if from.name == objects_part_1.name:
		objects_part_2.add_child(outline)
	elif from.name == objects_part_2.name:
		objects_part_1.add_child(outline)
	remote_path = (get_path_to(outline))
	#print(get_path_to(outline))
	if remove_on_stomp:
		enemy_attacked.stomped_succeeded.connect(remove_outline)
		
	enemy_attacked.killed_succeeded.connect(remove_outline)
	if enemy_attacked.stomping_creation:
		enemy_attacked.stomping_creation.creation_force_sibling = true
	
	await get_tree().physics_frame
	var _body: Area2D = get_node('../Body')
	_body.process_mode = Node.PROCESS_MODE_INHERIT

func remove_outline():
	outline.queue_free()
