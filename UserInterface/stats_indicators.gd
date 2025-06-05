extends CanvasLayer

signal on_change_hp_down
signal players_hp_is_zero
signal player_need_to_be_invincible
signal player_is_not_invincible
signal spend_mana

func _on_player_hurt_box_body_entered(body: Node2D) -> void:
	emit_signal("on_change_hp_down")

func _on_player_hp_bar_on_hp_is_zero(bool: Variant) -> void:
	emit_signal("players_hp_is_zero")

func _on_player_hp_bar_get_damage(is_vulnerable: Variant) -> void:
	if is_vulnerable:
		emit_signal("player_need_to_be_invincible")
	else:
		emit_signal("player_is_not_invincible")


func _on_main_character_on_cast_spell() -> void:
	emit_signal("spend_mana")
	pass # Replace with function body.
