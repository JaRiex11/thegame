extends Node2D

# Характеристики оружия
@export var player_sprite_texture: Texture2D
@export var gamer_path: String = "res://main_character.gd"
@export var weapon_name: String = "Pistol"
@export var damage: int = 10
@export var fire_rate: float = 0.5
@export var magazine_size: int = 10
@export var max_ammo: int = 50
@export var bullet_speed: float = 700
@export var bullet_scene: PackedScene
@export var sprite_offset = Vector2(0, 0)

var current_ammo: int
var total_ammo: int
var can_shoot: bool = true
var is_reloading: bool = false

# Спрайты и позиции
@onready var ground_sprite = $OnGroundSprite
@onready var hand_sprite = $InHandSprite
@onready var shoot_point = $ShootPoint

func _ready():
	current_ammo = magazine_size
	total_ammo = max_ammo - magazine_size
	hand_sprite.hide()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.pick_up_weapon(self)
		ground_sprite.hide()
		#queue_free()

func shoot(direction: Vector2):
	print("shooting 2!!!")
	if can_shoot and current_ammo > 0 and not is_reloading:
		var bullet = bullet_scene.instantiate()
		bullet.direction = direction
		bullet.position = shoot_point.global_position
		bullet.rotation = direction.angle()
		bullet.speed = bullet_speed
		bullet.damage = damage
		get_tree().current_scene.add_child(bullet)
		
		current_ammo -= 1
		can_shoot = false
		await get_tree().create_timer(fire_rate).timeout
		can_shoot = true
		print("current_ammo: ", current_ammo)

func reload():
	print("start reloading")
	if total_ammo <= 0 or is_reloading: 
		return
		
	is_reloading = true
	# Здесь будет анимация перезарядки
	await get_tree().create_timer(1.5).timeout
	
	var needed = magazine_size - current_ammo
	if total_ammo >= needed:
		current_ammo += needed
		total_ammo -= needed
	else:
		current_ammo += total_ammo
		total_ammo = 0
		
	is_reloading = false
	print("finish reloading")

func update_ammo(new_ammo: int):
	total_ammo += new_ammo
	total_ammo = min(total_ammo, max_ammo)
