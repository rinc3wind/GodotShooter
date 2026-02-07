extends Monster
class_name Imp

@export var fireball_scene: PackedScene

func _ready():
	# Set Imp-specific stats
	max_health = 60
	speed = 10.0
	attack_range = 20.0
	detection_range = 80.0
	
	# Call parent ready
	super._ready()

func monster_ready():
	# Imp-specific initialization
	pass

# --------------------
# Imp attacks with fireballs
# --------------------
func on_attack_start():
	super.on_attack_start()  # Play attack animation
	
	# Throw fireball after a short delay (animation windup)
	await get_tree().create_timer(0.3).timeout
	throw_fireball()

func get_attack_duration() -> float:
	return 0.9  # Total attack duration for Imp

func throw_fireball():
	if fireball_scene == null or player == null:
		return
	
	var fireball = fireball_scene.instantiate()
	
	# Set direction BEFORE adding to scene tree
	var target := player.global_position + Vector3(0, 1.5, 0)
	var spawn_pos := global_position + Vector3(0, 2.9, -1.5)
	fireball.direction = (target - spawn_pos).normalized()
	fireball.instigator = self
	
	# Now add to scene
	get_parent().add_child(fireball)
	fireball.global_position = spawn_pos

func on_wake_up():
	#print("Imp awakened!")
	pass

func on_damaged(damage: int, _hit_position: Vector3):
	super.on_damaged(damage, _hit_position)
	#print("Imp took ", damage, " damage!")

func on_death():
	super.on_death()
