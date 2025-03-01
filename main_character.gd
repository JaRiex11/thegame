extends CharacterBody2D

const SPEED = 300.0

@export var bullet_scene = preload("res://Bullet.tscn")

func _physics_process(delta):
	var mouse_position = get_global_mouse_position()
	var direction = (mouse_position - global_position).normalized()
	var angle = direction.angle()
	
	var move_direction = Input.get_vector("left", "right", "up", "down")
	velocity = move_direction * SPEED
	
	rotation = angle
	if Input.is_action_just_pressed("attack1"):
		shoot()
	move_and_slide()
	

func shoot():
	var bullet = bullet_scene.instantiate()
	bullet.direction = Vector2.RIGHT.rotated(rotation)
	bullet.position = position + bullet.direction * 20  # Позиция пули перед персонажем
	get_parent().add_child(bullet)
