extends CharacterBody2D

@onready var player_sprite = $AnimatedSprite2D

const Weapon = preload("res://scenes/based_scenes/weapon.gd")

@export var SPEED = 400.0
@export var max_health: int = 100

# Переменная для хранения текущего направления (пригодится для idle)
var is_facing_right = true
var timer_jump = Timer.new()

var current_health: int
var weapons: Array = []
@onready var current_weapon: Node = null

func _ready():
	current_health = max_health

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
	
	if Input.is_action_pressed("attack1") and current_weapon:
		handle_shooting()
	
	if Input.is_action_just_pressed("reload") and current_weapon:
		handle_reload()

func handle_shooting():
	print("Стреляем из текущего оружия")
	current_weapon.shoot(Vector2.RIGHT.rotated(rotation))

func handle_reload():
	print("Перезаряжаем оружие")
	current_weapon.reload()

func pick_up_weapon(new_weapon: Weapon):
	# Если оружие уже есть - добавить патроны
	print("picked up: ", new_weapon.weapon_name)
	for weapon in weapons:
		if weapon.weapon_name == new_weapon.weapon_name:
			weapon.update_ammo(new_weapon.total_ammo)
			return
			
	# Новое оружие
	# Удаляем оружие из сцены уровня
	new_weapon.get_parent().remove_child(new_weapon)
	
	# Добавляем оружие как дочерний элемент игрока
	add_child(new_weapon)
	new_weapon.position = new_weapon.sprite_offset  # Устанавливаем позицию оружия относительно игрока
	weapons.append(new_weapon)
	
	print("Оружие добавлено в инвентарь. Всего оружия: ", weapons.size())
	print("current_weapon: ", current_weapon)
	
	switch_weapon(weapons.size() - 1)
	

func switch_weapon(index: int):
	if index < 0 or index >= weapons.size():
		print("Некорректный индекс оружия")
		return
		
	if current_weapon:
		current_weapon.hide()
		
	current_weapon = weapons[index]
	current_weapon.show()
s	player_sprite.texture = current_weapon.player_sprite_texture
	print("Текущее оружие:", current_weapon.weapon_name)
	print("current_weapon: ", current_weapon)

func take_damage(damage: int):
	current_health -= damage
	if current_health <= 0:
		die()

func die():
	# Логика смерти
	queue_free()
