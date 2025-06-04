extends ElemMediumAI
class_name FireElemental

func _ready():
	super._ready()
	is_elemental = true
	current_element = ElemSys.ELEMENT.FIRE
