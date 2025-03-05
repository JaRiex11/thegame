extends CanvasLayer

@onready var resume_button = $Panel/ResumeButton
@onready var main_menu_button = $Panel/MainMenuButton

func _ready():
	process_mode = PROCESS_MODE_ALWAYS

func _on_resume_button_pressed():
	print("Кнопка Resume нажата")
	hide()
	get_tree().paused = false

func _on_main_menu_button_pressed():
	print("Кнопка Main Menu нажата")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
