extends Node

var player: Node3D = null
var weapon_manager: Node3D = null

func set_player(p: Node3D):
	player = p

func get_player() -> Node3D:
	return player

func set_weapon_manager(wm: Node3D):
	weapon_manager = wm

func get_weapon_manager() -> Node3D:
	return weapon_manager
