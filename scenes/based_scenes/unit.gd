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
var target : Unit = null
var is_facing_right := true  # Для определения направления
var death_completed := false # Флаг завершения анимации смерти
var invincible := false
var animated_sprite : AnimatedSprite2D
#endregion

#region Встроенные функции
func _ready() -> void:
	animated_sprite = $AnimatedSprite2D
	current_health = max_health
	_initialize_components()
	change_state(UNIT_STATE.IDLE)

func _physics_process(delta: float) -> void:
#	_update_timers(delta)
	_update_movement(delta)
	_update_animation()
	_handle_state_logic(delta)
#endregion

#region Публичные функции
func take_damage(amount: float, attacker_pos: Vector2, attacker_kb_force: float) -> void:
	if current_state == UNIT_STATE.DEAD or invincible: return
	
	current_health -= amount
	print("unit's health: ", current_health)
	_play_hit_effect()
	#var attack_pos = attacker.global_position if is_instance_valid(attacker) else global_position
	_knockback(attacker_pos, attacker_kb_force)
	
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
	move_and_slide()
	
	_update_facing()

func _update_facing() -> void:
	if velocity.x > 0 or (velocity.y != 0 and is_facing_right):
		is_facing_right = true
	else: 
		is_facing_right = false

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
	move_and_slide()
#endregion

#region Вспомогательные методы
func play_anim(anim_name: String):
	if (animated_sprite.sprite_frames.has_animation(anim_name)): # Чтобы игра не упала, если не найдет анимацию
		animated_sprite.play(anim_name)

func is_in_attack_range(target_position: Vector2) -> bool:
	return global_position.distance_to(target_position) <= attack_range

func can_see_target(target: CharacterBody2D) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		target.global_position,
		collision_mask
	)
	var result = space_state.intersect_ray(query)
	return result.is_empty() or result.collider == target
#endregion
