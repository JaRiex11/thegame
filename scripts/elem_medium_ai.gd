extends Elemental
class_name ElemMediumAI

# Состояния

# Настройки
@export var chase_speed: float = 150.0   # Скорость преследования
@export var patrol_speed: float = 80.0   # Скорость патрулирования

# Переменные
var current_target: CharacterBody2D = null
var last_known_position: Vector2

func _ready() -> void:
	super._ready()
	# Инициализация начального состояния
	change_state(UNIT_STATE.PATROL)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_handle_state_logic(delta)
	move_and_slide()

func _handle_state_logic(delta: float) -> void:
	super._handle_state_logic(delta)
	
	match current_state:
		UNIT_STATE.PATROL:
			_patrol_state(delta)
		UNIT_STATE.CHASE:
			_chase_state(delta)
		UNIT_STATE.ATTACK:
			_attack_state(delta)

func _patrol_state(delta: float) -> void:
	# Логика патрулирования (можете использовать ваш закомментированный код)
	if current_target:
		change_state(UNIT_STATE.CHASE)

func _chase_state(delta: float) -> void:
	if not current_target:
		change_state(UNIT_STATE.PATROL)
		return
	
	var distance_to_target = global_position.distance_to(current_target.global_position)
	
	# Если цель в зоне атаки - переходим в состояние атаки
	if distance_to_target <= attack_range:
		change_state(UNIT_STATE.ATTACK)
		return
	
	# Двигаемся к цели
	var direction = (current_target.global_position - global_position).normalized()
	velocity = direction * chase_speed

func _attack_state(delta: float) -> void:
	if not current_target:
		change_state(UNIT_STATE.PATROL)
		return
	
	var distance_to_target = global_position.distance_to(current_target.global_position)
	
	# Если цель слишком далеко - продолжаем преследование
	if distance_to_target > attack_range * 1.2:  # Небольшой гистерезис
		change_state(UNIT_STATE.CHASE)
		return
	
	# Поддерживаем дистанцию атаки
	var direction = (current_target.global_position - global_position).normalized()
	
	if distance_to_target < attack_range * 0.9:  # Слишком близко - отступаем
		velocity = -direction * chase_speed * 0.7
	elif distance_to_target > attack_range * 1.1:  # Слишком далеко - приближаемся
		velocity = direction * chase_speed * 0.5
	else:  # Идеальная дистанция - стоим на месте
		velocity = Vector2.ZERO
	
	# Здесь можно добавить логику атаки
	# _try_attack()

# Функция для изменения состояния
func change_state(new_state: UNIT_STATE) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	# Можно добавить дополнительные действия при смене состояния

# Функция для установки цели
func set_target(target: CharacterBody2D) -> void:
	current_target = target
	if target and current_state == UNIT_STATE.PATROL:
		change_state(UNIT_STATE.CHASE)
