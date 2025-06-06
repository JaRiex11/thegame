extends ProgressBar

var max_hp := 20
var cur_hp: int

var cur_heart_amount: int # 5, 4, 3, 2, 1, 0
var last_heart_hits_cnt: int # 0, 1, 2, 3

var anim_prefix: String
var anim_postfix: String

var is_breaking = false
var is_waving = false
var is_animating = false

var hp_regen_duration : float = 3.0
var regen_hp_timer := hp_regen_duration

@onready var hp_bar_sprite : AnimatedSprite2D = $"../hp_bar"
@onready var shield_bar := $"../../DefendSystem/PlayerShieldBar"

signal on_hp_is_zero
signal get_damage(is_vulnerable)  # true - можно получать урон, false - неуязвим
signal animation_event(event_type)  # Универсальный сигнал для событий анимации
signal animation_completed
signal need_to_break_shield

func _ready() -> void:
	cur_heart_amount = 5
	last_heart_hits_cnt = 0
	cur_hp = max_hp
	value = cur_hp
	update_anim_name()
	update_animations()

func _process(delta: float) -> void:
	value = cur_hp
	regen_hp_timer -= delta
	if (regen_hp_timer < 0):
		regen_hp_timer = hp_regen_duration
		change_health_up()

func update_animations() -> void:	
	var animation = anim_prefix + anim_postfix
	if hp_bar_sprite.sprite_frames.has_animation(animation):
		hp_bar_sprite.play(animation)

func change_health_up():
	if is_animating or cur_hp >= max_hp:
		return
	cur_hp += 1
	last_heart_hits_cnt -= 1
	if (last_heart_hits_cnt < 0):
		play_wave_animation()
		cur_heart_amount += 1
		if (cur_heart_amount < 6):
			cur_heart_amount = 5
			last_heart_hits_cnt = 3
		else :
			last_heart_hits_cnt = 0
	
	update_anim_name()
	update_animations()

func change_health_down():
	if shield_bar.has_shields():
		emit_signal("need_to_break_shield")
		emit_signal("get_damage", true)
		await get_tree().create_timer(1.0).timeout
		emit_signal("get_damage", false)
		return
	if is_animating:
		return
	
	is_animating = true
	emit_signal("get_damage", true)  # Становимся неуязвимыми
	
	if (cur_heart_amount > 1):
		await play_wave_animation()
	
	cur_hp -= 1
	last_heart_hits_cnt += 1
	
	if (last_heart_hits_cnt > 3):
		await play_break_anim()
		cur_heart_amount -= 1
		last_heart_hits_cnt = 0

	update_anim_name()
	update_animations()
	is_animating = false
	emit_signal("get_damage", false)  # Снова становимся уязвимыми

func update_anim_name():
	match cur_heart_amount:
		5: anim_prefix = "Five"
		4: anim_prefix = "Four"
		3: anim_prefix = "Three"
		2: anim_prefix = "Two"
		1: anim_prefix = "One"
		0: 
			anim_prefix = "Zero"
			anim_postfix = ""
			emit_signal("on_hp_is_zero", true)
			return
	
	match last_heart_hits_cnt:
		0: anim_postfix = "Full"
		1: anim_postfix = "Without1"
		2: anim_postfix = "Without2"
		3: anim_postfix = "Without3"

func play_wave_animation():
	# Отправляем событие начала анимации
	emit_signal("animation_event", "wave_start")
	
	var anim_name = anim_prefix + "Wave"
	if hp_bar_sprite.sprite_frames.has_animation(anim_name):
		hp_bar_sprite.play(anim_name)
		await self.animation_completed  # Ждем сигнала о завершении
	
	# Отправляем событие завершения анимации
	emit_signal("animation_event", "wave_end")

func play_break_anim():
	# Отправляем событие начала анимации
	emit_signal("animation_event", "break_start")
	
	var anim_name = anim_prefix + "Break"
	if hp_bar_sprite.sprite_frames.has_animation(anim_name):
		hp_bar_sprite.play(anim_name)
		await self.animation_completed  # Ждем сигнала о завершении
	
	# Отправляем событие завершения анимации
	emit_signal("animation_event", "break_end")

func _on_hp_bar_animation_finished() -> void:
	print("animation is finished")
	emit_signal("animation_completed")
