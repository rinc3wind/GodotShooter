extends CanvasLayer
class_name HUD

# References to UI elements
@onready var health_label: Label = $MarginContainer/HBoxContainer/HealthLabel
@onready var ammo_label: Label = $MarginContainer2/HBoxContainer/AmmoLabel

# Reference to player
var player: CharacterBody3D
var weapon_manager: WeaponManager

func _ready():
	player = GameManager.get_player()
	weapon_manager = GameManager.get_weapon_manager()

func _process(_delta):
	if player:
		update_hud()
	else: player = GameManager.get_player()

func update_hud():
	# Update health
	if player.has_method("get_health"):
		health_label.text = "HEALTH: " + str(player.get_health())
	
	# Update ammo
	if !weapon_manager:
		weapon_manager = GameManager.get_weapon_manager()
	elif weapon_manager and weapon_manager.has_method("get_current_ammo"):
		ammo_label.text = "AMMO: " + str(weapon_manager.get_current_ammo())
	else:
		ammo_label.text = "AMMO: --"

# Call this from player when taking damage
func flash_damage():
	# Flash red on damage
	var flash = ColorRect.new()
	flash.color = Color(1, 0, 0, 0.3)  # Red, semi-transparent
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)
