# Example 1: Door
extends Interactable
class_name InteractableDoor

@export var is_locked := false
@export var required_key := ""

var is_open := false

func _ready():
	if is_locked:
		interaction_prompt = "Locked - Need " + required_key
	else:
		interaction_prompt = "Press E to open door"

func interact(player):
	if is_locked:
		# Check if player has key
		if player.has_method("has_item") and player.has_item(required_key):
			is_locked = false
			print("Door unlocked!")
		else:
			print("Door is locked!")
			return
	
	# Toggle door
	is_open = !is_open
	
	if is_open:
		open_door()
	else:
		close_door()

func open_door():
	print("Opening door")
	# Animate door opening
	var tween = create_tween()
	tween.tween_property(self, "rotation:y", deg_to_rad(90), 0.5)
	interaction_prompt = "Press E to close door"

func close_door():
	print("Closing door")
	var tween = create_tween()
	tween.tween_property(self, "rotation:y", deg_to_rad(0), 0.5)
	interaction_prompt = "Press E to open door"

func get_prompt() -> String:
	if is_locked:
		return "Locked - Need " + required_key
	elif is_open:
		return "Press E to close door"
	else:
		return "Press E to open door"


# Example 2: Item Pickup
extends Interactable
class_name InteractableItem

@export var item_name := "Health Pack"
@export var heal_amount := 25

func _ready():
	interaction_prompt = "Press E to pick up " + item_name

func interact(player):
	# Give item to player
	if player.has_method("heal"):
		player.heal(heal_amount)
		print("Picked up ", item_name, " - healed ", heal_amount)
	
	# Remove from world
	queue_free()


# Example 3: Button/Switch
extends Interactable
class_name InteractableButton

signal button_pressed

@export var is_active := false
@export var one_time_use := false

var has_been_used := false

func _ready():
	interaction_prompt = "Press E to activate"

func interact(player):
	if one_time_use and has_been_used:
		return
	
	is_active = !is_active
	has_been_used = true
	
	print("Button activated!")
	button_pressed.emit()
	
	# Visual feedback
	if has_node("MeshInstance3D"):
		var mesh = $MeshInstance3D
		var mat = mesh.get_active_material(0)
		if mat:
			mat.emission_enabled = is_active
	
	if one_time_use:
		interaction_prompt = "Already used"


# Example 4: Readable (notes, signs)
extends Interactable
class_name InteractableReadable

@export_multiline var text_content := "This is a readable note."
@export var title := "Note"

signal text_displayed(text: String, title: String)

func _ready():
	interaction_prompt = "Press E to read"

func interact(player):
	print("Reading: ", title)
	text_displayed.emit(text_content, title)
	# You'd show this in a UI panel
