extends Elemental
class_name WaterElemental

func _ready():
	super._ready()
	is_elemental = true
	current_element = ElemSys.ELEMENT.WATER
