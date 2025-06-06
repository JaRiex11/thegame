extends Node2D

@onready var player := $"../MainCharacter"

signal need_to_restore_shield
signal is_shields_needed(body)

func _ready() -> void:
	need_to_restore_shield.connect(player.restore_shield)
	is_shields_needed.connect(player.check_shields)
	player.die_shield_item.connect(die)

func _on_area_2d_body_entered(body: Node2D) -> void:
	emit_signal("is_shields_needed", self)
	#call_deferred("die")

func die(body):
	if body != self: return
	emit_signal("need_to_restore_shield")
	queue_free()
