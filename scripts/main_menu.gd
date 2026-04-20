extends Control

class_name MainMenu

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var arena2_button: Button = $VBoxContainer/Arena2Button
@onready var skins_button: Button = $VBoxContainer/SkinsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	arena2_button.pressed.connect(_on_arena2_pressed)
	skins_button.pressed.connect(_on_skins_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_arena2_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/game2.tscn")

func _on_skins_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/skin_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
