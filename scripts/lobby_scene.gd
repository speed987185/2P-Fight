extends Control

class_name LobbyScene

@onready var players_list: VBoxContainer = $VBoxContainer/PlayersList
@onready var ready_button: Button = $VBoxContainer/ReadyButton
@onready var start_game_button: Button = $VBoxContainer/StartGameButton
@onready var leave_button: Button = $VBoxContainer/LeaveButton

var player_status = {} # peer_id : is_ready (bool)
var my_id = 1

func _ready() -> void:
	my_id = multiplayer.get_unique_id()
	
	ready_button.pressed.connect(_on_ready_pressed)
	start_game_button.pressed.connect(_on_start_game_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	
	if multiplayer.is_server():
		start_game_button.show()
		start_game_button.disabled = true
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	if multiplayer.is_server():
		player_status[my_id] = false
		update_ui()
	else:
		rpc_id(1, "register_player", my_id)

func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		if get_tree().root.has_node("LANDiscovery"):
			get_tree().root.get_node("LANDiscovery").stop_broadcasting()

func _on_peer_disconnected(id: int) -> void:
	player_status.erase(id)
	update_ui()
	if multiplayer.is_server():
		if get_tree().root.has_node("LANDiscovery"):
			get_tree().root.get_node("LANDiscovery").start_broadcasting_host()

@rpc("any_peer", "call_local", "reliable")
func register_player(id: int):
	if multiplayer.is_server():
		player_status[id] = false
		for peer_id in player_status.keys():
			rpc("sync_player", peer_id, player_status[peer_id])
		# Also send back to the newly registered player the whole list
		rpc_id(id, "sync_all", player_status)

@rpc("authority", "call_local", "reliable")
func sync_all(full_status: Dictionary):
	player_status = full_status
	update_ui()

@rpc("authority", "call_local", "reliable")
func sync_player(id: int, is_ready: bool):
	player_status[id] = is_ready
	update_ui()

func update_ui():
	for child in players_list.get_children():
		child.queue_free()
	
	var all_ready = true
	for id in player_status.keys():
		var label = Label.new()
		var status_text = "Ready" if player_status[id] else "Not Ready"
		var name_text = "Host" if id == 1 else "Player 2"
		if id == my_id:
			name_text += " (You)"
		label.text = name_text + " - " + status_text
		label.add_theme_font_size_override("font_size", 20)
		players_list.add_child(label)
		
		if not player_status[id]:
			all_ready = false
			
	if multiplayer.is_server():
		start_game_button.disabled = not (all_ready and player_status.size() == 2)

func _on_ready_pressed() -> void:
	rpc_id(1, "set_ready", my_id, true)
	ready_button.disabled = true

@rpc("any_peer", "call_local", "reliable")
func set_ready(id: int, is_ready: bool):
	if multiplayer.is_server():
		player_status[id] = is_ready
		for peer_id in player_status.keys():
			rpc("sync_player", peer_id, player_status[peer_id])

func _on_start_game_pressed() -> void:
	if multiplayer.is_server():
		# Assign roles based on player_status keys
		var peers = player_status.keys()
		var p1_id = 1
		var p2_id = 0
		for id in peers:
			if id != 1:
				p2_id = id
		
		# Keep host as P1 by default, or randomize
		if randf() > 0.5 and p2_id != 0:
			p1_id = p2_id
			p2_id = 1
			
		var roles = {}
		roles[p1_id] = "P1"
		if p2_id != 0:
			roles[p2_id] = "P2"
		
		rpc("start_game_with_roles", roles)

@rpc("authority", "call_local", "reliable")
func start_game_with_roles(roles: Dictionary):
	var mm = get_tree().root.get_node_or_null("MultiplayerManager")
	if not mm:
		mm = Node.new()
		mm.name = "MultiplayerManager"
		mm.set_script(preload("res://scripts/multiplayer_manager.gd"))
		get_tree().root.add_child(mm)
	
	mm.player_roles = roles
	
	var gm: GameManager = GameManager.instance
	if gm != null:
		gm.is_multiplayer_session = true
	
	get_tree().change_scene_to_file("res://Scenes/skin_menu.tscn")


func _on_leave_pressed() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		
	if get_tree().root.has_node("LANDiscovery"):
		var d = get_tree().root.get_node("LANDiscovery")
		d.stop_broadcasting()
		d.queue_free()
		
	get_tree().change_scene_to_file("res://Scenes/multiplayer_menu.tscn")
