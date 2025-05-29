extends CharacterBody2D

@export var health = 100

const SPEED = 100.0

func _physics_process(delta: float) -> void:
	pass

func take_damage(damage):
	health -= damage
	if health <= 0:
		die()

func die():
	queue_free()
