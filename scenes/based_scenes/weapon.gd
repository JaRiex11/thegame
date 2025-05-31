extends Node2D
class_name Weapon

# Состояния оружия
enum WeaponState { IDLE, SHOOTING, RELOADING }

# Характеристики оружия
@export_category("Связанные сцены")
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 700
@export var pivot_offset_y := 70  # Смещение точки вращения
@export var pivot_offset_x := 0  # Смещение точки вращения

@export_category("Характеристики")
@export var weapon_name: String = "Pistol"
@export var damage: int = 10
@export var fire_rate: float = 0.5
@export var magazine_size: int = 10
@export var max_ammo: int = 50
@export var reload_time: float = 1.5
@export var knockback_force: float = 500

@export var pivot_offset := Vector2(20, -10)  # Смещение точки вращения
@export var flip_offset := Vector2(-10, 0)  # Смещение при зеркалировании влево

var current_state: WeaponState = WeaponState.IDLE
var current_ammo: int
var total_ammo: int
var can_shoot: bool = true
var shoot_cooldown: Timer
var reload_timer: Timer

# Спрайты и позиции
@onready var ground_sprite: Sprite2D = $OnGroundSprite
@onready var hand_sprite: Sprite2D = $InHandSprite
@onready var shoot_point = $ShootPoint
@onready var collision := $Area2D/CollisionPolygon2D

signal state_changed(new_state)
signal ammo_updated(current, total)

func _ready():
	current_ammo = magazine_size
	total_ammo = max_ammo - magazine_size

	hand_sprite.z_index = 1
# Таймеры
	shoot_cooldown = Timer.new()
	add_child(shoot_cooldown)
	shoot_cooldown.timeout.connect(_on_shoot_cooldown_end)
	shoot_cooldown.one_shot = true
	
	reload_timer = Timer.new()
	add_child(reload_timer)
	reload_timer.timeout.connect(_on_reload_finished)
	reload_timer.one_shot = true

func update_aim(target_position: Vector2, weapon_pivot: Marker2D):
	# Вычисляем направление к цели
	var direction = (target_position - global_position).normalized()

	# Поворачиваем оружие
	
	#position.y = weapon_pivot.position.y + pivot_offset_y
	#position.x = weapon_pivot.position.x + pivot_offset_x
	
	rotation = direction.angle()
	
	# Вертикальное зеркалирование при стрельбе влево
	if direction.x < 0:
		hand_sprite.flip_h = false
		
		#position = flip_offset  # Смещаем для правильного позиционирования
	else:
		hand_sprite.flip_h = true
		#position = Vector2.ZERO
		
	# Всегда сохраняем ShootPoint справа от оружия
	shoot_point.position.x = abs(shoot_point.position.x)

func try_shoot(direction: Vector2, weapon_owner_pos: Vector2) -> bool:
	if current_state != WeaponState.IDLE or not can_shoot or current_ammo <= 0:
		return false
	
	shoot(direction, weapon_owner_pos)
	return true

func shoot(direction: Vector2, weapon_owner_pos: Vector2):
	current_state = WeaponState.SHOOTING
	emit_signal("state_changed", current_state)
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	# Порядок: (_owner_pos: Vector2, _direction: Vector2, _speed: float, _damage: int, _knockback_force: float)
	bullet.initialize_components(weapon_owner_pos, direction, bullet_speed, damage, knockback_force)
	bullet.global_position = shoot_point.global_position
	bullet.rotation = direction.angle()
	
	# Обновление боезапаса
	current_ammo -= 1
	emit_signal("ammo_updated", current_ammo, total_ammo)
	
	# Откат стрельбы
	can_shoot = false
	shoot_cooldown.start(fire_rate)
	print("current_ammo: ", current_ammo)
	
	# Эффект отдачи
	var recoil_vector = -direction * 10
	var original_pos = position
	position += recoil_vector
	
	# Анимация отдачи
	var tween = create_tween()
	tween.tween_property(self, "position", original_pos, 0.1)
	
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
	print("current_ammo: ", current_ammo)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Откладываем обработку подбора оружия
		call_deferred("_deferred_pick_up", body)

func _deferred_pick_up(player):
	# Отключаем коллизию перед удалением из сцены
	collision.set_deferred("disabled", true)
	
	# Передаем оружие игроку
	if is_instance_valid(player) and player.has_method("pick_up_weapon"):
		ground_sprite.hide()
		hand_sprite.show()
		player.pick_up_weapon(self)
		

func try_reload() -> bool:
	if current_state != WeaponState.IDLE or total_ammo <= 0 or current_ammo == magazine_size:
		return false
	
	_start_reloading()
	return true
	
func _start_reloading():
	current_state = WeaponState.RELOADING
	emit_signal("state_changed", current_state)
	reload_timer.start(reload_time)

func _on_shoot_cooldown_end():
	can_shoot = true
	if current_state == WeaponState.SHOOTING:
		current_state = WeaponState.IDLE
		emit_signal("state_changed", current_state)

func _on_reload_finished():
	var ammo_to_add = min(magazine_size - current_ammo, total_ammo)
	current_ammo += ammo_to_add
	total_ammo -= ammo_to_add
	
	emit_signal("ammo_updated", current_ammo, total_ammo)
	current_state = WeaponState.IDLE
	emit_signal("state_changed", current_state)

func update_ammo(new_ammo: int): # Нужно при подборе патронов для оружия
	total_ammo += new_ammo
	total_ammo = min(total_ammo, max_ammo)
