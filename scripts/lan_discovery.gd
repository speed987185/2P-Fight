extends Node

var udp_peer := PacketPeerUDP.new()
var is_broadcasting_host := false
const DISCOVERY_PORT = 12346

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_broadcasting_host():
	is_broadcasting_host = true
	var err = udp_peer.bind(DISCOVERY_PORT)
	if err != OK:
		print("Failed to bind UDP port for hosting.")
		return
	print("Started broadcasting host on LAN.")

func stop_broadcasting():
	is_broadcasting_host = false
	udp_peer.close()

func _process(delta):
	if is_broadcasting_host and udp_peer.get_available_packet_count() > 0:
		var array_bytes = udp_peer.get_packet()
		var packet_string = array_bytes.get_string_from_ascii()
		
		if packet_string == "LOOKING_FOR_HOST":
			# Reply back to the sender
			var sender_ip = udp_peer.get_packet_ip()
			var sender_port = udp_peer.get_packet_port()
			udp_peer.set_dest_address(sender_ip, sender_port)
			udp_peer.put_packet("HOST_AVAILABLE".to_ascii_buffer())
			print("Answered discovery request from ", sender_ip)
