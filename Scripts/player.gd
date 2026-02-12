extends CharacterBody3D

# --------------------
# Movement tuning
# --------------------
@export var walk_speed := 10.0
@export var sprint_speed := 14.0
@export var crouch_speed := 6.0

@export var acceleration := 70.0
@export var friction := 50.0
@export var gravity := 30.0
@export var jump_force := 11.0

# --------------------
# Mouse look
# --------------------
@export var mouse_sensitivity := 0.10
@export var max_look_up := 80.0
@export var max_look_down := -80.0

# --------------------
# Crouch
# --------------------
@export var stand_height := 1.6
@export var crouch_height := 1.0
@export var crouch_camera_y := 0.5  # Camera height when crouching
@export var stand_camera_y := 1.5   # Camera height when standing
@export var crouch_lerp_speed := 12.0

@onready var camera_pivot := $CameraPivot
@onready var camera := $CameraPivot/Camera3D
@onready var collision := $CollisionShape3D
@onready var weapon_manager := $WeaponManager
@onready var flashlight := $CameraPivot/Camera3D/Flashlight
@onready var interaction_manager := $InteractionManager

# --------------------
# Stats
# --------------------
@export var health := 100

var is_crouching := false
var look_angle := 0.0
var is_in_dialogue := false

const MAX_STEP_HEIGHT = 0.5
var _snapped_to_stairs_last_frame := false
var _last_frame_was_on_floor = -INF

func _ready():
	GameManager.set_player(self)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Setup interaction manager
	if interaction_manager:
		interaction_manager.setup(camera, self)

	# Give weapon manager access to camera
	if weapon_manager:
		weapon_manager.setup(camera)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		handle_mouse_look(event)

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --------------------
# Mouse look
# --------------------
func handle_mouse_look(event: InputEventMouseMotion):
	if is_in_dialogue: return

	rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

	look_angle = clamp(
		look_angle - event.relative.y * mouse_sensitivity,
		max_look_down,
		max_look_up
	)

# --------------------
# Main physics loop
# --------------------
func _physics_process(delta):
	if is_in_dialogue: return
	if is_on_floor(): _last_frame_was_on_floor = Engine.get_physics_frames()

	handle_crouch(delta)
	handle_movement(delta)
	handle_jump()
	handle_gravity(delta)
	if not _snap_up_to_stairs_check(delta):
		move_and_slide()
		_snap_down_to_stairs_check()
	update_camera_pitch()
	handle_flashlight()

func _process(delta):
	# Forward weapon input to weapon manager
	if weapon_manager:
		weapon_manager.process_input(delta)

# --------------------
# Movement
# --------------------
func handle_movement(delta):
	var input_dir := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	var speed := walk_speed

	if is_crouching:
		speed = crouch_speed
	elif Input.is_action_pressed("sprint"):
		speed = sprint_speed

	var wish_dir := (transform.basis * input_dir)
	wish_dir.y = 0
	wish_dir = wish_dir.normalized()

	var wish_velocity := wish_dir * speed
	var current_velocity := Vector2(velocity.x, velocity.z)

	if input_dir.length() > 0:
		current_velocity = current_velocity.move_toward(
			Vector2(wish_velocity.x, wish_velocity.z),
			acceleration * delta
		)
	else:
		current_velocity = current_velocity.move_toward(
			Vector2.ZERO,
			friction * delta
		)

	velocity.x = current_velocity.x
	velocity.z = current_velocity.y

# --------------------
# Jumping
# --------------------
func handle_jump():
	if is_on_floor() and Input.is_action_just_pressed("jump") and not is_crouching:
		velocity.y = jump_force

# --------------------
# Gravity
# --------------------
func handle_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0:
		velocity.y = 0

func handle_flashlight():
	if Input.is_action_just_pressed("flashlight_toggle"):
		flashlight.visible = not flashlight.visible

# --------------------
# Crouching
# --------------------
func handle_crouch(delta):
	var want_crouch := Input.is_action_pressed("crouch")

	# Check if we can stand up
	if is_crouching and not want_crouch:
		if not can_stand_up():
			want_crouch = true  # Stay crouched

	if want_crouch != is_crouching:
		is_crouching = want_crouch

	var capsule := collision.shape as CapsuleShape3D
	var target_height := crouch_height if is_crouching else stand_height
	capsule.height = lerp(capsule.height, target_height, crouch_lerp_speed * delta)

	var target_cam_y := crouch_camera_y if is_crouching else stand_camera_y

	# Move camera pivot instead of camera
	camera_pivot.position.y = lerp(camera_pivot.position.y, target_cam_y, crouch_lerp_speed * delta)

	# Keep camera at origin relative to pivot
	camera.position.y = 0

# Check if there's enough headroom to stand up
func can_stand_up() -> bool:
	var space_state := get_world_3d().direct_space_state

	# Calculate how much we need to check
	var height_difference := stand_height - crouch_height
	var check_distance := height_difference + 1.0  # Much larger margin to catch higher ceilings

	# Start from top of crouched capsule
	var start_height := crouch_height / 2.0

	# Do multiple raycasts in a circle pattern (more reliable with concave shapes)
	var raycast_positions := [
		Vector3.ZERO,  # Center
		Vector3(0.3, 0, 0),  # Right
		Vector3(-0.3, 0, 0),  # Left
		Vector3(0, 0, 0.3),  # Forward
		Vector3(0, 0, -0.3),  # Back
	]

	for offset in raycast_positions:
		var from: Vector3 = global_position + Vector3.UP * start_height + offset
		var to: Vector3 = from + Vector3.UP * check_distance

		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [self]
		query.collision_mask = 0xFFFFFFFF  # Check ALL layers for debugging

		var result := space_state.intersect_ray(query)

		if not result.is_empty():
			# Only block if it's on a layer we collide with
			if (result.collider.collision_layer & collision_mask) != 0:
				return false

	return true  # No hits, can stand

# --------------------
# Camera control
# --------------------
func update_camera_pitch():
	# Get recoil from weapon manager
	var recoil := 0.0
	if weapon_manager:
		recoil = weapon_manager.get_camera_recoil()

	var final_pitch := look_angle + recoil
	camera_pivot.rotation.x = deg_to_rad(final_pitch)

func die():
	print("Player died! Game Over.")
	health = 100
	global_position = Vector3.ZERO

# --------------------
# Stairs handling
# --------------------
func is_surface_too_steep(normal: Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > self.floor_max_angle

func _run_body_test_motion(from: Transform3D, motion: Vector3, result = null) -> bool:
	if not result: result = PhysicsTestMotionResult3D.new()
	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(self.get_rid(), params, result)

func _snap_down_to_stairs_check():
	var did_snap := false
	var floor_below : bool = %StairsBelowRayCast3D.is_colliding() and not is_surface_too_steep(%StairsBelowRayCast3D.get_collision_normal())
	var was_on_floor_last_frame = Engine.get_physics_frames() - _last_frame_was_on_floor == 1
	if not is_on_floor() and velocity.y <= 0 and (was_on_floor_last_frame or _snapped_to_stairs_last_frame) and floor_below:
		var body_test_result = PhysicsTestMotionResult3D.new()
		if _run_body_test_motion(self.global_transform, Vector3(0, -MAX_STEP_HEIGHT, 0), body_test_result):
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true
	_snapped_to_stairs_last_frame = did_snap

func _snap_up_to_stairs_check(delta) -> bool:
	if not is_on_floor() and not _snapped_to_stairs_last_frame: return false
	var expected_move_motion = self.velocity * Vector3(1, 0, 1) * delta
	var step_pos_with_clearance = self.global_transform.translated(expected_move_motion + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	var down_check_result = PhysicsTestMotionResult3D.new()
	if (_run_body_test_motion(step_pos_with_clearance, Vector3(0, -MAX_STEP_HEIGHT * 2, 0), down_check_result)
	and (down_check_result.get_collider().is_class('StaticBody3D') or down_check_result.get_collider().is_class('CSGShape3D'))):
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - self.global_position).y
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_collision_point() - self.global_position).y > MAX_STEP_HEIGHT: return false
		%StairsAheadRayCast3D.global_position = down_check_result.get_collision_point() + Vector3(0, MAX_STEP_HEIGHT, 0) + expected_move_motion.normalized() * 0.1
		%StairsAheadRayCast3D.force_raycast_update()
		if %StairsAheadRayCast3D.is_colliding() and not is_surface_too_steep(%StairsAheadRayCast3D.get_collision_normal()):
			self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			apply_floor_snap()
			_snapped_to_stairs_last_frame = true
			return true
	return false

# --------------------
# Public API for weapons
# --------------------
func get_camera() -> Camera3D:
	return camera

func is_moving() -> bool:
	return Vector2(velocity.x, velocity.z).length() > 0.1

func take_damage(damage: int, _hit_position: Vector3):
	health -= damage
	print("Player took ", damage, " damage! Health now: ", health)
	if health <= 0:
		die()

func get_health() -> int:
	return health
