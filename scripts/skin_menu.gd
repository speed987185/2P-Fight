extends Control

class_name SkinMenu

@onready var p1_skin_container: HBoxContainer = $VBoxContainer/Player1Skins
@onready var p2_skin_container: HBoxContainer = $VBoxContainer/Player2Skins
@onready var back_button: Button = $VBoxContainer/BackButton

var game_manager: GameManager
var skin_colors: Array[Color] = [
	Color.RED,
	Color.BLUE,
	Color.GREEN,
	Color.YELLOW,
	Color.ORANGE,
	Color.PURPLE,
	Color.CYAN,
	Color.WHITE
]

func _ready() -> void:
	_ensure_game_manager()

	_create_skin_buttons(p1_skin_container, 1)
	_create_skin_buttons(p2_skin_container, 2)

	back_button.pressed.connect(_on_back_pressed)

func _ensure_game_manager() -> void:
	if GameManager.instance == null:
		var gm: GameManager = GameManager.new()
		get_tree().root.add_child(gm)
	elif not GameManager.instance.is_inside_tree():
		get_tree().root.add_child(GameManager.instance)

	game_manager = GameManager.instance

func _create_skin_buttons(container: HBoxContainer, player_num: int) -> void:
	for color: Color in skin_colors:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(50, 50)
		button.modulate = color
		button.pressed.connect(_on_skin_selected.bindv([player_num, color]))
		container.add_child(button)

func _on_skin_selected(player_num: int, color: Color) -> void:
	game_manager.set_player_skin(player_num, color)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
