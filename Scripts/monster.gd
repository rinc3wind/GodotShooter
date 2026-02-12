extends CharacterBody3D
class_name Monster

# --------------------
# Base stats (override in child)
# --------------------
@export var max_health := 100
@export var speed := 4.0
@export var detection_range := 20.0
@export var attack_range := 2.0

# --------------------
# References
# --------------------
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var detection_ray: RayCast3D = $RayCast3D

var player: CharacterBody3D
var current_health: int
var is_attacking := false
var is_awake := false
var is_dead := false

# Damage accumulation (batches multiple hits in one frame)
var damage_this_frame := 0
var damage_positions: Array[Vector3] = []

# Animation state
var is_playing_damage_animation := false

# --------------------
# Initialization
# --------------------
func _ready():
	current_health = max_health
	player = GameManager.get_player()
	
	# Wait for NavigationServer to sync
	await get_tree().physics_frame
	set_physics_process(true)
	
	# Call child-specific setup
	monster_ready()

# Override in child classes for specific setup
func monster_ready():
	pass

# --------------------
# Main loop
# --------------------
func _physics_process(delta):
	# Process accumulated damage from previous frame
	if damage_this_frame > 0:
		process_accumulated_damage()
		damage_this_frame = 0
		damage_positions.clear()
	
	if is_dead or is_attacking or player == null:
		return
	
	# Wake up check
	if not is_awake:
		if can_see_player():
			is_awake = true
			on_wake_up()
		else:
			return  # Stay dormant
	
	# Behavior when awake
	var distance_to_player := global_position.distance_to(player.global_position)
	
	if distance_to_player <= attack_range and can_see_player():
		start_attack()
	else:
		move_toward_player(delta)

# --------------------
# Movement
# --------------------
func move_toward_player(_delta):
	if player == null:
		return
	# Don't move while playing damage animation
	if is_playing_damage_animation:
		velocity = Vector3.ZERO
		return
	nav_agent.target_position = player.global_position
	
	var current_pos := global_transform.origin
	var next_path_pos := nav_agent.get_next_path_position()
	
	# Calculate velocity (GZDoom-style: ignore Y for movement)
	var new_velocity := (next_path_pos - current_pos).normalized() * speed
	velocity.x = new_velocity.x
	velocity.z = new_velocity.z
	
	# Face movement direction
	if velocity.length() > 0.1:
		var look_target := Vector3(next_path_pos.x, global_position.y, next_path_pos.z)
		look_at(look_target, Vector3.UP)
	
	move_and_slide()
	on_moving()

# --------------------
# Combat
# --------------------
func start_attack():
	is_attacking = true
	velocity = Vector3.ZERO
	on_attack_start()
	
	# Wait for attack animation/logic
	await get_tree().create_timer(get_attack_duration()).timeout
	
	is_attacking = false
	on_attack_end()

func take_damage(damage: int, hit_position: Vector3 = Vector3.ZERO):
	if is_dead:
		return
	
	# Accumulate damage to process next frame
	damage_this_frame += damage
	if hit_position != Vector3.ZERO:
		damage_positions.append(hit_position)

func process_accumulated_damage():
	# Process all damage at once
	current_health -= damage_this_frame
	
	# Calculate average hit position for effects
	var avg_position := Vector3.ZERO
	if damage_positions.size() > 0:
		for pos in damage_positions:
			avg_position += pos
		avg_position /= damage_positions.size()
	
	# Call damage callback with total damage
	on_damaged(damage_this_frame, avg_position)
	
	# Wake up if hit
	if not is_awake:
		is_awake = true
		on_wake_up()
	
	# Check death
	if current_health <= 0:
		die()

func die():
	is_dead = true
	is_attacking = false
	velocity = Vector3.ZERO
	on_death()
	
	# Default: remove after death animation
	$CollisionShape3D.queue_free()
	$NavigationAgent3D.queue_free()
	$RayCast3D.queue_free()	
	await get_tree().create_timer(100).timeout
	queue_free()

# --------------------
# Detection
# --------------------
func can_see_player() -> bool:
	if player == null or detection_ray == null:
		return false
	
	# Check distance first (optimization)
	var distance := global_position.distance_to(player.global_position)
	if distance > detection_range:
		return false
	
	# Raycast to player's chest height
	var target_pos := player.global_position + Vector3(0, 1.2, 0)
	detection_ray.look_at(target_pos, Vector3.UP)
	detection_ray.force_raycast_update()
	
	if detection_ray.is_colliding():
		var collider := detection_ray.get_collider()
		return collider == player
	
	return false

# --------------------
# Override these in child classes
# --------------------

# Called when monster first sees the player
func on_wake_up():
	pass

# Called while moving each frame
func on_moving():
	# Don't override damage animation
	if is_playing_damage_animation:
		return
		
	if sprite:
		sprite.play("default")

# Called when attack begins
func on_attack_start():
	if sprite:
		sprite.play("attack")

# Called when attack ends
func on_attack_end():
	pass

# How long the attack takes (override for different attack durations)
func get_attack_duration() -> float:
	return 1.0

# Called when taking damage
func on_damaged(_damage: int, _hit_position: Vector3):
	print("Monster took ", _damage, " damage!")
	if sprite:
		is_playing_damage_animation = true
		sprite.play("damaged")
		
		# Wait for damage animation to finish
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("damaged"):
			var frame_count = sprite.sprite_frames.get_frame_count("damaged")
			var fps = sprite.sprite_frames.get_animation_speed("damaged")
			var duration = frame_count / fps if fps > 0 else 0.3
			await get_tree().create_timer(duration).timeout
		else:
			await get_tree().create_timer(0.3).timeout  # Default wait time
		
		is_playing_damage_animation = false

# Called when health reaches 0
func on_death():
	print("Monster died!")
	if sprite:
		sprite.play("death")
