extends Node

var player: Node3D = null
var weapon_manager: Node3D = null
var audio_player: AudioStreamPlayer2D = null

func set_player(p: Node3D):
	player = p

func get_player() -> Node3D:
	return player

func set_weapon_manager(wm: Node3D):
	weapon_manager = wm

func get_weapon_manager() -> Node3D:
	return weapon_manager

func set_audio_player(ap: AudioStreamPlayer2D):
	audio_player = ap

func get_audio_player() -> AudioStreamPlayer2D:
	return audio_player

func play_sound(sound: AudioStream):
	if audio_player and sound:
		audio_player.stream = sound
		audio_player.play()
