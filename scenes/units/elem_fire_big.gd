extends FireElemental
class_name ElemFireBig

@export var large_attack_dist := 100
@export var small_attack_dist := 20
#region Экспортируемые переменные
@export_category("AI Settings")
@export var patrol_speed := 80.0
@export var chase_speed := 280.0
@export var patrol_wait_time := 1.0
@export var search_duration := 5.0
@export_category("Attack Settings")
@export var dash_speed := 1000.0  # Скорость рывка
@export var dash_duration := 0.5  # Длительность рывка
@export var dash_cooldown := 2.0  # Перезарядка рывка
@export var attack_duration := 0.5  # Длительность анимации атаки
#endregion

#region Внутренние переменные
var current_target: CharacterBody2D = null
var last_known_position: Vector2 = Vector2.ZERO
var patrol_points: Array[Vector2] = []
var current_patrol_index := 0
var patrol_timer := 0.0
var search_timer := 0.0
var is_searching := false
var is_target_in_sight := false

var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var is_attacking := false
var attack_timer := 0.0
#endregion

#region Основные функции
func _ready() -> void:
	super._ready()
	add_to_group("hazards")
	_generate_patrol_points(4)  # Генерация точек патрулирования
	move_speed = patrol_speed

func _physics_process(delta: float) -> void:
	#super._physics_process(delta)
	
	# Обновляем таймеры
	_update_timers(delta)
	
	# Логика состояний
	if is_attacking:
		_handle_attack_state(delta)
	elif is_dashing:
		_handle_dash_state(delta)
	elif current_target:
		_handle_combat_state(delta)
	elif is_searching:
		_handle_search_state(delta)
	else:
		_handle_patrol_state(delta)
	
	#move_and_collide(velocity * delta)
	move_and_slide()
	#_draw_debug()
	super._physics_process(delta)

func _update_timers(delta: float) -> void:
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity = Vector2.ZERO
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false

func _handle_combat_state(delta: float) -> void:
	if not _is_target_visible(current_target):
		_lose_target()
		return

	var distance_to_target = global_position.distance_to(current_target.global_position)
	last_known_position = current_target.global_position

	# Логика атак
	if distance_to_target <= small_attack_dist and not is_attacking and dash_cooldown_timer <= 0:
		_start_melee_attack()
	elif distance_to_target <= large_attack_dist and not is_dashing and dash_cooldown_timer <= 0:
		_start_dash_attack()
	else:
		# Обычное преследование
		velocity = (current_target.global_position - global_position).normalized() * chase_speed

func _start_dash_attack() -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	var direction = (current_target.global_position - global_position).normalized()
	velocity = direction * dash_speed

	# Можно добавить эффекты рывка
	#$DashParticles.emitting = true

func _handle_dash_state(delta: float) -> void:
	# Плавное замедление рывка
	velocity = velocity.move_toward(Vector2.ZERO, delta * dash_speed * 2.0)

func _start_melee_attack() -> void:
	is_attacking = true
	attack_timer = attack_duration
	velocity = Vector2.ZERO
	
	# Определяем направление атаки
	var attack_dir = sign(current_target.global_position.x - global_position.x)
	if attack_dir > 0:
		play_anim("attack_right")
	else:
		play_anim("attack_left")
	
	# Наносим урон (можно через Area2D)
	$Hitbox.disabled = false
	await get_tree().create_timer(0.2).timeout  # Задержка перед уроном
	$Hitbox.disabled = true

func _handle_attack_state(delta: float) -> void:
	# Персонаж стоит на месте во время атаки
	velocity = Vector2.ZERO
	
func _handle_patrol_state(delta: float) -> void:
	if patrol_points.is_empty():
		return
		
	var target_point = patrol_points[current_patrol_index]
	
	if global_position.distance_to(target_point) < 10.0:
		patrol_timer += delta
		if patrol_timer >= patrol_wait_time:
			patrol_timer = 0.0
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	else:
		velocity = (target_point - global_position).normalized() * patrol_speed

func _handle_chase_state(delta: float) -> void:
	if not _is_target_visible(current_target):
		_lose_target()
		return
		
	last_known_position = current_target.global_position
	velocity = (current_target.global_position - global_position).normalized() * chase_speed

func _handle_search_state(delta: float) -> void:
	if global_position.distance_to(last_known_position) < 10.0:
		search_timer += delta
		if search_timer >= search_duration:
			is_searching = false
			search_timer = 0.0
	else:
		velocity = (last_known_position - global_position).normalized() * chase_speed

func _lose_target() -> void:
	is_searching = true
	search_timer = 0.0
	current_target = null
	move_speed = patrol_speed
#endregion

#region Логика обнаружения
func _is_target_visible(target: Node2D) -> bool:
	if not target:
		return false
	
	# Проверка дистанции
	if not is_target_in_sight:#global_position.distance_to(target.global_position) > sight_range:
		return false
		
	# Проверка прямой видимости
	return can_see_target(target)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Player: #and not current_target:
		is_target_in_sight = true
		if _is_target_visible(body):
			print("uvideli")
			current_target = body
			move_speed = chase_speed
			is_searching = false

func _on_view_area_body_exited(body: Node2D) -> void:
	if body is Player: #and not current_target:
		is_target_in_sight = false
#endregion

#region Вспомогательные функции
func _generate_patrol_points(count: int) -> void:
	patrol_points.clear()
	for i in range(count):
		var random_offset = Vector2(
			randf_range(-100, 100),
			randf_range(-100, 100)
		)
		patrol_points.append(global_position + random_offset)

#func _draw_debug() -> void:
	#if Engine.is_editor_hint():
		#return
		#
	## Рисуем точки патрулирования
	#for point in patrol_points:
		#draw_circle(point - global_position, 5.0, Color.GREEN)
		#
	## Рисуем последнюю известную позицию
	#if is_searching:
		#draw_circle(last_known_position - global_position, 8.0, Color.RED)
##endregion
