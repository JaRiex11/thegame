extends Node2D
class_name Spell

# Настройки)
@export var combo_animations : Array[String] = ["attack1", "attack2", "attack3"]
@export var damage_per_combo := [10.0, 15.0, 20.0]
@export var cast_point_offset := Vector2(15, -10)  # Смещение от персонажа
@export var hand_length := 30.0                    # Длина "руки" для эффекта
@export var combo_timeout := 0.5                   # Время между ударами комбо
@export var combo_timer := 1.0
@export var can_move_during_cast := true           # Разрешить движение при касте
# Ссылки на узлы
@onready var hand_pivot = $HandPivot
@onready var hand_sprite = $HandPivot/HandSprite
@onready var spell_effect = $HandPivot/SpellEffect
@onready var hitbox = $HandPivot/Hitbox
# Состояние
var caster: Node2D
var current_element: ElementsSystem.ELEMENT
var combo_count := 0
var is_casting := false
var animation_queue: Array[String] = []
var current_animation_playing := false
# Сигналы
signal combo_finished

func _physics_process(delta: float) -> void:
	position = caster.position + cast_point_offset

func setup(caster_node: Node2D, element: ElementsSystem.ELEMENT) -> void:
	caster = caster_node
	current_element = element
	position = caster.position + cast_point_offset

func update_aim(mouse_pos: Vector2) -> void:
	var direction = (mouse_pos - global_position).normalized()
	rotation = direction.angle()  # Поворот всей сцены к мышке
	spell_effect.position = Vector2(hand_length, 0)
	hitbox.position = spell_effect.position

func start_cast(mouse_pos: Vector2) -> void:
	print("in start cast")
	if not is_casting:
		# Начало нового комбо
		print("is first time")
		show()
		is_casting = true
		combo_count = 0
		update_aim(mouse_pos)
	
	_add_to_combo(mouse_pos)
	print("not first time")

func _add_to_combo(mouse_pos: Vector2) -> void:
	if combo_count >= combo_animations.size():
		return
	
	combo_count += 1
	combo_timer = combo_timeout
	
	# Добавляем анимацию в очередь
	animation_queue.append(combo_animations[combo_count - 1])
	_process_animation_queue()
	
	update_aim(mouse_pos)

func _process_animation_queue() -> void:
	if current_animation_playing or animation_queue.is_empty():
		return
	
	current_animation_playing = true
	var anim_name = animation_queue.pop_front()
	
	hand_sprite.play("Hand")
	spell_effect.play(anim_name)
	_setup_hitbox(combo_count)
	
	await spell_effect.animation_finished
	current_animation_playing = false
	
	# Проверяем нужно ли продолжить
	if not animation_queue.is_empty():
		_process_animation_queue()
	elif combo_timer <= 0:
		finish_combo()

func _setup_hitbox(combo_level: int) -> void:
	# Настройка хитбокса в зависимости от комбо
	var damage = damage_per_combo[combo_level - 1]
	hitbox.damage = damage
	hitbox.element = current_element
	
	# Позиционируем хитбокс в направлении атаки
	#hitbox.position = direction * 30
	#hitbox.rotation = direction.angle()

func finish_combo() -> void:
	if not is_casting:
		return
	
	is_casting = false
	combo_count = 0
	animation_queue.clear()
	hide()
	emit_signal("combo_finished")

func _process(delta: float) -> void:
	if is_casting:
		combo_timer -= delta
		if combo_timer <= 0 and not current_animation_playing:
			finish_combo()
