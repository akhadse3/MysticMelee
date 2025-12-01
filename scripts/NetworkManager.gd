extends Node

# Signals
signal connection_succeeded
signal connection_failed
signal player_connected(id: int)
signal player_disconnected(id: int)
signal server_disconnected
signal game_started
signal rematch_requested
signal rematch_accepted
signal opponent_played_card(card_type: int)
signal opponent_reacted(did_react: bool)
signal opponent_effect_choice(choice_data: Dictionary)
signal chat_message_received(sender: String, message: String)

# Network mode
enum NetworkMode { NONE, LAN, ONLINE }

# Network settings
const DEFAULT_PORT = 7777
const MAX_PLAYERS = 2

# State
var network_mode: NetworkMode = NetworkMode.NONE
var is_multiplayer: bool = false
var is_host: bool = false
var peer_id: int = 0
var opponent_id: int = 0
var opponent_name: String = "Opponent"
var local_player_name: String = "Player"
var current_port: int = DEFAULT_PORT

# Game start data (stored for when we change scenes)
var game_start_data: Dictionary = {}
var game_ready_to_start: bool = false

# Rematch state
var rematch_pending: bool = false
var local_wants_rematch: bool = false
var opponent_wants_rematch: bool = false

# Connection state
var is_connected: bool = false

func _ready():
	# Connect multiplayer signals (for LAN mode)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Connect Nakama signals (for online mode)
	_connect_nakama_signals()

func _connect_nakama_signals():
	# Wait a frame to ensure NakamaManager is loaded
	await get_tree().process_frame
	
	var nakama = get_node_or_null("/root/NakamaManager")
	if nakama:
		nakama.match_joined.connect(_on_nakama_match_joined)
		nakama.match_left.connect(_on_nakama_match_left)
		nakama.player_joined.connect(_on_nakama_player_joined)
		nakama.player_left.connect(_on_nakama_player_left)
		nakama.match_state_received.connect(_on_nakama_match_state_received)
		nakama.socket_closed.connect(_on_nakama_socket_closed)
		print("[NetworkManager] Connected to NakamaManager signals")

# ============================================
# LAN MULTIPLAYER (ENet)
# ============================================

func host_game(player_name: String, port: int = DEFAULT_PORT) -> Error:
	network_mode = NetworkMode.LAN
	local_player_name = player_name
	current_port = port
	
	# Close any existing connection first
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)
	
	if error != OK:
		print("[NetworkManager] Failed to create server on port ", port, " - Error: ", error)
		return error
	
	multiplayer.multiplayer_peer = peer
	is_multiplayer = true
	is_host = true
	is_connected = true
	peer_id = 1  # Host is always ID 1
	game_ready_to_start = false
	_reset_rematch_state()
	
	print("[NetworkManager] Server started successfully on port ", port)
	return OK

func join_game(player_name: String, address: String, port: int = DEFAULT_PORT) -> Error:
	network_mode = NetworkMode.LAN
	local_player_name = player_name
	current_port = port
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	
	if error != OK:
		return error
	
	multiplayer.multiplayer_peer = peer
	is_multiplayer = true
	is_host = false
	game_ready_to_start = false
	_reset_rematch_state()
	
	print("Connecting to ", address, ":", port)
	return OK

# Join using a room code
func join_with_code(player_name: String, room_code: String) -> Error:
	var decoded = decode_room_code(room_code)
	if decoded.is_empty():
		print("Failed to decode room code: ", room_code)
		return ERR_INVALID_PARAMETER
	
	print("Decoded room code - IP: ", decoded["ip"], " Port: ", decoded["port"])
	return join_game(player_name, decoded["ip"], decoded["port"])

# ============================================
# ONLINE MULTIPLAYER (Nakama)
# ============================================

func start_online_multiplayer(player_name: String) -> bool:
	var nakama = get_node_or_null("/root/NakamaManager")
	if not nakama:
		push_error("NakamaManager not found!")
		return false
	
	network_mode = NetworkMode.ONLINE
	local_player_name = player_name
	is_multiplayer = true
	game_ready_to_start = false
	_reset_rematch_state()
	
	# Authenticate if not already
	if not nakama.is_authenticated:
		var auth_result = await nakama.authenticate_device("", player_name)
		if not auth_result:
			return false
	
	# Connect socket if not connected
	if not nakama.is_socket_connected:
		var socket_result = await nakama.connect_socket()
		if not socket_result:
			return false
	
	is_connected = true
	return true

func start_online_matchmaking() -> bool:
	var nakama = get_node_or_null("/root/NakamaManager")
	if not nakama or not nakama.is_socket_connected:
		return false
	
	return await nakama.start_matchmaking(2, 2)

func cancel_online_matchmaking() -> bool:
	var nakama = get_node_or_null("/root/NakamaManager")
	if nakama:
		return await nakama.cancel_matchmaking()
	return false

func create_online_match() -> bool:
	var nakama = get_node_or_null("/root/NakamaManager")
	if not nakama or not nakama.is_socket_connected:
		return false
	
	return await nakama.create_match()

func join_online_match(match_id: String) -> bool:
	var nakama = get_node_or_null("/root/NakamaManager")
	if not nakama or not nakama.is_socket_connected:
		return false
	
	return await nakama.join_match(match_id)

func _on_nakama_match_joined(match_data: Dictionary):
	is_host = match_data.get("is_host", false)
	peer_id = 1 if is_host else 2
	
	var opponent = match_data.get("opponent")
	if opponent:
		opponent_name = opponent.username if opponent.username else "Opponent"
		opponent_id = 2 if is_host else 1
		emit_signal("player_connected", opponent_id)
	
	print("[NetworkManager] Nakama match joined - Host: ", is_host)

func _on_nakama_match_left():
	is_connected = false
	is_multiplayer = false
	emit_signal("server_disconnected")

func _on_nakama_player_joined(presence: Dictionary):
	opponent_name = presence.get("username", "Opponent")
	opponent_id = 2 if is_host else 1
	
	# Send our player info
	var nakama = get_node_or_null("/root/NakamaManager")
	if nakama:
		nakama.send_player_info(local_player_name)
	
	print("[NetworkManager] Player joined: ", opponent_name)
	emit_signal("player_connected", opponent_id)

func _on_nakama_player_left(presence: Dictionary):
	opponent_id = 0
	opponent_name = "Opponent"
	_reset_rematch_state()
	emit_signal("player_disconnected", 2)

func _on_nakama_socket_closed():
	is_connected = false
	is_multiplayer = false
	_reset_rematch_state()
	emit_signal("server_disconnected")

func _on_nakama_match_state_received(op_code: int, data: String, sender_id: String):
	var nakama = get_node_or_null("/root/NakamaManager")
	if not nakama:
		return
	
	# Ignore messages from ourselves
	if nakama.my_presence and sender_id == nakama.my_presence.session_id:
		return
	
	var json = JSON.new()
	if json.parse(data) != OK:
		print("[NetworkManager] Failed to parse match state: ", data)
		return
	
	var parsed_data = json.get_data()
	if not parsed_data is Dictionary:
		return
	
	match op_code:
		nakama.OpCode.PLAYER_INFO:
			opponent_name = parsed_data.get("name", "Opponent")
			print("[NetworkManager] Opponent name: ", opponent_name)
		
		nakama.OpCode.GAME_START:
			_handle_nakama_game_start(parsed_data)
		
		nakama.OpCode.CARD_PLAY:
			var card_type = parsed_data.get("card_type", 0)
			emit_signal("opponent_played_card", card_type)
		
		nakama.OpCode.REACTION:
			var did_react = parsed_data.get("did_react", false)
			emit_signal("opponent_reacted", did_react)
		
		nakama.OpCode.EFFECT_CHOICE:
			emit_signal("opponent_effect_choice", parsed_data)
		
		nakama.OpCode.CHAT:
			var message = parsed_data.get("message", "")
			emit_signal("chat_message_received", opponent_name, message)
		
		nakama.OpCode.REMATCH_REQUEST:
			opponent_wants_rematch = true
			emit_signal("rematch_requested")
			_check_rematch()

func _handle_nakama_game_start(data: Dictionary):
	var host_deck_seed = data.get("host_deck_seed", randi())
	var client_deck_seed = data.get("client_deck_seed", randi())
	var host_goes_first = data.get("host_goes_first", true)
	
	_reset_rematch_state()
	
	game_start_data = {
		"host_deck_seed": host_deck_seed,
		"client_deck_seed": client_deck_seed,
		"host_goes_first": host_goes_first,
		"is_host": is_host
	}
	game_ready_to_start = true
	
	print("[NetworkManager] Received game start data")
	emit_signal("game_started")

# ============================================
# COMMON FUNCTIONS
# ============================================

func disconnect_from_game():
	if network_mode == NetworkMode.LAN:
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer.close()
			multiplayer.multiplayer_peer = null
	elif network_mode == NetworkMode.ONLINE:
		var nakama = get_node_or_null("/root/NakamaManager")
		if nakama and nakama.is_in_match:
			nakama.leave_match()
	
	network_mode = NetworkMode.NONE
	is_multiplayer = false
	is_host = false
	is_connected = false
	peer_id = 0
	opponent_id = 0
	game_ready_to_start = false
	game_start_data.clear()
	_reset_rematch_state()

func _reset_rematch_state():
	rematch_pending = false
	local_wants_rematch = false
	opponent_wants_rematch = false

# Room Code System - encodes IP:Port into a shareable code using hex
func generate_room_code() -> String:
	# Get local IP addresses
	var ips = IP.get_local_addresses()
	var best_ip = "127.0.0.1"
	
	# Find the best local IP (prefer 192.168.x.x or 10.x.x.x)
	for ip in ips:
		if ip.begins_with("192.168.") or ip.begins_with("10."):
			best_ip = ip
			break
		elif ip.begins_with("172.") and not ip.begins_with("127."):
			best_ip = ip
	
	# Parse IP into parts
	var ip_parts = best_ip.split(".")
	if ip_parts.size() != 4:
		ip_parts = ["127", "0", "0", "1"]
	
	# Convert to hex: each IP octet (0-255) becomes 2 hex chars, port becomes 4 hex chars
	var code = ""
	for part in ip_parts:
		code += "%02X" % int(part)
	code += "%04X" % current_port
	
	# Format with dashes for readability: XXXX-XXXX-XXXX
	var formatted = ""
	for i in range(code.length()):
		if i > 0 and i % 4 == 0:
			formatted += "-"
		formatted += code[i]
	
	print("Generated room code: ", formatted, " for ", best_ip, ":", current_port)
	return formatted

func decode_room_code(code: String) -> Dictionary:
	# Remove formatting and convert to uppercase
	var cleaned = code.replace("-", "").replace(" ", "").to_upper()
	print("Cleaned room code: ", cleaned)
	
	# Should be exactly 12 hex chars (8 for IP + 4 for port)
	if cleaned.length() != 12:
		print("Invalid code length: ", cleaned.length(), " (expected 12)")
		return {}
	
	# Validate hex characters
	for c in cleaned:
		if not "0123456789ABCDEF".contains(c):
			print("Invalid hex character: ", c)
			return {}
	
	# Parse IP octets (each 2 hex chars)
	var ip_parts = []
	for i in range(4):
		var hex_str = cleaned.substr(i * 2, 2)
		var value = hex_str.hex_to_int()
		if value < 0 or value > 255:
			print("Invalid IP octet: ", value)
			return {}
		ip_parts.append(str(value))
	
	# Parse port (last 4 hex chars)
	var port_hex = cleaned.substr(8, 4)
	var port = port_hex.hex_to_int()
	if port <= 0 or port > 65535:
		print("Invalid port: ", port)
		return {}
	
	var ip = ".".join(ip_parts)
	print("Decoded: IP=", ip, " Port=", port)
	
	return {"ip": ip, "port": port}

# LAN callbacks
func _on_peer_connected(id: int):
	print("Peer connected: ", id)
	opponent_id = id
	emit_signal("player_connected", id)
	
	# Send our name to the new peer
	rpc_id(id, "receive_player_name", local_player_name)

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	opponent_id = 0
	_reset_rematch_state()
	emit_signal("player_disconnected", id)

func _on_connected_to_server():
	print("Connected to server!")
	is_connected = true
	peer_id = multiplayer.get_unique_id()
	emit_signal("connection_succeeded")

func _on_connection_failed():
	print("Connection failed!")
	is_connected = false
	emit_signal("connection_failed")

func _on_server_disconnected():
	print("Server disconnected!")
	is_connected = false
	_reset_rematch_state()
	emit_signal("server_disconnected")

# RPC for exchanging player names
@rpc("any_peer", "reliable")
func receive_player_name(name: String):
	var sender_id = multiplayer.get_remote_sender_id()
	opponent_name = name
	print("Opponent name: ", name)
	
	# If we're the host and just received the client's name, send ours back
	if is_host and sender_id != 1:
		rpc_id(sender_id, "receive_player_name", local_player_name)

# Host calls this to start the game
func start_multiplayer_game_as_host():
	if not is_host:
		return
	
	_reset_rematch_state()
	
	# Generate random seeds and decide who goes first
	var host_deck_seed = randi()
	var client_deck_seed = randi()
	var host_goes_first = randf() > 0.5
	
	print("Host starting game - host_seed: ", host_deck_seed, ", client_seed: ", client_deck_seed, ", host_first: ", host_goes_first)
	
	# Store data for local use
	game_start_data = {
		"host_deck_seed": host_deck_seed,
		"client_deck_seed": client_deck_seed,
		"host_goes_first": host_goes_first,
		"is_host": true
	}
	game_ready_to_start = true
	
	# Send to client via appropriate channel
	if network_mode == NetworkMode.LAN:
		rpc("receive_game_start", host_deck_seed, client_deck_seed, host_goes_first)
	elif network_mode == NetworkMode.ONLINE:
		var nakama = get_node_or_null("/root/NakamaManager")
		if nakama:
			nakama.send_game_start(host_deck_seed, client_deck_seed, host_goes_first)
	
	# Signal that game is starting (TitleScreen will change scene)
	emit_signal("game_started")

# Client receives game start data (LAN only)
@rpc("authority", "reliable")
func receive_game_start(host_deck_seed: int, client_deck_seed: int, host_goes_first: bool):
	print("Client received game start - host_seed: ", host_deck_seed, ", client_seed: ", client_deck_seed, ", host_first: ", host_goes_first)
	
	_reset_rematch_state()
	
	# Store data for when scene changes
	game_start_data = {
		"host_deck_seed": host_deck_seed,
		"client_deck_seed": client_deck_seed,
		"host_goes_first": host_goes_first,
		"is_host": false
	}
	game_ready_to_start = true
	
	# Signal that game is starting (TitleScreen will change scene)
	emit_signal("game_started")

# Called by Main.gd when scene is ready
func initialize_multiplayer_game():
	if not game_ready_to_start or game_start_data.is_empty():
		print("Error: Game start data not ready!")
		return
	
	print("Initializing multiplayer game with stored data")
	GameManager.start_multiplayer_game(
		game_start_data["host_deck_seed"],
		game_start_data["client_deck_seed"],
		game_start_data["host_goes_first"],
		game_start_data["is_host"]
	)
	
	# Clear the data after use
	game_ready_to_start = false

# Rematch system
func request_rematch():
	local_wants_rematch = true
	
	if network_mode == NetworkMode.LAN:
		rpc("receive_rematch_request")
	elif network_mode == NetworkMode.ONLINE:
		var nakama = get_node_or_null("/root/NakamaManager")
		if nakama:
			nakama.send_rematch_request()
	
	_check_rematch()

@rpc("any_peer", "reliable")
func receive_rematch_request():
	opponent_wants_rematch = true
	emit_signal("rematch_requested")
	_check_rematch()

func _check_rematch():
	if local_wants_rematch and opponent_wants_rematch:
		# Both players want rematch
		if is_host:
			# Host starts the new game
			start_multiplayer_game_as_host()
		# Client will receive the game start via RPC or Nakama

# Game action RPCs (LAN mode)
@rpc("any_peer", "reliable")
func send_card_play(card_type: int):
	emit_signal("opponent_played_card", card_type)

func broadcast_card_play(card_type: int):
	if network_mode == NetworkMode.LAN:
		rpc("send_card_play", card_type)
	elif network_mode == NetworkMode.ONLINE:
		var nakama = get_node_or_null("/root/NakamaManager")
		if nakama:
			nakama.send_card_play(card_type)

@rpc("any_peer", "reliable")
func send_reaction(did_react: bool):
	emit_signal("opponent_reacted", did_react)

func broadcast_reaction(did_react: bool):
	if network_mode == NetworkMode.LAN:
		rpc("send_reaction", did_react)
	elif network_mode == NetworkMode.ONLINE:
		var nakama = get_node_or_null("/root/NakamaManager")
		if nakama:
			nakama.send_reaction(did_react)

@rpc("any_peer", "reliable")
func send_effect_choice(choice_data: Dictionary):
	emit_signal("opponent_effect_choice", choice_data)

func broadcast_effect_choice(choice_data: Dictionary):
	if network_mode == NetworkMode.LAN:
		rpc("send_effect_choice", choice_data)
	elif network_mode == NetworkMode.ONLINE:
		var nakama = get_node_or_null("/root/NakamaManager")
		if nakama:
			nakama.send_effect_choice(choice_data)

# Chat functionality
@rpc("any_peer", "reliable")
func receive_chat(sender: String, message: String):
	emit_signal("chat_message_received", sender, message)

func send_chat(message: String):
	if network_mode == NetworkMode.LAN:
		rpc("receive_chat", local_player_name, message)
	elif network_mode == NetworkMode.ONLINE:
		var nakama = get_node_or_null("/root/NakamaManager")
		if nakama:
			nakama.send_chat(message)

# Check if it's our turn
func is_local_player_turn() -> bool:
	if not is_multiplayer:
		return true
	
	var is_player_one_turn = GameManager.pending_is_player
	if is_host:
		return is_player_one_turn
	else:
		return not is_player_one_turn

func is_local_player_one() -> bool:
	return is_host

# Get online match ID for display
func get_online_match_id() -> String:
	if network_mode == NetworkMode.ONLINE:
		var nakama = get_node_or_null("/root/NakamaManager")
		if nakama:
			return nakama.get_short_match_id()
	return ""
