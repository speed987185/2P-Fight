extends Control

class_name MainMenu

@onready var vbox_container: VBoxContainer = $VBoxContainer
@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

@onready var arena_chooser: VBoxContainer = $ArenaChooser
@onready var arena1_button: Button = $ArenaChooser/Arena1Button
@onready var arena2_button: Button = $ArenaChooser/Arena2Button
@onready var back_button: Button = $ArenaChooser/BackButton

var menu_bg_music: AudioStreamPlayer
var vbox_center: Vector2
var arena_chooser_right: Vector2

func _ready() -> void:


	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	var settings_btn = Button.new()
	settings_btn.text = "Settings"
	
	settings_btn.custom_minimum_size = Vector2(200, 60)
	settings_btn.add_theme_color_override("font_color", Color(0.000002, 0, 0.666229, 1))
	settings_btn.add_theme_font_size_override("font_size", 35)

	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(1, 1, 1, 1)
	sb_normal.border_width_left = 2
	sb_normal.border_width_top = 2
	sb_normal.border_width_right = 2
	sb_normal.border_width_bottom = 2
	sb_normal.border_color = Color(0, 0, 0, 1)
	settings_btn.add_theme_stylebox_override("normal", sb_normal)

	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.165625, 0.000008, 0.705698, 1)
	sb_hover.border_width_left = 2
	sb_hover.border_width_top = 2
	sb_hover.border_width_right = 2
	sb_hover.border_width_bottom = 2
	sb_hover.border_color = Color(0, 0, 0, 1)
	settings_btn.add_theme_stylebox_override("hover", sb_hover)
	
	vbox_container.add_child(settings_btn)
	vbox_container.move_child(settings_btn, 1)
	settings_btn.pressed.connect(_on_settings_pressed)

	var multi_btn = Button.new()
	multi_btn.text = "Multiplayer"
	multi_btn.custom_minimum_size = Vector2(200, 60)
	multi_btn.add_theme_color_override("font_color", Color(0.000002, 0, 0.666229, 1))
	multi_btn.add_theme_font_size_override("font_size", 35)
	multi_btn.add_theme_stylebox_override("normal", sb_normal)
	multi_btn.add_theme_stylebox_override("hover", sb_hover)
	vbox_container.add_child(multi_btn)
	vbox_container.move_child(multi_btn, 2)
	multi_btn.pressed.connect(_on_multiplayer_pressed)

	var sm = preload("res://Scenes/settings_menu.tscn").instantiate()
	sm.hide()
	sm.name = "SettingsMenu"
	add_child(sm)
	
	arena1_button.pressed.connect(_on_arena1_pressed)
	arena2_button.pressed.connect(_on_arena2_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Store positions for animations
	vbox_center = vbox_container.position
	arena_chooser_right = arena_chooser.position
	
	
	# Menu BGM is now handled by BGMManager autoload

func _play_click() -> void:
	var click_sfx: AudioStreamPlayer = AudioStreamPlayer.new()
	click_sfx.stream = preload("res://assets/Sfx/button click.mp3")
	click_sfx.bus = "SFX"
	add_child(click_sfx)
	click_sfx.play()
	click_sfx.finished.connect(click_sfx.queue_free)

func _on_play_pressed() -> void:
	_play_click()
	var gm: GameManager = GameManager.instance
	if gm != null:
		gm.is_multiplayer_session = false
	# Slide out main menu and slide in arena chooser
	SceneTransition.change_scene("res://Scenes/skin_menu.tscn")

func _on_settings_pressed() -> void:
	_play_click()
	$SettingsMenu.show()

func _on_multiplayer_pressed() -> void:
	_play_click()
	get_tree().change_scene_to_file("res://Scenes/multiplayer_menu.tscn")

func _on_back_pressed() -> void:
	_play_click()
	# Revert animation
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(vbox_container, "position:x", vbox_center.x, 0.5)
	tween.tween_property(arena_chooser, "position:x", arena_chooser_right.x, 0.5)

func _on_arena1_pressed() -> void:
	_play_click()
	get_tree().paused = false
	var gm: GameManager = GameManager.instance
	if gm != null:
		gm.is_multiplayer_session = false
		gm.selected_arena = "res://Scenes/game.tscn"
	SceneTransition.change_scene("res://Scenes/skin_menu.tscn")

func _on_arena2_pressed() -> void:
	_play_click()
	get_tree().paused = false
	var gm: GameManager = GameManager.instance
	if gm != null:
		gm.is_multiplayer_session = false
		gm.selected_arena = "res://Scenes/game2.tscn"
	SceneTransition.change_scene("res://Scenes/skin_menu.tscn")

func _on_quit_pressed() -> void:
	_play_click()
	get_tree().quit()
