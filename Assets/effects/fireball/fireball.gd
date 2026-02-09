extends Area3D
class_name Fireball

@export var speed := 20.0
@export var damage := 14
@export var lifetime := 5.0

var direction := Vector3.ZERO
var instigator: Node3D

func _ready():
	# Connect the signal via code for reliability
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body == instigator: return
	if body.has_method("take_damage"): body.take_damage(damage, global_position)
	queue_free()
