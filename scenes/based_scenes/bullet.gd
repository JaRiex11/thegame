extends Area2D

var owner_pos: Vector2
var speed: float
var damage: int
var direction: Vector2
var knockback_force: float

func _process(delta: float) -> void:
	position += direction * speed * delta

func initialize_components(_owner_pos: Vector2, _direction: Vector2, _speed: float, _damage: int, _knockback_force: float) -> void:
	owner_pos = _owner_pos
	direction = _direction
	speed = _speed
	damage = _damage
	knockback_force = _knockback_force

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage, owner_pos, knockback_force)
	queue_free()
