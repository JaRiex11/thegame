extends Button

@export var scene_path: String = "res://floors/floor1.tscn"#"res://scenes/Test.tscn"

func _ready() -> void:
	pressed.connect(_on_button_pressed)

func _on_button_pressed():
	get_tree().change_scene_to_file(scene_path)
