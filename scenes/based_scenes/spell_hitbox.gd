extends Area2D
class_name SpellHitbox

@export var damage := 10.0
@export var element: ElementsSystem.ELEMENT = ElementsSystem.ELEMENT.NONE

func _ready() -> void:
	monitorable = false
	monitoring = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(
			damage,
			global_position,
			50.0,  # knockback_force
			element
		)
