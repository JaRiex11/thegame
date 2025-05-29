extends CharacterBody2D
class_name PLayer

@onready var player_sprite = $AnimatedSprite2D

const Weapon = preload("res://scenes/based_scenes/weapon.gd")

@export var SPEED = 400.0
@export var max_health: int = 100

# Переменная для хранения текущего направления (пригодится для idle)
var is_facing_right = true
var timer_jump = Timer.new()

var current_health: int
var weapons: Array[Weapon] = []
@onready var current_weapon: Weapon = null

func _ready():
	current_health = max_health
	if has_node("PlayerHurtbox"):
		$PlayerHurtbox.body_entered.connect(_on_body_entered_enemy_body)

func _physics_process(delta):
	#var mouse_pos = get_global_mouse_position()
	#var look_dir = (mouse_pos - global_position).normalized()
	#rotation = look_dir.angle()
	
	var move_dir = Input.get_vector("left", "right", "up", "down")
	velocity = move_dir * SPEED
	move_and_slide()
	
	if move_dir.x != 0 or move_dir.y != 0:
		if Input.is_action_just_pressed("jump"):
			SPEED = 500
			timer_jump.wait_time = 0.5
			SPEED = 400
		elif move_dir.x > 0 or (move_dir.y != 0 and is_facing_right):
			player_sprite.play("WalkR")
			is_facing_right = true
		else:
			player_sprite.play("WalkL")
			is_facing_right = false
	else:
		if is_facing_right:
			player_sprite.play("IdleR")
		else:
			player_sprite.play("IdleL")
	
	if current_weapon:
		# Получаем позицию курсора
		var mouse_pos = get_global_mouse_position()
		# Обновляем прицеливание оружия
		current_weapon.update_aim(mouse_pos)

		# Стрельба
		if Input.is_action_pressed("attack1"):
			var look_dir = (mouse_pos - global_position).normalized()
			handle_shooting(look_dir)
	
	if Input.is_action_just_pressed("reload") and current_weapon:
		handle_reload()

func handle_shooting(direction: Vector2):
	if current_weapon:
		current_weapon.shoot(direction, self)  # Передаём направление и владельца

		# Анимация отдачи
		#$AnimationPlayer.play("weapon_recoil")

		# Визуальный эффект
		#$MuzzleFlash.restart()
		#$MuzzleFlash.emitting = true

func handle_reload():
	print("Перезаряжаем оружие")
	current_weapon.reload()

func pick_up_weapon(new_weapon: Weapon):
	# Проверяем, не удалён ли уже объект
	if not is_instance_valid(new_weapon):
		return
	
	# Если оружие уже есть - добавить патроны
	print("picked up: ", new_weapon.weapon_name)
	for weapon in weapons:
		if weapon.weapon_name == new_weapon.weapon_name:
			weapon.update_ammo(new_weapon.total_ammo)
			new_weapon.queue_free()
			return
			
	# Новое оружие
	# Переносим оружие в инвентарь
	new_weapon.get_parent().remove_child(new_weapon)
	add_child(new_weapon)
	
	# Настраиваем оружие
	new_weapon.position = Vector2.ZERO
	new_weapon.ground_sprite.hide()
	new_weapon.hand_sprite.show()
	new_weapon.set_process(true)  # Важно!
	print("Оружие добавлено в инвентарь. Всего оружия: ", weapons.size())
	print("current_weapon: ", current_weapon)
	weapons.append(new_weapon)
	switch_weapon(weapons.size() - 1)
	

func switch_weapon(index: int):
	if index < 0 or index >= weapons.size():
		return
	
	# Скрываем текущее оружие
	if current_weapon and is_instance_valid(current_weapon):
		current_weapon.hand_sprite.hide()
	
	# Показываем новое
	current_weapon = weapons[index]
	current_weapon.hand_sprite.show()

	# Для правильного порядка отрисовки
	move_child(current_weapon, get_child_count() - 1)

func take_damage(damage: int):
	current_health -= damage
	if current_health <= 0:
		die()

func die():
	# Логика смерти
	queue_free()

func _on_body_entered_enemy_body(body: Unit) -> void:
	print(current_health)
	if body.is_in_group("hazards"):
		# Получаем компонент урона от объекта
		if body.has_method("get_body_damage"):
			take_damage(body.get_body_damage())
		else:
			take_damage(15)
