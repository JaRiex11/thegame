extends Node2D

@onready var pause_menu = $PauseMenu

func _physics_process(delta):
	if Input.is_action_just_pressed("esc"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		pause_menu.hide()
		get_tree().paused = false
	else:
		pause_menu.show()
		get_tree().paused = true
