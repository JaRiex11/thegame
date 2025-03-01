extends Area2D

@export var speed = 700
@export var damage = 50
var direction = Vector2()

func _ready() -> void:
	rotation = direction.angle()

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()


#func _on_body_entered(body: Node2D) -> void:
	#pass # Replace with function body.
