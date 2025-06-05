extends CharacterBody2D
class_name Bullet

var is_from_player: bool = false
var owner_pos: Vector2
var speed: float
var base_damage: float
var direction: Vector2
var knockback_force: float
var damage_element: ElemSys.ELEMENT = ElemSys.ELEMENT.NONE

# Параметры снижения урона
@export var max_distance: float = 1000.0  # Максимальная дистанция действия пули
@export var falloff_start: float = 300.0  # Дистанция начала снижения урона
@export var falloff_end: float = 800.0    # Дистанция, где урон минимален
@export var min_damage_factor: float = 0.3  # Минимальный % от базового урона (30%)

var traveled_distance: float = 0.0
var start_position: Vector2

func _ready() -> void:
	# Назначаем velocity один раз при инициализации
	velocity = direction * speed
	start_position = global_position
	if is_from_player:
		set_collision_mask_value(7, false)
	print("Выстрел")

func _physics_process(delta: float) -> void:
	var movement = velocity * delta
	traveled_distance += movement.length()
	
	# Проверяем, не превысили ли максимальную дистанцию
	if traveled_distance > max_distance:
		queue_free()
		return
	
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
	base_damage = _damage
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
	
	 # Рассчитываем текущий урон с учетом дистанции
	var current_damage = get_current_damage()
	
	# Наносим урон
	body.take_damage(
		current_damage,
		owner_pos,
		knockback_force,
		damage_element
	)

# Рассчитываем текущий урон с учетом дистанции
func get_current_damage() -> int:
	# Если не достигли точки начала снижения - полный урон
	if traveled_distance <= falloff_start:
		return base_damage
	
	# Если прошли точку минимального урона - возвращаем минимальный
	if traveled_distance >= falloff_end:
		return int(base_damage * min_damage_factor)
	
	# Линейная интерполяция между полным и минимальным уроном
	var falloff_factor = (traveled_distance - falloff_start) / (falloff_end - falloff_start)
	return int(lerp(base_damage, base_damage * min_damage_factor, falloff_factor))
