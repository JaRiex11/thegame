extends CharacterBody2D
class_name Unit

#region Константы
enum UNIT_STATE {
	IDLE,
	MOVE,
	ATTACK,
	HURT,
	DEAD
}
#endregion

#region Экспортируемые переменные
@export var max_health := 100.0
@export var move_speed := 150.0
@export var attack_damage := 10.0
@export var attack_range := 50.0
@export_category("Visuals")
@export var sprite : Sprite2D
@export var animation_player : AnimationPlayer
@export_category("Animations")
@export var idle_right_anim : String = "IdleR"
@export var idle_left_anim : String = "IdleL"
@export var walk_right_anim : String = "WalkR"
@export var walk_left_anim : String = "WalkL"
@export var attack_right_anim : String = "AttackR"
@export var attack_left_anim : String = "AttackL"
@export var hurt_right_anim : String = "HurtR"
@export var hurt_left_anim : String = "HurtL"
@export var death_anim : String = "Death"  # Анимация смерти
#endregion

#region Внутренние переменные
var current_health : float
var current_state : UNIT_STATE = UNIT_STATE.IDLE
var target : Unit = null
var facing_direction := Vector2.RIGHT
var is_facing_right := true  # Для определения направления
var death_completed := false # Флаг завершения анимации смерти
#endregion

#region Встроенные функции
func _ready() -> void:
	current_health = max_health
	_initialize_components()
	change_state(UNIT_STATE.IDLE)

func _physics_process(delta: float) -> void:
	_update_movement(delta)
	_update_animation()
	_handle_state_logic(delta)
#endregion

#region Публичные функции
func take_damage(amount: float, attacker: Unit) -> void:
	if current_state == UNIT_STATE.DEAD: return
	current_health -= amount
	_play_hit_effect()
	if current_health <= 0: die()
	else: 
		change_state(UNIT_STATE.HURT)
		_knockback(attacker.global_position)

func die() -> void:
	change_state(UNIT_STATE.DEAD)
	set_physics_process(false)
	_play_death_effect()
	queue_free()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	_play_heal_effect()

func change_state(new_state: UNIT_STATE) -> void:
	if current_state == new_state:
		return
	
	_exit_state(current_state)
	current_state = new_state
	_enter_state(new_state)
#endregion

#region Внутренние методы (переопределяются в дочерних классах)
func _initialize_components() -> void:
	pass

func _update_movement(delta: float) -> void:
	if current_state == UNIT_STATE.DEAD:
		return
	
	var movement := _calculate_movement()
	velocity = movement * move_speed
	move_and_slide()
	
	if movement.length_squared() > 0.1:
		facing_direction = movement.normalized()
		_update_facing()

func _update_facing() -> void:
	if facing_direction.x != 0:
		is_facing_right = facing_direction.x > 0
		
		# Если состояние позволяет, меняем анимацию
		if current_state in [UNIT_STATE.IDLE, UNIT_STATE.MOVE]:
			change_state(current_state)

func _calculate_movement() -> Vector2:
	return Vector2.ZERO

func _handle_state_logic(delta: float) -> void:
	match current_state:
		UNIT_STATE.IDLE:
			_idle_state(delta)
		UNIT_STATE.MOVE:
			_move_state(delta)
		UNIT_STATE.ATTACK:
			_attack_state(delta)
		UNIT_STATE.HURT:
			_hurt_state(delta)
		UNIT_STATE.DEAD:
			_dead_state(delta)

func _enter_state(new_state: UNIT_STATE) -> void:
	var anim_name = ""
	
	match new_state:
		UNIT_STATE.IDLE:
			anim_name = idle_right_anim if is_facing_right else idle_left_anim
		UNIT_STATE.MOVE:
			anim_name = walk_right_anim if is_facing_right else walk_left_anim
		UNIT_STATE.ATTACK:
			anim_name = attack_right_anim if is_facing_right else attack_left_anim
			velocity = Vector2.ZERO
		UNIT_STATE.HURT:
			anim_name = hurt_right_anim if is_facing_right else hurt_left_anim
		UNIT_STATE.DEAD:
			anim_name = death_anim
			# Для анимации смерти подписываемся на её завершение
			if animation_player.has_animation(anim_name):
				animation_player.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)

	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
		
# Обработчик завершения анимации смерти
func _on_death_animation_finished(anim_name: String) -> void:
	if anim_name == death_anim:
		death_completed = true

func _exit_state(old_state: UNIT_STATE) -> void:
	pass

func _idle_state(delta: float) -> void:
	pass

func _move_state(delta: float) -> void:
	pass

func _attack_state(delta: float) -> void:
	pass

func _hurt_state(delta: float) -> void:
	pass

func _dead_state(delta: float) -> void:
	if death_completed:
		queue_free()

func _update_animation() -> void:
	pass

func _play_hit_effect() -> void:
	# Можно добавить particles или tween эффект
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func _play_heal_effect() -> void:
	# Для смерти используем специальную анимацию вместо твина
	if animation_player.has_animation(death_anim):
		animation_player.play(death_anim)
	else:
		# Фолбэк если анимации смерти нет
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 1.0)
		tween.tween_callback(queue_free)

func _play_death_effect() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func _knockback(source_position: Vector2) -> void:
	var direction = (global_position - source_position).normalized()
	var knockback_force = direction * 300.0
	velocity = knockback_force
	move_and_slide()
#endregion

#region Вспомогательные методы
func is_in_attack_range(target_position: Vector2) -> bool:
	return global_position.distance_to(target_position) <= attack_range

func can_see_target(target: Unit) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		target.global_position,
		collision_mask
	)
	var result = space_state.intersect_ray(query)
	return result.is_empty() or result.collider == target
#endregion
