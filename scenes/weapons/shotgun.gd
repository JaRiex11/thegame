extends Weapon

@export var pellets_count: int = 12  # Количество дробинок
@export var spread_angle: float = 30.0  # Угол разброса в градусах
@export var pellet_damage: int = 5  # Урон одной дробинки
@export var pellet_speed_variation: float = 0.2  # Разброс скорости

func _ready() -> void:
	super._ready()
	damage_element = ElemSys.ELEMENT.FIRE

func shoot(weapon_owner_pos: Vector2):
	current_state = WeaponState.SHOOTING
	emit_signal("state_changed", current_state)
	
	# Основное направление стрельбы
	var base_direction = (shoot_point.global_position - shoot_start_point.global_position).normalized()
	# Создаем несколько дробинок
	for i in range(pellets_count):
		var pellet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(pellet)
		
		# Рассчитываем случайное отклонение в пределах конуса
		var spread_rad = deg_to_rad(spread_angle)
		var random_angle = randf_range(-spread_rad/2, spread_rad/2)
		var pellet_direction = base_direction.rotated(random_angle)
		# Вариация скорости
		var pellet_speed = bullet_speed * (1 + randf_range(-pellet_speed_variation, pellet_speed_variation))
		# Инициализируем дробинку
		pellet.init_components(
			weapon_owner_pos,
			pellet_direction,
			pellet_speed,
			pellet_damage,  # Используем специальный урон для дробинки
			knockback_force,
			damage_element,
			is_players
		)
		pellet.global_position = shoot_point.global_position
		pellet.rotation = pellet_direction.angle()
	
	# Обновление боезапаса (1 выстрел = -1 патрон)
	current_ammo -= 1
	emit_signal("ammo_updated", current_ammo, magazine_size, total_ammo)
	
	# Откат стрельбы
	can_shoot = false
	shoot_cooldown.start(fire_rate)
	
	# Эффект отдачи
	var recoil_vector = -base_direction * 20
	var original_pos = position
	position += recoil_vector
	
	var tween = create_tween()
	tween.tween_property(self, "position", original_pos, 0.1)
