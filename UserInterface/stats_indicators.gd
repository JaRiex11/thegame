extends CanvasLayer

signal on_change_hp_down
signal players_hp_is_zero
signal player_need_to_be_invincible
signal player_is_not_invincible
signal spend_mana
signal spell_ability(flag: bool)
signal need_to_restore_shield
signal is_shields_needed(body)
signal die_shield_item(body)
signal change_element(elem: String)

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

func _on_player_mana_bar_spell_ability(can_spell: bool) -> void:
	if can_spell:
		emit_signal("spell_ability", true)
	else:
		emit_signal("spell_ability", false)
		


func _on_main_character_need_to_restore_shield() -> void:
	emit_signal("need_to_restore_shield")


func _on_main_character_is_shields_needed(body: Variant) -> void:
	emit_signal("is_shields_needed", body)


func _on_player_shield_bar_die_shield_item(body) -> void:
	emit_signal("die_shield_item", body)


func _on_main_character_change_element(element: String) -> void:
	emit_signal("change_element", element)
