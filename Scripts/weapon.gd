extends Node3D
class_name Weapon

@export var max_ammo: int		# Total ammo player can carry
@export var clip_size: int		# Ammo per magazine
@export var current_ammo: int	# Current total ammo (not in clip)
@export var ammo_in_clip: int	# Ammo currently loaded in clip

var camera: Camera3D
var recoil_offset := 0.0

func setup(cam: Camera3D):
	camera = cam

func get_recoil_offset() -> float:
	return recoil_offset

func apply_recoil(delta: float, return_speed: float):
	# Smoothly return recoil to zero
	recoil_offset = lerp(recoil_offset, 0.0, return_speed * delta)

func fire():
	# Override in child classes
	if ammo_in_clip > 0:
		ammo_in_clip -= 1

func reload():
	print("Reloading...")
	var needed_ammo = clip_size - ammo_in_clip
	var ammo_to_load = min(needed_ammo, current_ammo)
	ammo_in_clip += ammo_to_load
	current_ammo -= ammo_to_load
