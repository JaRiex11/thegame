extends Unit
class_name EnemyAI

#region Экспортируемые переменные
@export_category("AI Settings")
@export var patrol_speed := 80.0
@export var chase_speed := 150.0
@export var sight_range := 300.0
@export var patrol_wait_time := 2.0
@export var search_duration := 5.0
#endregion

#region Внутренние переменные
var current_target: Unit = null
var last_known_position: Vector2 = Vector2.ZERO
var patrol_points: Array[Vector2] = []
var current_patrol_index := 0
var patrol_timer := 0.0
var search_timer := 0.0
var is_searching := false
#endregion

#region Основные функции
func _ready() -> void:
	super._ready()
	_generate_patrol_points(4)  # Генерация точек патрулирования
	move_speed = patrol_speed

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if current_target:
		_handle_chase_state(delta)
	elif is_searching:
		_handle_search_state(delta)
	else:
		_handle_patrol_state(delta)
	
	_draw_debug()

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
func _is_target_visible(target: Unit) -> bool:
	if not target:
		return false
		
	# Проверка дистанции
	if global_position.distance_to(target.global_position) > sight_range:
		return false
		
	# Проверка прямой видимости
	return can_see_target(target)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not current_target:  # Player - замените на ваш класс игрока
		if _is_target_visible(body):
			current_target = body
			move_speed = chase_speed
			is_searching = false
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

func _draw_debug() -> void:
	if Engine.is_editor_hint():
		return
		
	# Рисуем точки патрулирования
	for point in patrol_points:
		draw_circle(point - global_position, 5.0, Color.GREEN)
		
	# Рисуем последнюю известную позицию
	if is_searching:
		draw_circle(last_known_position - global_position, 8.0, Color.RED)
#endregion
