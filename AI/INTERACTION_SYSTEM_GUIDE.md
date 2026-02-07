# Interaction System Setup Guide

## Overview

This interaction system uses:
- **Raycast from camera** to detect what player is looking at
- **Interactable base class** for all interactive objects
- **InteractionManager** to handle logic
- **Prompt UI** to show interaction hints

## Quick Setup

### 1. Add InteractionManager to Player

**Scene structure:**
```
Player (CharacterBody3D)
├── CameraPivot/Camera3D
├── WeaponManager
└── InteractionManager (Node) ← Add this, attach interaction_manager.gd
```

### 2. Initialize in Player Script

Add to your `player.gd`:

```gdscript
@onready var interaction_manager := $InteractionManager

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Setup interaction manager
	if interaction_manager:
		interaction_manager.setup(camera, self)
	
	# ... rest of your code
```

### 3. Add Input Action

**Project Settings → Input Map:**
- Add new action: `interact`
- Bind to: **E** key (or F, or whatever you prefer)

### 4. Add Interaction Prompt to HUD

**In your HUD scene:**

```
HUD (CanvasLayer)
├── ... (your existing HUD elements)
└── InteractionPrompt (Label)
    - Text: ""
    - Visible: false
    - Layout: Center (anchored to center of screen)
```

**Label settings:**
- Horizontal Alignment: Center
- Vertical Alignment: Center
- Font Size: 20-24
- Outline: Add black outline for visibility

## Creating Interactable Objects

### Method 1: Extend Interactable (Recommended)

**Create a new script for your door:**

```gdscript
extends Interactable

var is_open := false

func interact(player):
	is_open = !is_open
	
	if is_open:
		# Rotate door 90 degrees
		var tween = create_tween()
		tween.tween_property(self, "rotation:y", deg_to_rad(90), 0.5)
	else:
		var tween = create_tween()
		tween.tween_property(self, "rotation:y", 0, 0.5)

func get_prompt() -> String:
	return "Press E to open door" if not is_open else "Press E to close door"
```

### Method 2: Add Interactable Script to Existing Object

1. Select your door/item/button node
2. Attach `interactable.gd` to it
3. Override `interact()` function

## Example Interactables

### Simple Door

**Scene:**
```
Door (Node3D) - attach door script extending Interactable
├── MeshInstance3D (door model)
└── StaticBody3D
    └── CollisionShape3D
```

**Script:**
```gdscript
extends Interactable

var is_open := false

func _ready():
	interaction_prompt = "Press E to open"

func interact(player):
	is_open = !is_open
	var tween = create_tween()
	tween.tween_property(self, "rotation:y", deg_to_rad(90 if is_open else 0), 0.5)
```

### Health Pickup

**Scene:**
```
HealthPack (Node3D) - attach health pack script
├── MeshInstance3D (or Sprite3D)
└── Area3D (for detection)
    └── CollisionShape3D
```

**Script:**
```gdscript
extends Interactable

@export var heal_amount := 25

func interact(player):
	if player.has_method("heal"):
		player.health += heal_amount
		print("Healed ", heal_amount)
	queue_free()  # Remove from world
```

### Button/Lever

```gdscript
extends Interactable

signal activated

@export var target_door: NodePath  # Assign in inspector

func interact(player):
	activated.emit()
	
	# Open connected door
	if has_node(target_door):
		var door = get_node(target_door)
		if door.has_method("open"):
			door.open()
	
	print("Button pressed!")
```

## Advanced Features

### Highlight Objects When Looking

Add to interactable objects:

```gdscript
func on_focused():
	# Highlight when player looks at this
	if has_node("MeshInstance3D"):
		$MeshInstance3D.get_active_material(0).emission_enabled = true

func on_unfocused():
	# Remove highlight
	if has_node("MeshInstance3D"):
		$MeshInstance3D.get_active_material(0).emission_enabled = false
```

### Conditional Interactions

```gdscript
extends Interactable

@export var requires_item := "Red Key"

func interact(player):
	if not player.has_method("has_item"):
		return
	
	if player.has_item(requires_item):
		print("Door unlocked!")
		queue_free()
	else:
		print("You need the ", requires_item)

func get_prompt() -> String:
	return "Locked - Need " + requires_item
```

### Distance-Based Prompts

Already built in! Each Interactable has:
```gdscript
@export var interaction_distance := 3.0
```

Just adjust in the Inspector per-object.

### Interact with Physics Bodies

The system works with:
- ✅ StaticBody3D
- ✅ RigidBody3D  
- ✅ Area3D
- ✅ Any Node3D with collision

Just make sure the interactable script is on the body or its parent.

## UI Customization

### Custom Prompt Style

Edit your HUD's InteractionPrompt Label:

```gdscript
# In HUD script
func _ready():
	$InteractionPrompt.add_theme_color_override("font_color", Color.YELLOW)
	$InteractionPrompt.add_theme_font_size_override("font_size", 24)
```

### Add Icon Next to Prompt

```
InteractionPrompt (HBoxContainer)
├── Icon (TextureRect) - [E] key image
└── Text (Label) - "to open door"
```

## Troubleshooting

### "Nothing happens when I press E"

- Check `interact` input action is defined
- Verify InteractionManager is setup in player's `_ready()`
- Make sure camera reference is passed correctly

### "Prompt doesn't show"

- Check HUD has a Label node named "InteractionPrompt"
- Verify the path in interaction_manager setup
- Make sure Label is set to visible when there's an interactable

### "Can't interact with object"

- Object or its parent must have Interactable script
- Object must have collision (StaticBody3D, Area3D, etc.)
- Check interaction range (default 3.0 units)

### "Raycast goes through objects"

- Make sure collision layers are set up correctly
- Check that the object has a CollisionShape3D
- Verify InteractionManager's raycast is checking the right layers

## Best Practices

1. **Group interactables**: Use groups for easier management
   ```gdscript
   func _ready():
       add_to_group("interactable")
   ```

2. **Audio feedback**: Add sounds to interactions
   ```gdscript
   func interact(player):
       $AudioStreamPlayer3D.play()
       # ... interaction logic
   ```

3. **Animation**: Use AnimationPlayer for complex interactions
   ```gdscript
   func interact(player):
       $AnimationPlayer.play("open")
   ```

4. **State persistence**: Save door/button states
   ```gdscript
   var is_open := false
   
   func save_state():
       return {"is_open": is_open}
   
   func load_state(state):
       is_open = state.is_open
   ```

## Complete Example: Locked Door

```gdscript
extends Interactable

@export var required_key := "Red Key"
var is_locked := true
var is_open := false

func get_prompt() -> String:
	if is_locked:
		return "Locked - Need " + required_key
	elif is_open:
		return "Press E to close"
	else:
		return "Press E to open"

func interact(player):
	# Check if locked
	if is_locked:
		if player.has_method("has_item") and player.has_item(required_key):
			is_locked = false
			$AudioStreamPlayer3D.stream = preload("res://sounds/unlock.ogg")
			$AudioStreamPlayer3D.play()
		else:
			$AudioStreamPlayer3D.stream = preload("res://sounds/locked.ogg")
			$AudioStreamPlayer3D.play()
			return
	
	# Toggle door
	is_open = !is_open
	$AnimationPlayer.play("open" if is_open else "close")
	$AudioStreamPlayer3D.stream = preload("res://sounds/door.ogg")
	$AudioStreamPlayer3D.play()

func on_focused():
	$MeshInstance3D.get_active_material(0).emission = Color(0.2, 0.2, 0.2)

func on_unfocused():
	$MeshInstance3D.get_active_material(0).emission = Color.BLACK
```

Now you have a complete, flexible interaction system!
