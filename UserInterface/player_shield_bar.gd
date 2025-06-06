extends ProgressBar

var cur_shields_amount: int # 5, 4, 3, 2, 1
@onready var sheilds_sprite := $"../shield_bar"
@onready var shield_icon := $"../Shield"
signal die_shield_item(body)

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
	if (cur_shields_amount > 0):
		shield_icon.show()
		sheilds_sprite.show()
	else:
		shield_icon.hide()
	
	match cur_shields_amount:
		5: sheilds_sprite.play("Five")
		4: sheilds_sprite.play("Four")
		3: sheilds_sprite.play("Three")
		2: sheilds_sprite.play("Two")
		1: sheilds_sprite.play("One")
		0: sheilds_sprite.hide()

func restore_shield():
	if(cur_shields_amount >= 5): return
	if(cur_shields_amount < 0): cur_shields_amount = 0
	cur_shields_amount += 1
	update_animations()
	pass

func break_shield():
	if(cur_shields_amount <= 0): return
	cur_shields_amount -= 1
	update_animations()


func _on_stats_indicators_is_shields_needed(body) -> void:
	if (cur_shields_amount < 5):
		emit_signal("die_shield_item", body)
		
