extends Interactable

@export var timeline:String
var player

func _ready():
	interaction_prompt = "Talk"
	
	# Connect to Dialogic signals
	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)	

func interact(_player):
	player = _player
	Dialogic.start(timeline)

func _on_dialogue_started():
	player.is_in_dialogue = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_dialogue_ended():
	player.is_in_dialogue = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
