extends Control

class_name ArenaMenu

@onready var arena1_btn: Button = $Arena1
@onready var arena2_btn: Button = $Arena2
@onready var back_btn: Button = $BackButton

func _ready() -> void:
	arena1_btn.pressed.connect(_on_arena1_pressed)
	arena2_btn.pressed.connect(_on_arena2_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not multiplayer.is_server():
			arena1_btn.disabled = true
			arena2_btn.disabled = true
	
	_add_hover_effect(arena1_btn)
	_add_hover_effect(arena2_btn)

func _add_hover_effect(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(func():
		var tween: Tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15)
	)
	btn.mouse_exited.connect(func():
		var tween: Tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
	)

func _play_click() -> void:
	var click_sfx: AudioStreamPlayer = AudioStreamPlayer.new()
	click_sfx.stream = preload("res://assets/Sfx/button click.mp3")
	click_sfx.bus = "SFX"
	add_child(click_sfx)
	click_sfx.play()
	click_sfx.finished.connect(click_sfx.queue_free)

func _on_arena1_pressed() -> void:
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if multiplayer.is_server():
			rpc("sync_arena_selection", 1)
	else:
		sync_arena_selection(1)

func _on_arena2_pressed() -> void:
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if multiplayer.is_server():
			rpc("sync_arena_selection", 2)
	else:
		sync_arena_selection(2)

@rpc("authority", "call_local", "reliable")
func sync_arena_selection(arena_idx: int) -> void:
	if arena_idx == 1:
		_play_click()
		_zoom_and_transition(arena1_btn, "res://Scenes/game.tscn")
	elif arena_idx == 2:
		_play_click()
		_zoom_and_transition(arena2_btn, "res://Scenes/game2.tscn")

func _zoom_and_transition(btn: Button, target_scene: String) -> void:
	# Disable buttons to prevent double clicking
	arena1_btn.disabled = true
	arena2_btn.disabled = true
	back_btn.disabled = true
	
	var gm = GameManager.instance
	if gm: gm.selected_arena = target_scene
	
	# Bring clicked button to front
	move_child(btn, get_child_count() - 1)
	btn.pivot_offset = btn.size / 2.0
	
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var screen_center = get_viewport_rect().size / 2.0
	tween.tween_property(btn, "position", screen_center - (btn.size / 2.0), 0.5)
	tween.tween_property(btn, "scale", Vector2(15.0, 15.0), 0.6)
	tween.tween_property(btn, "modulate:a", 0.0, 0.6)
	
	var other_btn = arena2_btn if btn == arena1_btn else arena1_btn
	tween.tween_property(other_btn, "modulate:a", 0.0, 0.3)
	tween.tween_property($Title, "modulate:a", 0.0, 0.3)
	tween.tween_property(back_btn, "modulate:a", 0.0, 0.3)
	
	await get_tree().create_timer(0.65).timeout
	
	if target_scene != "":
		SceneTransition.change_scene(target_scene)

func _on_back_pressed() -> void:
	_play_click()
	SceneTransition.change_scene("res://Scenes/skin_menu.tscn")
