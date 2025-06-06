extends Control

@onready var text_label := $Label

func update_ammo(current: int, magazine_size: int, total: int):
	text_label.text = "Обойма: %d/%d\nВ запасе: %d" % [current, magazine_size, total]
