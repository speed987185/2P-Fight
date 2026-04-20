extends Node2D

class_name GameController

var pause_menu_scene: PackedScene = preload("res://Scenes/pause_menu.tscn")
var winner_menu_scene: PackedScene = preload("res://Scenes/winner_menu.tscn")

func _ready() -> void:
	_ensure_game_manager()
	var gm: GameManager = GameManager.instance
	if gm != null:
		gm.reset_game_state()
	_ensure_menu(pause_menu_scene, "PauseMenu")
	_ensure_menu(winner_menu_scene, "WinnerMenu")

func _ensure_game_manager() -> void:
	if GameManager.instance == null:
		var gm: GameManager = GameManager.new()
		get_tree().root.add_child(gm)
		return
	
	if not GameManager.instance.is_inside_tree():
		get_tree().root.add_child(GameManager.instance)

func _ensure_menu(packed_scene: PackedScene, node_name: String) -> void:
	if has_node(node_name):
		return
	var menu: Node = packed_scene.instantiate()
	add_child(menu)
