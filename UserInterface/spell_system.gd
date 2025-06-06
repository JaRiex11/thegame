extends Control

@onready var elem_icon = $ElementIcon

var cur_elem : String

func _ready() -> void:
	cur_elem = "Water"
	elem_icon.play(cur_elem)

func change_element(elem: String):
	print("Popali v gsdgsdg")
	match elem:
		"Fire", "fire", "FIRE":
			switch_icon_to_fire()
		"Water", "water", "WATER":
			switch_icon_to_water()

func switch_icon_to_fire():
	cur_elem = "Fire"
	elem_icon.play(cur_elem)
	

func switch_icon_to_water():
	cur_elem = "Water"
	elem_icon.play(cur_elem)
