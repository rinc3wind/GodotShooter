extends Weapon
class_name Shotgun

# --------------------
# Shotgun stats
# --------------------
@export var pellet_count := 8			# Number of pellets per shot
@export var pellet_spread := 6.0		# degrees
@export var pellet_range := 100.0		# max distance pellets can hit
@export var fire_rate := 0.6			# seconds between shots; default 0.9
@export var damage_per_pellet := 4		# damage per pellet; default 6
@export var recoil_kick := 2.2			# degrees
@export var recoil_return := 18.0		# return speed

# --------------------
# Sprite settings
# --------------------
@export var idle_texture: Texture2D
@export var fire_texture: Texture2D
@export var fire_animation_time := 0.1  # How long to show fire sprite

@onready var sprite: Sprite3D

var fire_cooldown := 0.0
var fire_animation_timer := 0.0

func setup(cam: Camera3D):
	super.setup(cam)  # Call parent setup
	# Find sprite as child of camera
	sprite = cam.get_node_or_null("WeaponSprite")
	if sprite and idle_texture:
		sprite.texture = idle_texture

func _ready():
	# Make sure sprite exists
	if sprite and idle_texture:
		sprite.texture = idle_texture

func process_weapon(delta: float):
	# Tick down cooldown
	if fire_cooldown > 0:
		fire_cooldown -= delta
	
	# Handle fire animation
	if fire_animation_timer > 0:
		fire_animation_timer -= delta
		if fire_animation_timer <= 0 and sprite and idle_texture:
			sprite.texture = idle_texture
	
	# Apply recoil recovery
	apply_recoil(delta, recoil_return)
	
	# Handle firing
	if Input.is_action_pressed("fire") and fire_cooldown <= 0:
		fire()

func fire():
	if not camera:
		return

	fire_cooldown = fire_rate
	recoil_offset -= recoil_kick
	
	# Show fire sprite
	if sprite and fire_texture:
		sprite.texture = fire_texture
		fire_animation_timer = fire_animation_time
	
	var space_state := get_world_3d().direct_space_state
	
	for i in pellet_count:
		fire_pellet(space_state)

func fire_pellet(space_state: PhysicsDirectSpaceState3D):
	# Random spread
	var spread_x := randf_range(-pellet_spread, pellet_spread)
	var spread_y := randf_range(-pellet_spread, pellet_spread)
	
	# Get base direction from camera
	var direction: Vector3 = -camera.global_transform.basis.z
	direction = direction.rotated(camera.global_transform.basis.y, deg_to_rad(spread_x))
	direction = direction.rotated(camera.global_transform.basis.x, deg_to_rad(spread_y))
	direction = direction.normalized()
	
	# Raycast
	var from: Vector3 = camera.global_position
	var to := from + direction * pellet_range
	
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_parent().get_parent()]  # Exclude player
	query.collide_with_areas = false
	
	var result := space_state.intersect_ray(query)
	
	if result:
		handle_hit(result)

func handle_hit(result: Dictionary):
	#print("Hit: ", result.collider.name)
	create_bullet_hole(result)
	
	# TODO: Apply damage
	if result.collider.has_method("take_damage"):
		result.collider.take_damage(damage_per_pellet)

func create_bullet_hole(result):
	var decal := Decal.new()
	get_tree().current_scene.add_child(decal)
	decal.texture_albedo = preload("res://Assets/effects/bullet_hole.png")
	var normal: Vector3 = result["normal"].normalized()
	decal.global_position = result["position"] + normal * 0.01

	# Build tangent space
	var tangent: Vector3
	if abs(normal.dot(Vector3.UP)) < 0.99:
		tangent = normal.cross(Vector3.UP).normalized()
	else:
		tangent = normal.cross(Vector3.RIGHT).normalized()
	var bitangent: Vector3 = tangent.cross(normal).normalized()

	# Random spin around normal
	var angle := randf() * TAU
	tangent = tangent.rotated(normal, angle)
	bitangent = bitangent.rotated(normal, angle)
	decal.global_transform.basis = Basis(tangent, -normal, bitangent)
	decal.size = Vector3(0.2, 0.2, 0.2)
	
	# Destroy decal after 30 seconds
	await get_tree().create_timer(30).timeout
	if is_instance_valid(decal): decal.queue_free()
