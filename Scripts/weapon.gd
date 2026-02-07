extends Node3D
class_name Weapon

var camera: Camera3D
var recoil_offset := 0.0

func setup(cam: Camera3D):
	camera = cam

func process_weapon(_delta: float):
	# Override in child classes
	pass

func get_recoil_offset() -> float:
	return recoil_offset

func apply_recoil(delta: float, return_speed: float):
	# Smoothly return recoil to zero
	recoil_offset = lerp(recoil_offset, 0.0, return_speed * delta)
