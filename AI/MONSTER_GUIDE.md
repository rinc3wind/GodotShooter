# Monster Class System Guide

## Architecture

```
Monster (monster.gd) - Base class
├── Generic enemy logic
├── Movement with NavigationAgent3D
├── Line-of-sight detection
├── Health and damage
├── Wake-up system
└── Attack state management

Imp (imp.gd) - Extends Monster
├── Fireball attack
├── Imp-specific stats
└── Custom behaviors
```

## Scene Structure

Your monster scenes should have:

```
Imp (CharacterBody3D) - attach imp.gd
├── NavigationAgent3D
├── AnimatedSprite3D
├── RayCast3D (for line-of-sight)
└── CollisionShape3D
```

## How It Works

### Base Monster Class

**Generic logic (all monsters use this):**
- Dormant until player is seen
- Pathfinding toward player
- Distance-based attack triggering
- Line-of-sight checking
- Health and damage system

**Override points (customize in child classes):**
- `on_wake_up()` - When first spotting player
- `on_moving()` - Called while moving (default plays "walk" animation)
- `on_attack_start()` - When attack begins
- `on_attack_end()` - When attack ends
- `get_attack_duration()` - How long attack takes
- `on_damaged()` - When taking damage
- `on_death()` - When dying

### Imp Class

**Imp-specific:**
- Ranged attack (fireballs)
- 15-unit attack range
- 60 HP
- Throws projectile during attack

## Creating New Monsters

### Example: Zombie (melee enemy)

```gdscript
extends Monster
class_name Zombie

func _ready():
	max_health = 100
	speed = 3.0
	attack_range = 2.0  # Melee range
	detection_range = 15.0
	super._ready()

func on_attack_start():
	super.on_attack_start()
	
	# Deal damage immediately (melee)
	if player and global_position.distance_to(player.global_position) <= attack_range:
		player.take_damage(15)

func get_attack_duration() -> float:
	return 0.6  # Quick melee swipe

func on_death():
	super.on_death()
	# Drop items, play death sound, etc.
```

### Example: Cacodemon (flying ranged enemy)

```gdscript
extends Monster
class_name Cacodemon

@export var projectile_scene: PackedScene

func _ready():
	max_health = 400
	speed = 3.0
	attack_range = 20.0  # Long range
	detection_range = 25.0
	super._ready()

# Override movement to fly/hover
func move_toward_player(delta):
	# Custom flying movement
	# Maybe maintain a certain height above ground
	super.move_toward_player(delta)

func on_attack_start():
	super.on_attack_start()
	await get_tree().create_timer(0.4).timeout
	shoot_projectile()

func shoot_projectile():
	# Similar to Imp but different projectile
	pass
```

## Important Notes

### Stats Override
Set monster-specific stats in the child's `_ready()` BEFORE calling `super._ready()`:

```gdscript
func _ready():
	max_health = 60  # Set first
	speed = 4.0
	super._ready()   # Then call parent
```

### Attack Flow
1. Monster enters attack range and has line-of-sight
2. `start_attack()` is called (sets is_attacking = true)
3. `on_attack_start()` is called (child class handles actual attack)
4. Waits for `get_attack_duration()` seconds
5. `on_attack_end()` is called
6. is_attacking = false, monster resumes movement

### Damage System
To damage the monster from weapons:

```gdscript
# In shotgun.gd or weapon scripts:
func handle_hit(result: Dictionary):
	if result.collider.has_method("take_damage"):
		result.collider.take_damage(damage_per_pellet, result.position)
```

The monster's `take_damage()` automatically:
- Reduces health
- Wakes up the monster if asleep
- Calls `on_damaged()` for effects
- Calls `die()` if health <= 0

### Detection System
- Monster stays dormant until `can_see_player()` returns true
- Checks distance first (optimization)
- Then does raycast to player's chest
- Once awake, stays awake (doesn't fall back asleep)
- Can be woken up by taking damage even if player isn't seen

## Animation Names Expected

The base Monster class expects these animations (if using AnimatedSprite3D):
- `"walk"` - Playing while moving
- `"attack"` - Playing during attack
- `"death"` - Playing when dying

Override `on_moving()` or `on_attack_start()` if your animations have different names.

## Tips

1. **GZDoom-style movement**: Horizontal velocity only, no Y movement (unless falling)
2. **Wake-up sounds**: Add in `on_wake_up()` override
3. **Pain sounds**: Add in `on_damaged()` override
4. **Death drops**: Add in `on_death()` override
5. **Projectile prediction**: For fast players, lead the shot in `throw_fireball()`

## Common Patterns

### Random idle behavior when awake but player out of range:
```gdscript
func move_toward_player(delta):
	if global_position.distance_to(player.global_position) > 30:
		# Player is far, wander randomly
		wander()
	else:
		super.move_toward_player(delta)
```

### Different attack types based on distance:
```gdscript
func on_attack_start():
	var dist = global_position.distance_to(player.global_position)
	if dist < 5.0:
		melee_attack()
	else:
		ranged_attack()
```
