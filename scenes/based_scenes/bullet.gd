extends CharacterBody2D

var is_from_player: bool = false
var owner_pos: Vector2
var speed: float
var damage: int
var direction: Vector2
var knockback_force: float
var damage_element: ElemSys.ELEMENT = ElemSys.ELEMENT.NONE

func _ready() -> void:
	# Назначаем velocity один раз при инициализации
	velocity = direction * speed
	if is_from_player:
		set_collision_mask_value(7, false)

func _physics_process(delta: float) -> void:
	# Используем move_and_collide для точного определения столкновений
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var body = collision.get_collider()
		_handle_collision(body)
		queue_free()

func init_components(
	_owner_pos: Vector2,
	_direction: Vector2,
	_speed: float,
	_damage: int,
	_knockback_force: float,
	_damage_element: ElemSys.ELEMENT,
	_is_from_player: bool = false
	) -> void:
	z_index = -1
	owner_pos = _owner_pos
	direction = _direction.normalized()
	speed = _speed
	damage = _damage
	knockback_force = _knockback_force + 100
	damage_element = _damage_element
	is_from_player = _is_from_player
	velocity = direction * speed
	
	if is_from_player:
		set_collision_mask_value(7, false)

func _handle_collision(body: Node) -> void:
	if not body.has_method("take_damage"):
		return
	
	# Проверяем, не попали ли в своего (игрока, если пуля от игрока)
	if body.is_in_group("player") and is_from_player:
		return
	
	# Наносим урон
	body.take_damage(
		damage,
		owner_pos,
		knockback_force,
		damage_element
	)
