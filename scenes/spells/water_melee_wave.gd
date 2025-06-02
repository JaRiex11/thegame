extends Spell
class_name WaterMeleeWave

func _ready() -> void:
	super._ready()
	element = ElementsSystem.ELEMENT.WATER
	is_ranged = false

func _start_melee_effect() -> void:
	# Анимация волны перед персонажем
	
	var anim_name = [quick_anim, medium_anim, charged_anim][charge_level]
	play_anim(quick_anim)

func _on_animation_finished() -> void:
	if animated_sprite.animation == "impact":
		queue_free()
	else:
		super._on_animation_finished()
