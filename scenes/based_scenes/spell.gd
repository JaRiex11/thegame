extends Node2D
class_name Spell

# Базовые параметры
@export var base_damage := 10.0
@export var base_knockback := 50.0
@export var element: ElementsSystem.ELEMENT = ElementsSystem.ELEMENT.NONE
@export var is_ranged := false  # True для дальних, False для ближних заклинаний
@export var cast_time := 0.5  # Время анимации каста
@export_category("Animations")
@export var quick_cast_anim : String = "quick_cast"
@export var medium_cast_anim : String = "medium_cast"
@export var charged_cast_anim : String = "charged_cast"
@export var quick_anim : String = "quick"
@export var medium_anim : String = "medium"
@export var charged_anim : String = "charged"

# Компоненты
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D

# Внутренние переменные
var charge_level: int = 0  # 0 - quick, 1 - medium, 2 - charged
var caster: Node2D = null
var damage_multipliers := [0.8, 1.0, 1.5]
#var size_multipliers := [0.7, 1.0, 1.3]

func _ready() -> void:
	# Настройка параметров
	#var scale_mult = size_multipliers[charge_level]
	#scale = Vector2(scale_mult, scale_mult)
	
	# Подписка на события
	animated_sprite.animation_finished.connect(_on_animation_finished)
	hitbox.body_entered.connect(_on_body_entered)
	
	# Запуск анимации
	_start_cast()

func _physics_process(delta: float) -> void:
	global_position = caster.global_position + Vector2(20, 0)

func setup(caster_ref: Node2D, charge: int) -> void:
	caster = caster_ref
	charge_level = clamp(charge, 0, 2)
	global_position = caster.global_position
	
	if is_ranged:
		# Для дальних заклинаний - направление в сторону взгляда
		if caster.is_facing_right:
			position += Vector2(30, 0)
		else:
			position += Vector2(-30, 0)
			scale.x *= -1  # Отражаем спрайт

func _start_cast() -> void:
	var anim_name = [quick_cast_anim, medium_cast_anim, charged_cast_anim][charge_level]
	play_anim(anim_name)
	
	# Активируем хитбокс только после анимации каста
	collision_shape.set_deferred("disabled", true)

func _on_animation_finished() -> void:
	print("popali pered super if")
	if animated_sprite.animation.ends_with("cast"): # Проверяем, на что оканчивается название анимации
		# Завершение каста - активируем эффект
		# Тут можно санимировать какой то начальный эффект видимо
		collision_shape.set_deferred("disabled", false)
		print("popali pered if")
		if is_ranged:
			print("popali v if")
			_start_ranged_effect()
		else:
			_start_melee_effect()
	else:
		queue_free()

func _start_ranged_effect() -> void:# Логика для дальних заклинаний
	pass

func _start_melee_effect() -> void:# Логика для ближних заклинаний
	pass

func _on_body_entered(body: Node) -> void:
	if body == caster or not body.has_method("take_damage"):
		return
	
	var damage = base_damage * damage_multipliers[charge_level]
	body.take_damage(
		damage,
		global_position,
		base_knockback, #* size_multipliers[charge_level],
		element
	)
	
	if not is_ranged: # Здесь можно сыграть анимацию удара (типо)
		#animated_sprite.play("impact")
		pass
	else:
		_ranged_impact(body)

func _ranged_impact(body: Node) -> void:
	# Логика попадания дальнего заклинания
	# animated_sprite.play("impact")
	set_physics_process(false)

func _process(delta: float) -> void:
	if is_ranged and animated_sprite.animation == "active":
		# Движение дальнего заклинания
		position += Vector2.RIGHT.rotated(rotation) * 300 * delta
	
func play_anim(anim_name: String):
	if (animated_sprite.sprite_frames.has_animation(anim_name)): # Чтобы игра не упала, если не найдет анимацию
		animated_sprite.play(anim_name)
		print("Сыграна анимация ", anim_name)
	else:
		print("Анимации ", anim_name, " нет в Spell")
