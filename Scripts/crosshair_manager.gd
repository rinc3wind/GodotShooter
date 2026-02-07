extends CanvasLayer
class_name CrosshairManager

# --------------------
# Crosshair presets
# --------------------
@export var crosshair_textures: Array[Texture2D] = []
@export var current_crosshair_index := 0

@export var crosshair_scale := 0.5:
	set(value):
		crosshair_scale = value
		if crosshair:
			crosshair.scale = Vector2(crosshair_scale, crosshair_scale)

@export var crosshair_color := Color.WHITE:
	set(value):
		crosshair_color = value
		if crosshair:
			crosshair.modulate = crosshair_color

@onready var crosshair: TextureRect

func _ready():
	crosshair = $CenterContainer/Crosshair

	# Set initial crosshair texture
	if crosshair_textures.size() > 0 and current_crosshair_index < crosshair_textures.size():
		set_crosshair(current_crosshair_index)
		
	# Apply initial scale and color (do this first, after @onready vars are ready)
	if crosshair:
		await get_tree().process_frame
		crosshair.scale = Vector2(crosshair_scale, crosshair_scale)
		crosshair.modulate = crosshair_color

func _input(event):
	# Optional: cycle through crosshairs with a key (e.g., C key)
	if event.is_action_pressed("ui_focus_next"):  # Replace with custom action
		cycle_crosshair()

# Change to specific crosshair by index
func set_crosshair(index: int):
	if index < 0 or index >= crosshair_textures.size():
		return
	
	current_crosshair_index = index
	if crosshair and crosshair_textures[index]:
		crosshair.texture = crosshair_textures[index]

# Cycle to next crosshair
func cycle_crosshair():
	if crosshair_textures.size() == 0:
		return
	
	current_crosshair_index = (current_crosshair_index + 1) % crosshair_textures.size()
	set_crosshair(current_crosshair_index)

# Show/hide crosshair
func set_visible_crosshair(is_visible: bool):
	if crosshair:
		crosshair.visible = is_visible

# Change crosshair color (useful for hit markers)
func set_color(color: Color):
	if crosshair:
		crosshair.modulate = color

# Flash crosshair (e.g., when hitting enemy)
func flash_hit(duration: float = 0.1, hit_color: Color = Color.RED):
	if not crosshair:
		return
	
	var original_color = crosshair.modulate
	crosshair.modulate = hit_color
	
	await get_tree().create_timer(duration).timeout
	crosshair.modulate = original_color
