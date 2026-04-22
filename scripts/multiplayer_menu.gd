extends Control

class_name MultiplayerMenu

@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/HBoxContainer/JoinButton
@onready var ip_input: LineEdit = $VBoxContainer/HBoxContainer/IPInput
@onready var find_match_button: Button = $VBoxContainer/FindMatchButton
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var status_label: Label = $VBoxContainer/StatusLabel

const PORT = 12345
const DISCOVERY_PORT = 12346

var udp_peer := PacketPeerUDP.new()
var is_searching := false
var search_timer := 0.0

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	find_match_button.pressed.connect(_on_find_match_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(delta: float) -> void:
	if is_searching:
		search_timer -= delta
		if udp_peer.get_available_packet_count() > 0:
			var packet_bytes = udp_peer.get_packet()
			var msg = packet_bytes.get_string_from_ascii()
			if msg == "HOST_AVAILABLE":
				var host_ip = udp_peer.get_packet_ip()
				print("Found host at: ", host_ip)
				is_searching = false
				udp_peer.close()
				_join_game_with_ip(host_ip)
				return
				
		if search_timer <= 0:
			# No host found, become host!
			print("No host found, becoming host.")
			is_searching = false
			udp_peer.close()
			_on_host_pressed()

func _on_find_match_pressed() -> void:
	status_label.text = "Searching for game on LAN..."
	host_button.disabled = true
	join_button.disabled = true
	find_match_button.disabled = true
	
	udp_peer.set_broadcast_enabled(true)
	udp_peer.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	var err = udp_peer.bind(0) # Bind to random port to receive replies
	if err == OK:
		udp_peer.put_packet("LOOKING_FOR_HOST".to_ascii_buffer())
		is_searching = true
		search_timer = 2.0 # 2 seconds to find a host
	else:
		status_label.text = "Failed to bind UDP."

func _on_host_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 2)
	if error != OK:
		status_label.text = "Error hosting server: " + str(error)
		return
	
	multiplayer.multiplayer_peer = peer
	var gm: GameManager = GameManager.instance
	if gm != null:
		gm.is_multiplayer_session = true
	status_label.text = "Hosting..."
	
	# Start background LAN discovery broadcasting
	if not get_tree().root.has_node("LANDiscovery"):
		var discovery = Node.new()
		discovery.name = "LANDiscovery"
		discovery.set_script(preload("res://scripts/lan_discovery.gd"))
		get_tree().root.add_child(discovery)
	get_tree().root.get_node("LANDiscovery").start_broadcasting_host()
	
	# Move to lobby
	get_tree().change_scene_to_file("res://Scenes/lobby_scene.tscn")

func _on_join_pressed() -> void:
	var ip = ip_input.text.strip_edges()
	if ip == "":
		status_label.text = "Please enter an IP address."
		return
	_join_game_with_ip(ip)

func _join_game_with_ip(ip: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	if error != OK:
		status_label.text = "Error creating client: " + str(error)
		return
		
	multiplayer.multiplayer_peer = peer
	var gm: GameManager = GameManager.instance
	if gm != null:
		gm.is_multiplayer_session = true
	status_label.text = "Connecting to " + ip + "..."
	host_button.disabled = true
	join_button.disabled = true
	find_match_button.disabled = true

func _on_connected_ok() -> void:
	status_label.text = "Connected!"
	get_tree().change_scene_to_file("res://Scenes/lobby_scene.tscn")

func _on_connected_fail() -> void:
	status_label.text = "Connection failed."
	multiplayer.multiplayer_peer = null
	var gm: GameManager = GameManager.instance
	if gm != null:
		gm.is_multiplayer_session = false
	host_button.disabled = false
	join_button.disabled = false
	if is_instance_valid(find_match_button):
		find_match_button.disabled = false

func _on_server_disconnected() -> void:
	status_label.text = "Disconnected from server."
	multiplayer.multiplayer_peer = null
	var gm: GameManager = GameManager.instance
	if gm != null:
		gm.is_multiplayer_session = false
	host_button.disabled = false
	join_button.disabled = false
	if is_instance_valid(find_match_button):
		find_match_button.disabled = false

func _on_back_pressed() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		var gm: GameManager = GameManager.instance
		if gm != null:
			gm.is_multiplayer_session = false
	
	if get_tree().root.has_node("LANDiscovery"):
		var d = get_tree().root.get_node("LANDiscovery")
		d.stop_broadcasting()
		d.queue_free()
		
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
