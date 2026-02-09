extends AudioStreamPlayer2D

func _ready() -> void:
	GameManager.set_audio_player(self)
