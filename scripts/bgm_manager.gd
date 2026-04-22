extends Node

class_name BGMManager

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var mute_button: Button = $CanvasLayer/MuteButton

var music_bus_idx: int
var last_scene_name: String = ""

func _ready() -> void:
	music_bus_idx = AudioServer.get_bus_index("Music")
	if music_bus_idx == -1:
		music_bus_idx = 0
		
	music_player.stream = preload("res://assets/Sfx/main_menu_bg.mp3")
	music_player.volume_db = -6.0
	music_player.bus = "Music"
	music_player.play()
	
	mute_button.pressed.connect(_on_mute_pressed)
	_update_mute_text()

func _process(_delta: float) -> void:
	var current = get_tree().current_scene
	if not current: return
	
	if current.name != last_scene_name:
		last_scene_name = current.name
		_check_scene(current)

func _check_scene(current_scene: Node) -> void:
	var scene_name = current_scene.name.to_lower()
	var filename = current_scene.scene_file_path.to_lower()
	
	var is_game = false
	if "game" in scene_name or "game" in filename:
		if not "menu" in filename and not "manager" in filename:
			is_game = true
			
	if is_game:
		if music_player.playing:
			music_player.stop()
		$CanvasLayer.hide()
	else:
		if not music_player.playing:
			music_player.play()
		$CanvasLayer.show()

func _on_mute_pressed() -> void:
	var is_muted = AudioServer.is_bus_mute(music_bus_idx)
	AudioServer.set_bus_mute(music_bus_idx, not is_muted)
	_update_mute_text()

func _update_mute_text() -> void:
	var is_muted = AudioServer.is_bus_mute(music_bus_idx)
	if is_muted:
		mute_button.text = "🔇"
	else:
		mute_button.text = "🔊"
