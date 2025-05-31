extends CharacterBody2D
class_name Player

const Weapon = preload("res://scenes/based_scenes/weapon.gd")

# Состояния игрока
enum PlayerState { IDLE, WALK, HURT, DEAD }

@export var SPEED := 400.0
@export var max_health: int = 100

@export_category("Animations")
@export var idle_right_anim : String = "IdleR"
@export var idle_left_anim : String = "IdleL"
@export var walk_right_anim : String = "WalkR"
@export var walk_left_anim : String = "WalkL"
@export var hurt_right_anim : String = "HurtR"
@export var hurt_left_anim : String = "HurtL"
@export var death_anim : String = "Death"  # Анимация смерти

@onready var current_weapon: Weapon = null
@onready var player_sprite := $AnimatedSprite2D
@onready var weapon_pivot := $WeaponPivot

# Машина состояний
var current_state: PlayerState = PlayerState.IDLE
var is_facing_right: bool = true
var hurt_timer: float = 0.0

# Переменные игрока
var current_health: int
var weapons: Array[Weapon] = []
var jump_speed_boost: float = 0.0

func _ready():
	current_health = max_health
	if has_node("PlayerHurtbox"):
		$PlayerHurtbox.body_entered.connect(_on_body_entered_enemy_body)
	
	change_state(PlayerState.IDLE)

func _physics_process(delta):
	update_facing_direction()
	handle_movement()
	handle_weapon()
	update_animations()

func update_facing_direction():
	var mouse_pos = get_global_mouse_position()
	# Определяем направление взгляда по позиции курсора
	is_facing_right = mouse_pos.x > global_position.x

func handle_movement():
	var move_dir = Input.get_vector("left", "right", "up", "down")
	velocity = move_dir * SPEED
	move_and_slide()
	
	# Изменение состояния движения
	if move_dir.length() > 0:
		if current_state != PlayerState.WALK:
			change_state(PlayerState.WALK)
	else:
		if current_state != PlayerState.IDLE:
			change_state(PlayerState.IDLE)

func handle_weapon():
	if not current_weapon:
		return
	
	# Обновляем прицеливание оружия
	current_weapon.update_aim(get_global_mouse_position(), weapon_pivot)
	
	# Стрельба
	if Input.is_action_pressed("attack1"):
		var direction = (get_global_mouse_position() - global_position).normalized()
		current_weapon.try_shoot(direction, self)
	
	# Перезарядка
	if Input.is_action_just_pressed("reload"):
		current_weapon.try_reload()

func change_state(new_state: PlayerState):
	if current_state == new_state:
		return
	
	current_state = new_state
	# Можно добавить обработку входа в состояние

func update_animations():
	match current_state:
		PlayerState.IDLE:
			play_anim(idle_right_anim if is_facing_right else idle_left_anim)
		PlayerState.WALK:
			play_anim(walk_right_anim if is_facing_right else walk_left_anim)
		PlayerState.HURT:
			play_anim(hurt_right_anim if is_facing_right else hurt_left_anim)
		PlayerState.DEAD:
			play_anim(death_anim)

func pick_up_weapon(new_weapon: Weapon):
	if not is_instance_valid(new_weapon):
		return
	
	print("picked up: ", new_weapon.weapon_name)
	
	# Проверяем, есть ли уже такое оружие
	for weapon in weapons:
		if weapon.weapon_name == new_weapon.weapon_name:
			weapon.update_ammo(new_weapon.total_ammo)
			new_weapon.queue_free()
			return
	
	# Откладываем добавление оружия в иерархию
	call_deferred("_deferred_add_weapon", new_weapon)

func _deferred_add_weapon(new_weapon: Weapon):
	# Удаляем из текущего родителя
	if new_weapon.get_parent():
		new_weapon.get_parent().remove_child(new_weapon)
	
	# Добавляем к точке вращения
	weapon_pivot.add_child(new_weapon)
	new_weapon.z_index = 1  # Оружие поверх персонажа
	new_weapon.position = Vector2.ZERO
	
	# Настраиваем оружие
	new_weapon.ground_sprite.hide()
	new_weapon.hand_sprite.show()
	new_weapon.set_process(true)
	
	weapons.append(new_weapon)
	if weapons.size() == 1:
		switch_weapon(weapons.size() - 1)

func switch_weapon(index: int):
	if index < 0 or index >= weapons.size():
		return
	
	# Скрываем текущее оружие
	if current_weapon and is_instance_valid(current_weapon):
		current_weapon.hand_sprite.hide()
	
	print("swiitch")
	# Показываем новое
	current_weapon = weapons[index]
	current_weapon.hand_sprite.show()
	
	# Для правильного порядка отрисовки
	if current_weapon.get_parent() == weapon_pivot:
		weapon_pivot.move_child(current_weapon, weapon_pivot.get_child_count() - 1)

func take_damage(damage: int):
	if current_state == PlayerState.DEAD or current_state == PlayerState.HURT:
		return
	
	current_health -= damage
	if current_health <= 0:
		change_state(PlayerState.DEAD)
	else:
		change_state(PlayerState.HURT)

func die():
	# Логика смерти
	print("Player died!")
	# queue_free() - раскомментировать, когда будет готова система смерти
	
func _on_body_entered_enemy_body(body: Node) -> void:
	if body.is_in_group("hazards"):
		var damage = body.get_body_damage() if body.has_method("get_body_damage") else 15
		take_damage(damage)

func play_anim(anim_name: String):
	if (player_sprite.sprite_frames.has_animation(anim_name)): # Чтобы игра не упала, если не найдет анимацию
		player_sprite.play(anim_name)
