extends CharacterBody2D

@export var health = 100

const SPEED = 100.0

func _physics_process(delta: float) -> void:
	pass

func take_damage(damage, owner, kb_force, dmg_elem):
	print("Манекен:\n",
		"DamageElement: ", ElemSys.element_to_string(dmg_elem)
	)
	#health -= damage
	_play_hit_effect()
	if health <= 0:
		die()

func _play_hit_effect() -> void:
	# Можно добавить particles или tween эффект
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func die():
	queue_free()
