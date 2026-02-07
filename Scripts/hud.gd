extends CanvasLayer
class_name HUD

# References to UI elements
@onready var health_label: Label = $MarginContainer/HBoxContainer/HealthLabel
@onready var ammo_label: Label = $MarginContainer/HBoxContainer/AmmoLabel

# Reference to player
var player: CharacterBody3D

func _ready():
	# Find player
	player = get_tree().current_scene.get_node_or_null("Player")

func _process(_delta):
	if player:
		update_hud()

func update_hud():
	# Update health
	if player.has_method("get_health"):
		health_label.text = "HEALTH: " + str(player.get_health())
	
	# Update ammo (if you add ammo system)
	# if player.has_method("get_ammo"):
	#     ammo_label.text = "AMMO: " + str(player.get_ammo())
	
	# For now, placeholder
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
