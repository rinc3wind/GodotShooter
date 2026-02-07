extends Node
class_name InteractionManager

@export var interaction_range := 3.0
@export var interaction_raycast_from_center := true

var camera: Camera3D
var current_interactable: Interactable = null
var player: CharacterBody3D

# UI reference (optional)
var prompt_label: Label = null

func setup(cam: Camera3D, plr: CharacterBody3D):
	camera = cam
	player = plr
	
	# Try to find prompt label in HUD
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		prompt_label = hud.get_node_or_null("InteractionPrompt")

func _process(_delta):
	check_for_interactable()
	
	# Handle interaction input
	if Input.is_action_just_pressed("interact"):
		if current_interactable:
			current_interactable.interact(player)

func check_for_interactable():
	if not camera:
		return
	
	var space_state := camera.get_world_3d().direct_space_state
	
	# Raycast from camera center
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * interaction_range
	
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result := space_state.intersect_ray(query)
	
	var new_interactable: Interactable = null
	
	if not result.is_empty():
		# Check if hit object or its parent is interactable
		new_interactable = get_interactable_from_collision(result.collider)
	
	# Handle focus changes
	if new_interactable != current_interactable:
		# Unfocus old
		if current_interactable:
			current_interactable.on_unfocused()
		
		# Focus new
		current_interactable = new_interactable
		if current_interactable:
			current_interactable.on_focused()
		
		# Update prompt
		update_prompt()

func get_interactable_from_collision(collider) -> Interactable:
	# Check if the collider itself is an Interactable
	if collider is Interactable:
		return collider
	
	# Check if collider has Interactable script
	if collider.get_script():
		var script_path = collider.get_script().get_path()
		if "interactable" in script_path.to_lower():
			return collider
	
	# Check parent nodes
	var parent = collider.get_parent()
	while parent:
		if parent is Interactable:
			return parent
		parent = parent.get_parent()
	
	return null

func update_prompt():
	if not prompt_label:
		return
	
	if current_interactable:
		prompt_label.text = current_interactable.get_prompt()
		prompt_label.visible = true
	else:
		prompt_label.visible = false

func get_current_interactable() -> Interactable:
	return current_interactable
