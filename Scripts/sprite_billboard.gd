extends Sprite3D

# Alternative simpler version using look_at

var player: Node3D

func _ready():
	# Get player reference from singleton (fast!)
	player = GameManager.get_player()
	
	if not player:
		push_warning("Player not found for sprite billboard")
		set_process(false)
		return
	
	# Disable built-in billboard
	billboard = BaseMaterial3D.BILLBOARD_DISABLED

func _process(_delta):
	if player:
		# Get player position but keep sprite's own Y level
		var target := Vector3(
			player.global_position.x,
			global_position.y,  # Use sprite's Y, not player's
			player.global_position.z
		)
		
		# Face the target
		look_at(target, Vector3.UP)