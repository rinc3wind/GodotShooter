extends Weapon
class_name Shotgun

# --------------------
# Shotgun stats
# --------------------
@export var pellet_count := 8			# Number of pellets per shot
@export var pellet_spread := 6.0		# degrees
@export var pellet_range := 100.0		# max distance pellets can hit
@export var fire_rate := 0.2			# seconds between shots; default 0.9
@export var damage_per_pellet := 4		# damage per pellet; default 6
@export var recoil_kick := 2.2			# degrees
@export var recoil_return := 18.0		# return speed

# --------------------
# Animation settings
# --------------------
@export var shoot_animation := "shoot"
@export var reload_animation := "reload"
@export var idle_animation := "idle"

@onready var sprite: AnimatedSprite3D

var fire_cooldown := 0.0
var is_reloading := false

func setup(cam: Camera3D):
	super.setup(cam)  # Call parent setup
	# Find sprite as child of camera
	sprite = cam.get_node_or_null("WeaponSprite")
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
		sprite.play(idle_animation)

func _ready():
	# Initialize ammo
	max_ammo = 50
	clip_size = 2
	current_ammo = 36
	ammo_in_clip = 2
	
	# Make sure sprite exists and play idle
	if sprite:
		sprite.play(idle_animation)

func process_weapon(delta: float):
	# Tick down cooldown
	if fire_cooldown > 0:
		fire_cooldown -= delta

	# Apply recoil recovery
	apply_recoil(delta, recoil_return)

	# Don't allow actions during reload
	if is_reloading:
		return

	# Handle firing
	if Input.is_action_pressed("fire") and fire_cooldown <= 0:
		fire()
	
	# Handle reloading
	if Input.is_action_just_pressed("reload"):
		start_reload()

func fire():
	if not camera:
		return
	
	if ammo_in_clip <= 0:
		# Auto-reload if out of ammo
		start_reload()
		return

	fire_cooldown = fire_rate
	recoil_offset -= recoil_kick

	# Play shoot animation
	if sprite:
		sprite.play(shoot_animation)

	var space_state := get_world_3d().direct_space_state

	for i in pellet_count:
		fire_pellet(space_state)

	super.fire()  # Call parent fire (decrements ammo)

func start_reload():
	# Don't reload if already reloading or clip is full or no reserve ammo
	if is_reloading:
		return
	if ammo_in_clip >= clip_size:
		return
	if current_ammo <= 0:
		return
	
	is_reloading = true
	
	# Play reload animation
	if sprite:
		sprite.play(reload_animation)
	
	# The actual reload logic will happen when animation finishes

func _on_animation_finished():
	if not sprite:
		return
	
	# Check which animation just finished
	if sprite.animation == shoot_animation:
		# Return to idle after shooting
		sprite.play(idle_animation)
	
	elif sprite.animation == reload_animation:
		# Complete the reload
		super.reload()
		is_reloading = false
		sprite.play(idle_animation)

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
	create_bullet_hole(result)

	# Apply damage
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
