extends Node

var player: Node3D = null

func set_player(p: Node3D):
	player = p

func get_player() -> Node3D:
	return player