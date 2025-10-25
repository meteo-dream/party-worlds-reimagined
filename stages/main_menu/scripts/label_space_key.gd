extends Label

@export var action: String = "ui_select"

var _tw: Tween
var _min_a: float = 0
@onready var _template = text

func _ready() -> void:
	modulate.a = 0
	update_text()
	SettingsManager.settings_saved.connect(update_text)


func _physics_process(delta: float) -> void:
	if _tw: return
	
	_tw = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	_tw.tween_property(self, ^"modulate:a", 1, 0.5)
	_tw.tween_property(self, ^"modulate:a", _min_a, 0.5)


func update_text() -> void:
	var _events: Array[InputEvent] = InputMap.action_get_events(action)
	var _event: String = "buttons on keyboard"
	for i in _events:
		if i is InputEventKey:
			_event = i.as_text().get_slice(' (', 0) + ' key'
			break
	
	text = _template % _event
