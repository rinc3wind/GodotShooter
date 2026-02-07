extends Node3D
class_name Interactable

# Base class for all interactable objects

@export var interaction_prompt := "Press E to interact"
@export var interaction_distance := 3.0

# Override this in child classes
func interact(player):
	print("Interacted with ", name)

# Optional: Called when player looks at this object
func on_focused():
	pass

# Optional: Called when player looks away
func on_unfocused():
	pass

# Optional: Get custom prompt based on state
func get_prompt() -> String:
	return interaction_prompt
