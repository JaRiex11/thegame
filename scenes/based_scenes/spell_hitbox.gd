extends Area2D
class_name SpellHitbox

var damage := 10.0
var element: ElemSys.ELEMENT = ElemSys.ELEMENT.NONE
var knockback_force := 50

func setup(_damage: float, _kb_force: float, _element: ElemSys.ELEMENT):
	damage = _damage
	element = _element
	knockback_force = _kb_force

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		print("Задели врага!!!")
		body.take_damage(
			damage,
			global_position,
			50.0,  # knockback_force
			element
		)
