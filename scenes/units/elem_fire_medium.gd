extends ElemMediumAI
class_name ElemFireMedium

# Настройки
@export var fire_attack_range := 150.0
@export var fire_detection_range := 300.0
@export var attack_cooldown := 1.5

# Состояния атаки
var is_attacking := false
var attack_cooldown_timer := 0.0

func _ready() -> void:
	super._ready()
	add_to_group("hazards")
	attack_range = fire_attack_range

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	
	if is_attacking:
		_handle_attack_state()
	else:
		_handle_movement(delta)
	
	move_and_slide()

func _update_timers(delta: float) -> void:
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

func _handle_movement(delta: float) -> void:
	if !current_target:
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	var direction = (current_target.global_position - global_position).normalized()
	
	# Логика преследования
	if distance > fire_detection_range:
		current_target = null
		change_state(UNIT_STATE.PATROL)
	elif distance > fire_attack_range:
		# Активно преследуем игрока
		velocity = direction * chase_speed
		change_state(UNIT_STATE.CHASE)
	else:
		# На дистанции атаки
		change_state(UNIT_STATE.ATTACK)
		_try_attack(direction)
	
	_update_facing_direction(direction.x)
	_update_animation()

func _try_attack(direction: Vector2) -> void:
	if attack_cooldown_timer <= 0:
		_start_ranged_attack(direction)

func _start_ranged_attack(direction: Vector2) -> void:
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	velocity = Vector2.ZERO
	
	if direction.x > 0:
		play_anim("attack_right")
	else:
		play_anim("attack_left")
	
	$Hitbox.disabled = false
	await get_tree().create_timer(0.2).timeout
	$Hitbox.disabled = true
	is_attacking = false

func _handle_attack_state() -> void:
	velocity = Vector2.ZERO

func _update_facing_direction(x_direction: float) -> void:
	$Sprite2D.flip_h = x_direction < 0

func _update_animation() -> void:
	if is_attacking:
		return
	
	if velocity.length() > 10:
		play_anim("walk")
	else:
		play_anim("idle")

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Player:
		current_target = body
		change_state(UNIT_STATE.CHASE)
