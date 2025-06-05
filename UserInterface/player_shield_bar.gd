extends ProgressBar

var cur_shields_amount: int # 5, 4, 3, 2, 1
@onready var sheilds_sprite := $shield_bar

func _ready() -> void:
	cur_shields_amount = 5
	value = cur_shields_amount
	update_animations()

func _process(delta: float) -> void:
	value = cur_shields_amount

func has_shields():
	if cur_shields_amount <= 0:
		return false
	else:
		return true

func update_animations():
	match cur_shields_amount:
		5: sheilds_sprite.play("Five")
		4: sheilds_sprite.play("Four")
		3: sheilds_sprite.play("Three")
		2: sheilds_sprite.play("Two")
		1: sheilds_sprite.play("One")
		_: sheilds_sprite.play("Zero")

func break_shield():
	cur_shields_amount -= 1
	update_animations()
	print("minus 1 shield")
