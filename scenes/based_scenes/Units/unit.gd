extends CharacterBody2D
class_name Unit

#region Константы
enum UNIT_STATE {
	IDLE,
	MOVE,
	ATTACK,
	HURT,
	DEAD,
	CHASE,
	PATROL,
	SEARCH
}
#endregion

#region Экспортируемые переменные
@export var max_health := 100.0
@export var move_speed := 150.0
@export var attack_damage := 10.0
@export var attack_range := 50.0
@export var knockback_resistance := 0.2  # Сопротивление отбрасыванию (0-1)
@export var body_damage := 25

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
var current_state : UNIT_STATE
var last_state: UNIT_STATE = UNIT_STATE.IDLE
var is_facing_right := true  # Для определения направления
var death_completed := false # Флаг завершения анимации смерти
var invincible := false
var animated_sprite : AnimatedSprite2D
# Стихийная логика
var current_status_effects: Array[ElemSys.STATUS_EFFECT] = []
var current_element: ElemSys.ELEMENT = ElemSys.ELEMENT.NONE
var is_elemental: bool = false
#endregion

#region Встроенные функции
func _ready() -> void:
	animated_sprite = $AnimatedSprite2D
	current_health = max_health
	_initialize_components()
	change_state(UNIT_STATE.IDLE)

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_movement(delta)
	_update_animation()
	_handle_state_logic(delta)
#endregion

#region Публичные функции
func take_damage(
	amount: float, 
	attacker_pos: Vector2, 
	attacker_kb_force: float, 
	damage_element: ElemSys.ELEMENT = ElemSys.ELEMENT.NONE
	) -> void:
	if current_state == UNIT_STATE.DEAD or invincible: return
	
	# Рассчитываем множитель урона в зависимости от элементов
	var damage_multiplier = _get_elemental_damage_multiplier(damage_element)
	print("  AttckElement: ", ElemSys.element_to_string(damage_element),
	"  DefElement: ", ElemSys.element_to_string(current_element),
	"Damage multiplier: ", damage_multiplier)
	
	var final_damage = amount * damage_multiplier
	if final_damage != 0:
		current_health -= final_damage
		_play_hit_effect()
		_knockback(attacker_pos, attacker_kb_force)
		
	print("unit's health: ", current_health)
	# Обрабатываем элементальные реакции
	if damage_element != ElemSys.ELEMENT.NONE:
		_process_elemental_reaction(damage_element)
	
	if current_health <= 0:
		die()
	else: 
		change_state(UNIT_STATE.HURT)

func die() -> void:
	change_state(UNIT_STATE.DEAD)
	set_physics_process(false)
	_play_death_effect()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	_play_heal_effect()

func change_state(new_state: UNIT_STATE) -> void:
	if current_state == new_state:
		return
	
	last_state = current_state
	_exit_state(current_state)
	current_state = new_state
	_enter_state(new_state)

func get_body_damage():
	return body_damage
#endregion

#region Стихийная логика
func _get_elemental_damage_multiplier(damage_element: ElemSys.ELEMENT) -> float:
	if is_elemental:
		if (damage_element == ElemSys.ELEMENT.NONE || damage_element == ElemSys.ELEMENT.PHYSIC): # Пока что 1.0, но вообще, надо 0
			return 0.5
		# Для элементалей учитываем их стихию
		return ElemSys.get_damage_multiplier(damage_element, current_element)
	else:
		# Для не-элементалей просто 1.0, если не учитываем статус эффекты
		return 1.0

func _process_elemental_reaction(attacker_element: ElemSys.ELEMENT) -> void:
	# Обрабатываем реакции между элементами
	if is_elemental:
		var reaction = ElemSys.get_reaction(attacker_element, current_element)
		print("attacker_element ", ElemSys.element_to_string(attacker_element),
			"  current_element ", ElemSys.element_to_string(current_element),
			"  Получили реакцию ", ElemSys.element_to_string(reaction))
		if reaction != ElemSys.ELEMENT.NONE:
			_apply_elemental_reaction(reaction)
	else:
		# Обрабатываем статус эффекты для не-элементалей
		var new_status = _get_status_from_element(attacker_element)
		if new_status != ElemSys.STATUS_EFFECT.NONE:
			_apply_status_effect(new_status)

func _apply_status_effect(status: ElemSys.STATUS_EFFECT) -> void:
	# Проверяем, есть ли уже такой эффект
	if current_status_effects.has(status):
		return
	
	print("append status effect: ", status)
	current_status_effects.append(status)
	
	# Проверяем возможные реакции между статус эффектами
	_check_status_interactions()

func _check_status_interactions() -> void:
	# Проверяем взаимодействия между статус эффектами
	if current_status_effects.has(ElemSys.STATUS_EFFECT.BURNING) and current_status_effects.has(ElemSys.STATUS_EFFECT.WET):
		# Произошла реакция пара
		_apply_elemental_reaction(ElemSys.ELEMENT.STEAM)
		# Удаляем статус эффекты
		current_status_effects.erase(ElemSys.STATUS_EFFECT.BURNING)
		current_status_effects.erase(ElemSys.STATUS_EFFECT.WET)

func _apply_elemental_reaction(reaction: ElemSys.ELEMENT) -> void:
	match reaction:
		ElemSys.ELEMENT.STEAM:
			print("Activate STEAM reaction")
			# Эффект пара - наносим дополнительный урон
			take_damage(10.0, global_position, 0, ElemSys.ELEMENT.STEAM)
			_play_steam_effect()
		# Можно добавить другие реакции

func _play_steam_effect() -> void:
	# Визуальный эффект пара
	# var steam_particles = preload("res://effects/steam_particles.tscn").instantiate()
	#add_child(steam_particles)
	#steam_particles.emitting = true
	#await get_tree().create_timer(1.0).timeout
	#steam_particles.queue_free()
	pass

func _get_status_from_element(element: ElemSys.ELEMENT) -> ElemSys.STATUS_EFFECT:
	match element:
		ElemSys.ELEMENT.FIRE: return ElemSys.STATUS_EFFECT.BURNING
		ElemSys.ELEMENT.WATER: return ElemSys.STATUS_EFFECT.WET
		_: return ElemSys.STATUS_EFFECT.NONE
#endregion

#region Внутренние методы (переопределяются в дочерних классах)
func _initialize_components() -> void:
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		push_error("AnimatedSprite2D missing in Unit scene!")
	# Автоподключение сигнала атаки

func _update_movement(delta: float) -> void:
	if current_state == UNIT_STATE.DEAD:
		return
	 
	var movement := _calculate_movement()
	velocity = movement * move_speed
	
	# Заменяем move_and_collide на move_and_slide для Godot 4.4
	move_and_slide()
	
	_update_facing()

func _update_facing() -> void:
	if velocity.x > 0 or (velocity.y != 0 and is_facing_right):
		is_facing_right = true
	else: 
		is_facing_right = false

func _update_timers(delta) -> void:
	pass

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
			if animated_sprite.sprite_frames.has_animation(anim_name):
				animated_sprite.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)
		
	play_anim(anim_name)

# Обработчик завершения анимации смерти
func _on_death_animation_finished() -> void:
	death_completed = true

func _exit_state(old_state: UNIT_STATE) -> void:
	pass

func _idle_state(delta: float) -> void:
	if is_facing_right:
		play_anim(idle_right_anim)
	else:
		play_anim(idle_left_anim)

func _move_state(delta: float) -> void:
	pass

func _attack_state(delta: float) -> void:
	pass

func _hurt_state(delta: float) -> void:
	pass

func _dead_state(delta: float) -> void:
	if death_completed:
		queue_free()

func _chase_state(delta) -> void:
	pass

func _patrol_chase(delta: float) -> void:
	pass

func _update_animation() -> void:
	pass

func _play_hit_effect() -> void:
	# Можно добавить particles или tween эффект
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func _play_heal_effect() -> void:
	pass

func _play_death_effect() -> void:
	$Hitbox.set_deferred("disabled", true)
	if animated_sprite.sprite_frames.has_animation(death_anim):
		animated_sprite.play(death_anim)
		await animated_sprite.animation_finished
	else:
		# Фолбэк если анимации смерти нет
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.0)
		await tween.finished
	queue_free()

func _knockback(source_position: Vector2, source_knockback_force: float) -> void:
	var direction = (global_position - source_position).normalized()
	var knockback_force = direction * source_knockback_force * knockback_resistance
	velocity = knockback_force
	move_and_collide(velocity, get_process_delta_time())
#endregion

#region Вспомогательные методы
func play_anim(anim_name: String):
	if (animated_sprite.sprite_frames.has_animation(anim_name)): # Чтобы игра не упала, если не найдет анимацию
		animated_sprite.play(anim_name)
	else:
		print("Анимация ", anim_name, " не найдена")

func is_in_attack_range(target_position: Vector2) -> bool:
	return global_position.distance_to(target_position) <= attack_range

func can_see_target(target: CharacterBody2D) -> bool:
	if not target or not is_instance_valid(target):
		return false
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		target.global_position,
		collision_mask
	)
	# Исключаем из проверки самого себя и возможные другие объекты
	query.exclude = [self]
	#query.collide_with_areas = false
	#query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	# Для отладки (можно убрать после тестов)
	#print("Ray collider:", result.collider.name if result else "none")
	if result.is_empty():  # Если луч не попал ни в что
		return false
	return result.collider == target  # Теперь доступ безопасен
#endregion
