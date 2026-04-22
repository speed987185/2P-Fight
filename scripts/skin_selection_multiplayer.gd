extends Control

class_name SkinSelectionMultiplayer

@onready var role_label: Label = $VBoxContainer/RoleLabel
@onready var selections_label: Label = $VBoxContainer/SelectionsLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton

@onready var skin_0: Button = $VBoxContainer/SkinButtons/Skin0
@onready var skin_1: Button = $VBoxContainer/SkinButtons/Skin1
@onready var skin_2: Button = $VBoxContainer/SkinButtons/Skin2
@onready var skin_3: Button = $VBoxContainer/SkinButtons/Skin3

var my_id = 1
var selected_skin = 0
var confirmed = false

var player_roles = {} # id : role ("P1" or "P2")
var player_skins = {} # id : skin_id
var player_confirmed = {} # id : bool

func _ready() -> void:
	my_id = multiplayer.get_unique_id()
	
	skin_0.pressed.connect(_on_skin_selected.bind(0))
	skin_1.pressed.connect(_on_skin_selected.bind(1))
	skin_2.pressed.connect(_on_skin_selected.bind(2))
	skin_3.pressed.connect(_on_skin_selected.bind(3))
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	if multiplayer.is_server():
		# Assign roles
		var peers = multiplayer.get_peers()
		var p1_id = my_id
		var p2_id = peers[0] if peers.size() > 0 else 0
		
		# Randomize P1 and P2
		if randf() > 0.5 and p2_id != 0:
			p1_id = p2_id
			p2_id = my_id
			
		player_roles[p1_id] = "P1"
		if p2_id != 0:
			player_roles[p2_id] = "P2"
			
		player_skins[p1_id] = 0
		player_confirmed[p1_id] = false
		if p2_id != 0:
			player_skins[p2_id] = 0
			player_confirmed[p2_id] = false
			
		update_ui()
		# Sync roles to clients
		rpc("sync_state", player_roles, player_skins, player_confirmed)

func _on_skin_selected(skin_id: int) -> void:
	if confirmed: return
	selected_skin = skin_id
	rpc_id(1, "request_skin", my_id, skin_id)

@rpc("any_peer", "call_local", "reliable")
func request_skin(id: int, skin_id: int):
	if multiplayer.is_server() and not player_confirmed[id]:
		player_skins[id] = skin_id
		rpc("sync_state", player_roles, player_skins, player_confirmed)

func _on_confirm_pressed() -> void:
	if confirmed: return
	confirmed = true
	confirm_button.disabled = true
	skin_0.disabled = true
	skin_1.disabled = true
	skin_2.disabled = true
	skin_3.disabled = true
	rpc_id(1, "set_confirmed", my_id)

@rpc("any_peer", "call_local", "reliable")
func set_confirmed(id: int):
	if multiplayer.is_server():
		player_confirmed[id] = true
		rpc("sync_state", player_roles, player_skins, player_confirmed)
		
		var all_ready = true
		for peer_id in player_confirmed.keys():
			if not player_confirmed[peer_id]:
				all_ready = false
				break
		
		if all_ready and player_confirmed.size() == 2:
			# Auto start game
			rpc("start_multiplayer_game", player_roles, player_skins)

@rpc("authority", "call_local", "reliable")
func sync_state(roles: Dictionary, skins: Dictionary, confs: Dictionary):
	player_roles = roles
	player_skins = skins
	player_confirmed = confs
	update_ui()

func update_ui():
	if not player_roles.has(my_id): return
	
	role_label.text = "You are: " + player_roles[my_id]
	
	var sel_text = ""
	for id in player_roles.keys():
		var role = player_roles[id]
		var s_id = player_skins[id]
		var is_conf = player_confirmed[id]
		var c_text = "(Ready)" if is_conf else "(Selecting)"
		sel_text += role + " selected skin " + str(s_id) + " " + c_text + "\n"
	
	selections_label.text = sel_text

@rpc("authority", "call_local", "reliable")
func start_multiplayer_game(roles: Dictionary, skins: Dictionary) -> void:
	player_roles = roles
	player_skins = skins
	var mm = get_tree().root.get_node_or_null("MultiplayerManager")
	if not mm:
		mm = Node.new()
		mm.name = "MultiplayerManager"
		mm.set_script(preload("res://scripts/multiplayer_manager.gd"))
		get_tree().root.add_child(mm)
	
	mm.player_roles = player_roles
	mm.player_skins = player_skins
	
	get_tree().change_scene_to_file("res://Scenes/multiplayer_game.tscn")
