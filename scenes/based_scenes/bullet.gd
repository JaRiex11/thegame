extends Area2D

var owner_pos: Vector2
var speed: float
var damage: int
var direction: Vector2
var knockback_force: float
var damage_element: ElemSys.ELEMENT = ElemSys.ELEMENT.NONE 

func _process(delta: float) -> void:
	position += direction * speed * delta

func init_components(_owner_pos: Vector2, _direction: Vector2, _speed: float, _damage: int, _knockback_force: float, _damage_element: ElemSys.ELEMENT) -> void:
	z_index = -1
	owner_pos = _owner_pos
	direction = _direction
	speed = _speed
	damage = _damage
	knockback_force = _knockback_force
	damage_element = _damage_element
	print("bullet speed :", speed)

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage, owner_pos, knockback_force, damage_element)
	queue_free()
