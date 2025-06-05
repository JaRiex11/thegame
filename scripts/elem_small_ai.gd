extends Elemental
class_name ElemSmallAI

#region Экспортируемые переменные
@export_category("AI Settings")
@export var patrol_speed := 80.0
@export var chase_speed := 180.0
@export var patrol_wait_time := 1.0
@export var search_duration := 5.0
@export var attack_prepare_time := 0.5
@export var dash_speed := 500.0
@export var dash_duration := 0.3
@export var vision_check_interval := 0.5 # Как часто проверяем прямую видимость
#endregion

#region Внутренние переменные
var current_target: CharacterBody2D = null
var last_known_position: Vector2 = Vector2.ZERO
var patrol_points: Array[Vector2] = []
var current_patrol_index := 0
var patrol_timer := 0.0
var search_timer := 0.0
var prepare_timer := 0.0
var dash_timer := 0.0
var is_dashing := false
var vision_timer := 0.0
var potential_targets: Array[CharacterBody2D] = []
#endregion

func _ready() -> void:
	super._ready()
	# Убедитесь что нода ViewArea существует
	if not has_node("ViewArea"):
		push_error("ViewArea node is missing!")
	#else:
		#$ViewArea.body_entered.connect(_on_view_area_body_entered)
		#$ViewArea.body_exited.connect(_on_view_area_body_exited)
	
	add_to_group("hazards")
	_generate_patrol_points(4)
	move_speed = patrol_speed
	change_state(UNIT_STATE.PATROL)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_timers(delta)  # Добавлен вызов таймеров
	
	if Engine.get_frames_drawn() % 30 == 0: # Выводим раз в 0.5 секунды
		print("State: ", current_state, 
			  " Patrol index: ", current_patrol_index,
			  " Patrol timer: ", patrol_timer,
			  " Search timer: ", search_timer)
			
	# Убедитесь что velocity вычисляется перед move_and_slide
	velocity = _calculate_movement() * move_speed
	
	# Только если не в состоянии атаки или подготовки
	if current_state != UNIT_STATE.ATTACK || prepare_timer <= 0:
		move_and_slide()
	
	queue_redraw()
	#_draw()

func _update_timers(delta) -> void:
	#if patrol_timer > 0:
		#patrol_timer -= delta
	#
	#if search_timer > 0:
		#search_timer -= delta
		#if search_timer <= 0 and current_state == UNIT_STATE.SEARCH:
			## Время поиска истекло - возвращаемся к патрулированию
			#last_known_position = Vector2.ZERO
			#change_state(UNIT_STATE.PATROL)
	#
	#if prepare_timer > 0:
		#prepare_timer -= delta
	#
	#if dash_timer > 0:
		#dash_timer -= delta
		#if dash_timer <= 0:
			#_end_dash()
	super._update_timers(delta)
	
	# Обновляем все таймеры
	if patrol_timer > 0:
		patrol_timer -= delta
	
	if search_timer > 0:
		search_timer -= delta
		if search_timer <= 0 and current_state == UNIT_STATE.SEARCH:
			# Время поиска истекло - возвращаемся к патрулированию
			last_known_position = Vector2.ZERO
			change_state(UNIT_STATE.PATROL)
	
	if prepare_timer > 0:
		prepare_timer -= delta
		# При подготовке к атаке замедляем движение
		if current_state == UNIT_STATE.ATTACK:
			move_speed = patrol_speed * 0.3
	
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			_end_dash()
	
	vision_timer -= delta
	if vision_timer <= 0:
		vision_timer = vision_check_interval
		_check_visibility_of_potential_targets()

func _update_animation() -> void:
	if not animated_sprite:
		return
		
	match current_state:
		UNIT_STATE.IDLE:
			play_anim(idle_right_anim if is_facing_right else idle_left_anim)
		UNIT_STATE.MOVE:
			play_anim(walk_right_anim if is_facing_right else walk_left_anim)
		UNIT_STATE.CHASE:
			play_anim(walk_right_anim if is_facing_right else walk_left_anim)
		UNIT_STATE.ATTACK:
			play_anim(attack_right_anim if is_facing_right else attack_left_anim)
		_:
			play_anim(idle_right_anim if is_facing_right else idle_left_anim)

func _calculate_movement() -> Vector2:
	var direction := Vector2.ZERO
	
	match current_state:
		UNIT_STATE.CHASE:
			if current_target:
				direction = (current_target.global_position - global_position).normalized()
			elif last_known_position != Vector2.ZERO:
				direction = (last_known_position - global_position).normalized()
		
		UNIT_STATE.PATROL:
			if patrol_points.size() > 0:
				var target_point = patrol_points[current_patrol_index]
				direction = (target_point - global_position).normalized()
		
		UNIT_STATE.SEARCH:
			if last_known_position != Vector2.ZERO:
				direction = (last_known_position - global_position).normalized()
	
	return direction

func _handle_state_logic(delta: float) -> void:
	match current_state:
		UNIT_STATE.PATROL:
			_patrol_state(delta)
		UNIT_STATE.CHASE:
			_chase_state(delta)
		UNIT_STATE.SEARCH:
			_search_state(delta)
		UNIT_STATE.ATTACK:
			_attack_state(delta)
		_:
			super._handle_state_logic(delta)

func _patrol_state(delta: float) -> void:
	if patrol_points.is_empty():
		_generate_patrol_points(4)
		return
	
	var target_point = patrol_points[current_patrol_index]
	var distance = global_position.distance_to(target_point)
	
	if distance < 10.0:
		if patrol_timer <= 0:
			# Ждем указанное время перед переходом к следующей точке
			patrol_timer = patrol_wait_time
			change_state(UNIT_STATE.IDLE)
	else:
		# Двигаемся к точке
		move_speed = patrol_speed
		change_state(UNIT_STATE.MOVE)

func _idle_state(delta: float) -> void:
	super._idle_state(delta)
	# В состоянии IDLE проверяем таймер патрулирования
	if patrol_timer <= 0:
		# Переходим к следующей точке
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		print("Moving to next patrol point: ", current_patrol_index)
		change_state(UNIT_STATE.PATROL)

func _chase_state(delta: float) -> void:
	if not current_target and last_known_position != Vector2.ZERO:
		# Если цель потеряна, но есть последняя позиция
		change_state(UNIT_STATE.SEARCH)
		return
	
	if current_target:
		# Всегда обновляем последнюю позицию, пока видим цель
		if can_see_target(current_target):
			last_known_position = current_target.global_position
			
			var distance = global_position.distance_to(current_target.global_position)
			if distance <= attack_range:
				_start_attack_prepare()
				return
		else:
			# Цель больше не видна
			change_state(UNIT_STATE.SEARCH)
			return
		
		move_speed = chase_speed
	else:
		# Цели нет вообще
		change_state(UNIT_STATE.PATROL)

func _search_state(delta: float) -> void:
	if last_known_position == Vector2.ZERO:
		change_state(UNIT_STATE.PATROL)
		return
	
	var distance = global_position.distance_to(last_known_position)
	
	if distance < 10.0:
		# Достигли последней известной позиции
		if search_timer <= 0:
			# Начинаем отсчет времени поиска
			search_timer = search_duration
		change_state(UNIT_STATE.IDLE)
	else:
		# Двигаемся к последней известной позиции
		move_speed = chase_speed * 0.7

func _start_attack_prepare() -> void:
	change_state(UNIT_STATE.ATTACK)
	prepare_timer = attack_prepare_time
	velocity = Vector2.ZERO

func _attack_state(delta: float) -> void:
	if prepare_timer > 0:
		# Готовимся к атаке - просто ждем
		return
	
	# Начинаем рывок
	if not is_dashing:
		_start_dash()

func _start_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration
	
	# Определяем направление рывка
	var dash_direction: Vector2
	if current_target:
		dash_direction = (current_target.global_position - global_position).normalized()
	else:
		# Если цели нет (маловероятно), используем текущее направление
		dash_direction = Vector2.RIGHT if is_facing_right else Vector2.LEFT
	
	# Делаем рывок сквозь игрока (на 50 пикселей дальше)
	var dash_target = global_position + dash_direction * (attack_range + 50)
	velocity = dash_direction * dash_speed
	move_speed = dash_speed

func _end_dash() -> void:
	is_dashing = false
	move_speed = chase_speed
	velocity = Vector2.ZERO
	
	# После рывка проверяем, видим ли еще цель
	if current_target and can_see_target(current_target):
		# Если цель все еще видна, продолжаем преследование
		change_state(UNIT_STATE.CHASE)
	else:
		# Иначе начинаем поиск
		if current_target:
			last_known_position = current_target.global_position
		current_target = null
		search_timer = search_duration
		change_state(UNIT_STATE.SEARCH)

# Обработчики сигналов Area2D
func _on_view_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var player = body as CharacterBody2D
		if not potential_targets.has(player):
			potential_targets.append(player)
		
		if can_see_target(player):
			current_target = player
			last_known_position = player.global_position
			move_speed = chase_speed
			change_state(UNIT_STATE.CHASE)

func _on_view_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		var player = body as CharacterBody2D
		potential_targets.erase(player)
		if current_target == player:
			# Запоминаем последнюю позицию и начинаем поиск
			last_known_position = player.global_position
			current_target = null
			change_state(UNIT_STATE.SEARCH)

# Периодическая проверка видимости всех потенциальных целей
func _check_visibility_of_potential_targets() -> void:
	if current_target and can_see_target(current_target):
		return  # Цель уже видна
	
	# Проверяем всех потенциальных целей
	for target in potential_targets:
		if can_see_target(target):
			current_target = target
			last_known_position = target.global_position
			move_speed = chase_speed
			change_state(UNIT_STATE.CHASE)
			return
	
	# Если дошли сюда, значит ни одна цель не видна
	if current_target:
		last_known_position = current_target.global_position
		current_target = null
		change_state(UNIT_STATE.SEARCH)

func _generate_patrol_points(count: int) -> void:
	patrol_points.clear()
	print("Generating patrol points around: ", global_position)
	for i in range(count):
		var random_offset = Vector2(
			randf_range(-100, 100),
			randf_range(-100, 100)
		)
		patrol_points.append(global_position + random_offset)
		print("Point ", i, ": ", global_position + random_offset)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self:
		body.take_damage(body_damage, global_position, 100.0, current_element)

func _draw():
	# Рисуем точки патрулирования
	for i in range(patrol_points.size()):
		var point = patrol_points[i]
		var color = Color.RED if i == current_patrol_index else Color.GREEN
		draw_circle(to_local(point), 10, color)
	
	# Рисуем путь к текущей точке
	if patrol_points.size() > 0:
		draw_line(Vector2.ZERO, to_local(patrol_points[current_patrol_index]) - position, Color.YELLOW, 2)
	
	# Рисуем направление движения
	if velocity.length() > 0:
		draw_line(Vector2.ZERO, velocity.normalized() * 50, Color.BLUE, 3)
