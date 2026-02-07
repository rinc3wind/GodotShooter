extends Node3D
class_name WeaponManager

var camera: Camera3D
var current_weapon: Weapon
var weapons: Array[Weapon] = []

func _ready():
	# Collect all weapon children
	for child in get_children():
		if child is Weapon:
			weapons.append(child)
			child.visible = false
	
	# Equip first weapon if available
	if weapons.size() > 0:
		equip_weapon(0)

func setup(cam: Camera3D):
	camera = cam
	
	# Pass camera to all weapons
	for weapon in weapons:
		weapon.setup(camera)

func process_input(delta: float):
	if current_weapon:
		current_weapon.process_weapon(delta)

func equip_weapon(index: int):
	if index < 0 or index >= weapons.size():
		return
	
	# Hide current weapon
	if current_weapon:
		current_weapon.visible = false
	
	# Show new weapon
	current_weapon = weapons[index]
	current_weapon.visible = true

func get_camera_recoil() -> float:
	if current_weapon:
		return current_weapon.get_recoil_offset()
	return 0.0

# Optional: weapon switching by number keys
func _input(event):
	if event.is_action_pressed("weapon_1"):
		equip_weapon(0)
	elif event.is_action_pressed("weapon_2"):
		equip_weapon(1)
	elif event.is_action_pressed("weapon_3"):
		equip_weapon(2)
