extends ProgressBar

var max_mp := 20
var cur_mp: int

var cur_mana_amount: int # 5, 4, 3, 2, 1, 0
var last_mana_hits_cnt: int # 0, 1, 2, 3

var anim_prefix: String
var anim_postfix: String

var check_spell_ability_timer := 0.2

@onready var mana_bar_sprite : AnimatedSprite2D = $mana_bar

signal mana_on_zero
signal spell_ability(can_spell: bool)

func _ready() -> void:
	cur_mana_amount = 5
	last_mana_hits_cnt = 0
	cur_mp = max_mp
	value = cur_mp
	update_anim_name()
	update_animations()

func _process(delta: float) -> void:
	value = cur_mp
	check_spell_ability_timer -= delta
	if (check_spell_ability_timer < 0):
		check_ability_to_spell()

func change_mana_down():
	cur_mp -= 1
	last_mana_hits_cnt += 1
	
	if (last_mana_hits_cnt > 3):
		cur_mana_amount -= 1
		last_mana_hits_cnt = 0
	
	update_anim_name()
	update_animations()

func check_ability_to_spell():
	if (cur_mp > 0):
		emit_signal("spell_ability", true)
		return true
	else:
		emit_signal("spell_ability", false)
		return false

func update_animations() -> void:	
	#match value:
		#20: hp_bar_sprite.play("FiveFull")
		#19: hp_bar_sprite.play("FiveWithout1")
		#18: hp_bar_sprite.play("FiveWithout2")
		#17: hp_bar_sprite.play("FiveWithout3")
		#16: hp_bar_sprite.play("FourFull")
		#15: hp_bar_sprite.play("FourWithout1")
		#14: hp_bar_sprite.play("FourWithout2")
		#13: hp_bar_sprite.play("FourWithout3")
		#12: hp_bar_sprite.play("ThreeFull")
		#11: hp_bar_sprite.play("ThreeWithout1")
		#10: hp_bar_sprite.play("ThreeWithout2")
		#9: hp_bar_sprite.play("ThreeWithout3")
		#8: hp_bar_sprite.play("TwoFull")
		#7: hp_bar_sprite.play("TwoWithout1")
		#6: hp_bar_sprite.play("TwoWithout2")
		#5: hp_bar_sprite.play("TwoWithout3")
		#4: hp_bar_sprite.play("OneFull")
		#3: hp_bar_sprite.play("OneWithout1")
		#2: hp_bar_sprite.play("OneWithout2")
		#1: hp_bar_sprite.play("OneWithout3")
		#0: hp_bar_sprite.play("Zero")
	var animation = anim_prefix + anim_postfix
	if mana_bar_sprite.sprite_frames.has_animation(animation):
		mana_bar_sprite.play(animation)

func update_anim_name():
	match cur_mana_amount:
		5: anim_prefix = "Five"
		4: anim_prefix = "Four"
		3: anim_prefix = "Three"
		2: anim_prefix = "Two"
		1: anim_prefix = "One"
		0: 
			anim_prefix = "Zero"
			anim_postfix = ""
			emit_signal("mana_on_zero")
			return
	
	match last_mana_hits_cnt:
		0: anim_postfix = "Full"
		1: anim_postfix = "Without1"
		2: anim_postfix = "Without2"
		3: anim_postfix = "Without3"
