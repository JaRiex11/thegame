extends Area2D

var owner_ref: WeakRef
var speed: float
var damage: int
var direction: Vector2

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body):
	var attacker = owner_ref.get_ref() if owner_ref else null
	if is_instance_valid(attacker) and body != attacker:
		if body.has_method("take_damage"):
			body.take_damage(damage, attacker)
	queue_free()
