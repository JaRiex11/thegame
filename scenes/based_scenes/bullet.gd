extends Area2D

var speed: float
var damage: int
var direction: Vector2

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
