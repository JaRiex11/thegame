extends CharacterBody2D
class_name Player

@onready var player_sprite = $AnimatedSprite2D

const Weapon = preload("res://scenes/based_scenes/weapon.gd")

enum PlayerState { IDLE, WALK, HURT, DEAD }

@export var SPEED := 400.0
@export var max_health: int = 100
@export var knockback_resistance := 0.2  # Сопротивление отбрасыванию (0-1)
@export_category("Animations")
@export var idle_right_anim : String = "IdleR"
@export var idle_left_anim : String = "IdleL"
@export var walk_right_anim : String = "WalkR"
@export var walk_left_anim : String = "WalkL"
@export var hurt_right_anim : String = "HurtR"
@export var hurt_left_anim : String = "HurtL"
@export var death_anim : String = "Death"  # Анимация смерти

var current_state: PlayerState = PlayerState.IDLE
var is_facing_right = true
var timer_jump = Timer.new()
var hurt_timer: float = 0.0
@onready var weapon_pivot := $WeaponPivot

var current_health: float
var weapons: Array[Weapon] = []
@onready var current_weapon: Weapon = null

# Заклинания и все с ними связанное
enum SpellType { MELEE, RANGED }
var current_spell_type: SpellType = SpellType.MELEE
var current_element: ElementsSystem.ELEMENT = ElementsSystem.ELEMENT.WATER
var current_spell: Spell = null
var current_active_spell: Spell = null  # Текущее активное заклинание в комбо
var in_spell_cooldown := false
var spell_coldown_timer : float = 0.3
var is_spelling := false

# Словарь заклинаний 
var spells_db = {
	#ElementsSystem.ELEMENT.FIRE: {
		#SpellType.MELEE: preload("res://scenes/spells/FireMeleeSpell.tscn"),
		#SpellType.RANGED: preload("res://scenes/spells/FireRangedSpell.tscn")
	#},
	ElementsSystem.ELEMENT.WATER: {
		SpellType.MELEE: preload("res://scenes/spells/WaterMeleeWave.tscn"),
		#SpellType.RANGED: preload("res://scenes/spells/WaterRangedSpell.tscn")
	}
}

func _ready():
	current_health = max_health
	if has_node("PlayerHurtbox"):
		$PlayerHurtbox.body_entered.connect(_on_body_entered_enemy_body)
	change_state(PlayerState.IDLE)
	
	current_spell = preload("res://scenes/based_scenes/Spell.tscn").instantiate()
	add_child(current_spell)
	current_spell.setup(self, current_element)

func _physics_process(delta):
	update_facing_direction()
	handle_movement()
	handle_weapon()
	update_animations()
	
	handle_spells()  # Добавляем обработку заклинаний

func update_facing_direction():
	var mouse_pos = get_global_mouse_position()
	if is_spelling and is_instance_valid(current_active_spell):
		
		is_facing_right = current_active_spell.cur_direction.x > global_position.x
	else:
		is_facing_right = mouse_pos.x > global_position.x

func handle_movement():
	var move_dir = Input.get_vector("left", "right", "up", "down")
	velocity = move_dir * SPEED
	if (is_instance_valid(current_active_spell)):
		velocity += current_active_spell.cur_direction.normalized() * 100
		print(current_active_spell.cur_direction.normalized() * 2)
		pass
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
	current_weapon.update_aim(get_global_mouse_position())
	
	# Стрельба
	if Input.is_action_pressed("attack1"):
		var direction = (get_global_mouse_position() - current_weapon.shoot_point.global_position).normalized()
		current_element = ElemSys.ELEMENT.WATER
		current_weapon.try_shoot(direction, self.position)
	
	# Перезарядка
	if Input.is_action_just_pressed("reload"):
		current_weapon.try_reload()

func handle_spells():
	# Переключение типа заклинания
	#if Input.is_action_just_pressed("switch_spell_type"):
		#current_spell_type = SpellType.RANGED if current_spell_type == SpellType.MELEE else SpellType.MELEE
		#print("Тип заклинания: ", "Дальнее" if current_spell_type == SpellType.RANGED else "Ближнее")
	
	# Переключение стихии
	#if Input.is_action_just_pressed("next_element"):
		#_switch_element(1)
	#elif Input.is_action_just_pressed("prev_element"):
		#_switch_element(-1)
	
	# Каст заклинания               "cast_spell"
	if Input.is_action_just_pressed("attack2"):
		print("Нажатие ПКМ зафиксировано")
		cast_spell()

func _switch_element(direction: int):
	var elements = ElementsSystem.ELEMENT.values()
	var current_idx = elements.find(current_element)
	var new_idx = wrapi(current_idx + direction, 0, elements.size())
	current_element = elements[new_idx]
	
	# Обновляем текущее заклинание
	current_spell.setup(self, current_element)
	print("Стихия изменена на: ", ElementsSystem.element_to_string(current_element))

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
			
	# Откладываем добавление оружия в иерархию
	call_deferred("_deferred_add_weapon", new_weapon)

func _deferred_add_weapon(new_weapon: Weapon):
	# Удаляем из текущего родителя
	if new_weapon.get_parent():
		new_weapon.get_parent().remove_child(new_weapon)
	
	# Добавляем к точке вращения
	weapon_pivot.add_child(new_weapon)
	new_weapon.z_index = 1  # Оружие поверх персонажа
	
	new_weapon.position.x = new_weapon.pivot_offset_x
	new_weapon.position.y = new_weapon.pivot_offset_y
	
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
	
	# Показываем новое
	current_weapon = weapons[index]
	current_weapon.hand_sprite.show()

	# Для правильного порядка отрисовки
	weapon_pivot.move_child(current_weapon, weapon_pivot.get_child_count() - 1)

func cast_spell() -> void:
	is_spelling = true
	if in_spell_cooldown: return
	
	var mouse_pos = get_global_mouse_position()
	if not current_active_spell or not is_instance_valid(current_active_spell):
		# Создаем новое заклинание если нет активного
		var spell_scene = spells_db[current_element][current_spell_type]
		current_active_spell = spell_scene.instantiate()
		get_parent().add_child(current_active_spell)
		current_active_spell.setup(self, current_element)
		current_active_spell.combo_finished.connect(_on_spell_combo_finished)
	
	current_active_spell.start_cast(mouse_pos)
	
	# Короткая анимация каста
	#player_sprite.play("cast_quick")

func _on_spell_combo_finished():
	if current_active_spell:
		current_active_spell.queue_free()
		current_active_spell = null
	
	in_spell_cooldown = true
	await get_tree().create_timer(0.3).timeout
	in_spell_cooldown = false
	is_spelling = false

func take_damage(
	amount: float, 
	attacker_pos: Vector2, 
	attacker_kb_force: float, 
	damage_element: ElemSys.ELEMENT = ElemSys.ELEMENT.NONE
	):
	if current_state == PlayerState.DEAD or current_state == PlayerState.HURT:
		return
	
	# Рассчитываем множитель урона в зависимости от элементов
	var damage_multiplier = _get_elemental_damage_multiplier(damage_element)
	var final_damage = amount * damage_multiplier
	
	current_health -= final_damage
	_play_hit_effect()
	_knockback(attacker_pos, attacker_kb_force)
	
	if current_health <= 0:
		change_state(PlayerState.DEAD)
		die()
	else:
		change_state(PlayerState.HURT)

func _get_elemental_damage_multiplier(damage_element: ElemSys.ELEMENT) -> float:
	return 1.0 # Пока без множителя, но вдруг понадобится

func _play_hit_effect() -> void:
	# Можно добавить particles или tween эффект
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func _knockback(source_position: Vector2, source_knockback_force: float) -> void:
	var direction = (global_position - source_position).normalized()
	var knockback_force = direction * source_knockback_force * knockback_resistance
	velocity = knockback_force
	move_and_slide()

func die():
	# Логика смерти
	queue_free()

func _on_body_entered_enemy_body(body: Node2D) -> void:
	if not (body is Unit):
		return
	if body.is_in_group("hazards"):
		# Получаем компонент урона от объекта
		if body.has_method("get_body_damage"):
			take_damage(body.get_body_damage(), body.global_position, 1.0, ElemSys.ELEMENT.NONE)
			print(current_health)
		else:
			take_damage(15, body.global_position, 1.0, ElemSys.ELEMENT.NONE)
			print(current_health)

func play_anim(anim_name: String):
	if (player_sprite.sprite_frames.has_animation(anim_name)): # Чтобы игра не упала, если не найдет анимацию
		player_sprite.play(anim_name)
