# HUD/UI Creation Guide for Godot 4

## Quick Start: Basic HUD

### Step 1: Create HUD Scene

1. **Scene → New Scene**
2. Select **User Interface** (creates a Control node as root)
3. Or manually: Add **CanvasLayer** as root node
4. Name it "HUD"
5. Attach the `hud.gd` script to it

### Step 2: Build the HUD Layout

**Simple Bottom HUD (Doom-style):**

```
HUD (CanvasLayer)
└── MarginContainer
    └── HBoxContainer
        ├── HealthLabel (Label)
        ├── VSeparator
        └── AmmoLabel (Label)
```

**How to create this:**

1. Add **MarginContainer** as child of HUD
   - In Inspector → Layout → Anchors Preset: **Bottom Wide**
   - Set **Custom Minimum Size** Y to something like 60

2. Add **HBoxContainer** as child of MarginContainer
   - This arranges children horizontally

3. Add **Label** as child of HBoxContainer
   - Name it "HealthLabel"
   - Text: "HEALTH: 100"
   - In Inspector → Theme Overrides → Font Size: 24 (or bigger)
   - Theme Overrides → Colors → Font Color: Red or White

4. Add **VSeparator** (vertical line spacer)

5. Add another **Label**
   - Name it "AmmoLabel"
   - Text: "AMMO: 50"
   - Same font settings

## HUD Layout Presets

### Corner Health/Ammo (Top-Left)

```
HUD (CanvasLayer)
└── VBoxContainer
    ├── HealthLabel
    └── AmmoLabel
```

- Set VBoxContainer → Layout → Anchors: **Top Left**
- Add margins in Theme Overrides → Constants

### Face/Mugshot Center Bottom (Classic Doom)

```
HUD (CanvasLayer)
├── BottomBar (MarginContainer) - Bottom Wide anchor
│   └── HBoxContainer
│       ├── HealthLabel
│       ├── FaceSprite (TextureRect)
│       └── AmmoLabel
```

### Full Doom-Style HUD

```
HUD (CanvasLayer)
├── TopBar (MarginContainer) - Top Wide
│   └── CenterContainer
│       └── MessageLabel (for "Found secret!")
├── BottomBar (MarginContainer) - Bottom Wide
│   └── HBoxContainer
│       ├── LeftPanel
│       │   ├── HealthLabel
│       │   └── ArmorLabel
│       ├── CenterContainer
│       │   └── FaceTexture
│       └── RightPanel
│           ├── AmmoLabel
│           └── WeaponLabel
└── DamageFlash (ColorRect) - Full screen, invisible until hit
```

## UI Node Types Reference

### **Label**
- Display text (health, ammo, etc.)
- **Properties:**
  - Text: The text to display
  - Horizontal/Vertical Alignment
  - Autowrap Mode: For long text

### **TextureRect**
- Display images (weapon icons, face, etc.)
- **Properties:**
  - Texture: Your image
  - Expand Mode: Ignore Size (scales to fit)
  - Stretch Mode: Keep / Keep Centered / Scale

### **ProgressBar**
- Health/armor bars
- **Properties:**
  - Min Value / Max Value
  - Value: Current amount
  - Show Percentage: true/false

### **Container Nodes**

**MarginContainer** - Adds padding around children
**VBoxContainer** - Stacks children vertically
**HBoxContainer** - Arranges children horizontally
**CenterContainer** - Centers its child
**GridContainer** - Grid layout

### **ColorRect**
- Solid color rectangles
- Good for backgrounds, damage flashes
- Set color in **Color** property

## Anchors and Layouts

**To position UI elements:**

1. Select your Control node (MarginContainer, Label, etc.)
2. Click **Layout** dropdown at top of viewport
3. Choose preset:
   - **Top Left** - Anchored to top-left corner
   - **Top Wide** - Spans top of screen
   - **Bottom Wide** - Spans bottom (good for HUD bars)
   - **Full Rect** - Covers entire screen
   - **Center** - Centered on screen

## Styling UI

### Method 1: Theme Overrides (Quick)

Select any Control node → Inspector → **Theme Overrides**:

- **Colors** → Font Color: Change text color
- **Font Sizes** → Font Size: Make text bigger
- **Fonts** → Font: Use custom font file

### Method 2: Custom Theme (Reusable)

1. Create **New Theme** resource
2. Save it as `my_theme.tres`
3. Edit default fonts, colors, sizes
4. Apply to HUD root: HUD → Theme → Load your theme

### Doom-Style Font

1. Import a retro/pixel font (e.g., .ttf file)
2. Select font in FileSystem
3. Import tab → **Rendering** → **Antialiasing**: None (for crispy pixels)
4. Apply to labels via Theme Overrides → Font

## Connecting HUD to Player

### Add to Player Script

```gdscript
# In player.gd
var health := 100
var max_health := 100

func get_health() -> int:
	return health

func take_damage(amount: int):
	health -= amount
	health = clamp(health, 0, max_health)
	
	# Flash HUD red
	var hud = get_node("../HUD")  # Adjust path
	if hud and hud.has_method("flash_damage"):
		hud.flash_damage()
```

### HUD Updates Automatically

The `hud.gd` script calls `update_hud()` every frame, which reads from the player.

## Advanced: Animated HUD

### Health Bar with Tween

```gdscript
# In hud.gd
@onready var health_bar: ProgressBar = $HealthBar

func update_health(new_health: int):
	var tween = create_tween()
	tween.tween_property(health_bar, "value", new_health, 0.3)
```

### Pulsing Low Health Warning

```gdscript
func _process(delta):
	if player and player.get_health() < 25:
		# Pulse red when low health
		var pulse = abs(sin(Time.get_ticks_msec() / 500.0))
		health_label.modulate = Color(1, pulse, pulse)
	else:
		health_label.modulate = Color.WHITE
```

### Weapon Icon Switching

```gdscript
@onready var weapon_icon: TextureRect = $WeaponIcon
@export var weapon_textures: Array[Texture2D] = []

func set_weapon(weapon_index: int):
	if weapon_index < weapon_textures.size():
		weapon_icon.texture = weapon_textures[weapon_index]
```

## Example: Complete Doom HUD

```gdscript
extends CanvasLayer

@onready var health_label = $Bottom/HBox/Health
@onready var ammo_label = $Bottom/HBox/Ammo
@onready var face_texture = $Bottom/HBox/Face
@onready var damage_flash = $DamageFlash

var player

func _ready():
	player = get_tree().current_scene.get_node("Player")
	damage_flash.modulate.a = 0  # Start invisible

func _process(_delta):
	if player:
		health_label.text = str(player.health)
		ammo_label.text = str(player.ammo)
		update_face()

func update_face():
	# Change face based on health
	if player.health > 80:
		face_texture.texture = load("res://faces/healthy.png")
	elif player.health > 50:
		face_texture.texture = load("res://faces/hurt.png")
	else:
		face_texture.texture = load("res://faces/critical.png")

func flash_damage():
	damage_flash.modulate.a = 0.4
	var tween = create_tween()
	tween.tween_property(damage_flash, "modulate:a", 0.0, 0.3)

func show_message(text: String, duration: float = 2.0):
	var msg = $MessageLabel
	msg.text = text
	msg.visible = true
	await get_tree().create_timer(duration).timeout
	msg.visible = false
```

## Common HUD Elements

### Crosshair
Already covered in the crosshair guide! Use the CrosshairLayer setup.

### Ammo Counter
```gdscript
ammo_label.text = str(current_ammo) + " / " + str(max_ammo)
```

### Health Bar (Visual)
Use ProgressBar with a custom theme for Doom-style bars

### Minimap
Advanced - use a SubViewport with a top-down camera

### Pickup Notifications
```gdscript
func show_pickup(item_name: String):
	$PickupLabel.text = "Picked up " + item_name
	$PickupLabel.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property($PickupLabel, "modulate:a", 0.0, 2.0)
```

## Tips

1. **Keep it simple** - Start with just health/ammo labels
2. **Use CanvasLayer** - Ensures HUD is always on top and separate from 3D
3. **Anchor everything** - So it scales properly on different screen sizes
4. **Test at different resolutions** - Project Settings → Window → adjust size
5. **Layer it** - Set CanvasLayer → Layer to high number (10+) to render on top

## Scene Structure Recommendation

```
Main Scene
├── Level (Node3D)
├── Player (CharacterBody3D)
├── CrosshairLayer (CanvasLayer) - layer 10
└── HUD (CanvasLayer) - layer 5
```

The HUD automatically updates from the Player each frame!
