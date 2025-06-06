extends ElemSmallAI
class_name ElemFireSmall

func _ready() -> void:
	super._ready()
	current_element = ElemSys.ELEMENT.FIRE
	current_health = 300

func die() -> void:
	if is_instance_valid(get_tree()):
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
	else:
		push_error("Scene tree is invalid!")
