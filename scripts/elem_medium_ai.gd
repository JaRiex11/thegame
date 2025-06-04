extends Unit
class_name ElemMediumAI

#состояния:
#поиск, преследование


# Переменные
var current_target: CharacterBody2D = null
# тут код
func _ready() -> void:
	super._ready() # Расширяем метод родителя
	# Тут свой код

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Обновляем таймеры
	#_update_timers(delta)
	
	# Логика состояний

func _handle_state_logic(delta: float) -> void:
	super._handle_state_logic(delta)
	match current_state:
		UNIT_STATE.CHASE:
			_chase_state(delta)
		UNIT_STATE.PATROL:
			_patrol_state(delta)
	pass

func _chase_state(delta) -> void:
	pass

func _patrol_state(delta) -> void:
	pass

#func _handle_patrol_state(delta: float) -> void:
	#if patrol_points.is_empty():
		#return
		#
	#var target_point = patrol_points[current_patrol_index]
	#
	#if global_position.distance_to(target_point) < 10.0:
		#patrol_timer += delta
		#if patrol_timer >= patrol_wait_time:
			#patrol_timer = 0.0
			#current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	#else:
		#velocity = (target_point - global_position).normalized() * patrol_speed
	#pass

#func _handle_chase_state(delta: float) -> void:
	#if not _is_target_visible(current_target):
		#_lose_target()
		#return
		#
	#last_known_position = current_target.global_position
	#velocity = (current_target.global_position - global_position).normalized() * chase_speed
	#pass
