extends CanvasLayer

const MESSAGE_BLOCK = preload("res://stages/main_menu/sounds/message_block.wav")

var activated: bool

signal message_shown
signal message_hidden

@onready var box: Node2D = $Box
@onready var text: Label = $Box/Texture/Text
@onready var text_2: Label = $Box/Texture/Text3
@onready var label_2: Label = $"../Label2"
@onready var tweaks: Control = $"../SubViewportContainer/SubViewport/Tweaks"
@onready var parent: Control = $".."
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	box.scale = Vector2.ZERO
	label_2.visible = false
	tweaks.add_user_signal("_tweak_desc")
	tweaks.add_user_signal("_show_desc")
	tweaks.get_node(^"Tweaks").connect(&"selected", _set_invis.unbind(4))
	tweaks.get_node(^"Gameplay").connect(&"selected", _set_invis.unbind(4))
	tweaks.get_node(^"Aesthetic").connect(&"selected", _set_invis.unbind(4))
	tweaks.get_node(^"Presets").connect(&"selected", _set_invis.unbind(4))
	tweaks.connect(&"_tweak_desc", func(controller):
		if controller.focused:
			label_2.visible = true
	)
	tweaks.connect(&"_show_desc", show_description)


func _set_invis() -> void:
	label_2.visible = false


func _physics_process(delta: float) -> void:
	if !activated: return
	if !get_tree().paused:
		get_tree().paused = true
	
	if box.scale.x < 0.5:
		return
	
	if Input.is_action_just_pressed(&"ui_select") || Input.is_action_just_pressed(&"ui_cancel"):
		hide_message()
		activated = false


func show_description(desc: String, title: String) -> void:
	message_shown.emit()
	box.scale = Vector2.ZERO
	text.text = desc
	text_2.text = title
	#$Box/Texture.size.y = text.get_line_height() * text.get_line_count() + 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	Audio.play_1d_sound(MESSAGE_BLOCK)
	get_tree().paused = true
	
	box.position = Vector2(320, 240) #как же похуй...
	
	var tw2 = get_tree().create_tween().bind_node(color_rect).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw2.tween_property(color_rect, ^"color:a", 0.5, 0.5)
	
	var tw = get_tree().create_tween().bind_node(box).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(box, ^"scale", Vector2.ONE, 0.5)
	tw.tween_callback(func():
		activated = true
		
	)


func hide_message() -> void:
	if !is_instance_valid(box): return
	message_hidden.emit()
	
	var tw2 = get_tree().create_tween().bind_node(color_rect).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw2.tween_property(color_rect, ^"color:a", 0.0, 0.5)
	
	var tw = get_tree().create_tween().bind_node(box)
	tw.tween_property(box, ^"scale", Vector2.ZERO, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(func():
		#box.reparent(self)
		#box = $Box
		process_mode = Node.PROCESS_MODE_INHERIT
		get_tree().paused = false
		activated = false
	)
