extends Node

# Nakama Manager - Handles all Nakama server communication for online multiplayer
# This provides authentication, matchmaking, and real-time match communication

# Signals
signal authenticated
signal authentication_failed(error: String)
signal socket_connected
signal socket_connection_failed(error: String)
signal socket_closed
signal matchmaking_started
signal matchmaking_cancelled
signal match_found(match_id: String)
signal match_joined(match_data: Dictionary)
signal match_join_failed(error: String)
signal match_left
signal player_joined(presence: Dictionary)
signal player_left(presence: Dictionary)
signal match_state_received(op_code: int, data: String, sender_id: String)

# Op codes for match state messages
enum OpCode {
	GAME_START = 1,
	CARD_PLAY = 2,
	REACTION = 3,
	EFFECT_CHOICE = 4,
	CHAT = 5,
	REMATCH_REQUEST = 6,
	PLAYER_INFO = 7
}

# Nakama configuration - Oracle Cloud Server with SSL
var server_key: String = "defaultkey"
var server_host: String = "mysticcards.duckdns.org"  # Your DuckDNS domain
var server_port: int = 443
var server_scheme: String = "https"
var socket_scheme: String = "wss"

# Nakama client and session
var client: NakamaClient = null
var session: NakamaSession = null
var socket: NakamaSocket = null

# Match state
var current_match_id: String = ""
var current_match = null
var matchmaker_ticket: String = ""
var my_presence = null
var opponent_presence = null
var presences: Dictionary = {}  # session_id -> presence

# User info
var user_id: String = ""
var username: String = ""
var display_name: String = ""

# State flags
var is_authenticated: bool = false
var is_socket_connected: bool = false
var is_in_match: bool = false
var is_matchmaking: bool = false
var is_host: bool = false  # First player to join is host

func _ready():
	# Create the Nakama client
	_create_client()

func _create_client():
	var nakama_node = get_node_or_null("/root/Nakama")
	if nakama_node:
		client = nakama_node.create_client(
			server_key,
			server_host,
			server_port,
			server_scheme
		)
		print("[Nakama] Client created: ", server_host, ":", server_port)
	else:
		push_error("[Nakama] Nakama addon not found! Make sure it's properly installed.")

# ============================================
# AUTHENTICATION
# ============================================

func authenticate_device(device_id: String = "", p_username: String = "") -> bool:
	if client == null:
		_create_client()
		if client == null:
			emit_signal("authentication_failed", "Nakama client not initialized")
			return false
	
	# Generate device ID if not provided
	if device_id.is_empty():
		device_id = _generate_device_id()
	
	# Generate a random username if not provided (for web compatibility)
	if p_username.is_empty():
		p_username = "Player_" + str(randi() % 100000)
	
	print("[Nakama] Authenticating with device ID...")
	
	session = await client.authenticate_device_async(device_id, p_username, true)
	
	if session.is_exception():
		var error = session.get_exception().message
		print("[Nakama] Authentication failed: ", error)
		emit_signal("authentication_failed", error)
		return false
	
	user_id = session.user_id
	username = session.username
	is_authenticated = true
	
	print("[Nakama] Authenticated! User ID: ", user_id, ", Username: ", username)
	emit_signal("authenticated")
	return true

func authenticate_email(email: String, password: String, p_username: String = "") -> bool:
	if client == null:
		_create_client()
		if client == null:
			emit_signal("authentication_failed", "Nakama client not initialized")
			return false
	
	print("[Nakama] Authenticating with email...")
	
	session = await client.authenticate_email_async(email, password, p_username, true)
	
	if session.is_exception():
		var error = session.get_exception().message
		print("[Nakama] Authentication failed: ", error)
		emit_signal("authentication_failed", error)
		return false
	
	user_id = session.user_id
	username = session.username
	is_authenticated = true
	
	print("[Nakama] Authenticated! User ID: ", user_id, ", Username: ", username)
	emit_signal("authenticated")
	return true

func _generate_device_id() -> String:
	# Generate a unique device ID
	var id = OS.get_unique_id()
	if id.is_empty():
		# Fallback: generate a random ID and save it
		var config = ConfigFile.new()
		var path = "user://nakama_device_id.cfg"
		if config.load(path) == OK:
			id = config.get_value("auth", "device_id", "")
		if id.is_empty():
			id = str(randi()) + str(Time.get_unix_time_from_system())
			config.set_value("auth", "device_id", id)
			config.save(path)
	return id

# ============================================
# SOCKET CONNECTION
# ============================================

func connect_socket() -> bool:
	if not is_authenticated:
		print("[Nakama] Cannot connect socket: not authenticated")
		return false
	
	if socket != null and socket.is_connected_to_host():
		print("[Nakama] Socket already connected")
		return true
	
	var nakama_node = get_node_or_null("/root/Nakama")
	if nakama_node == null:
		emit_signal("socket_connection_failed", "Nakama addon not found")
		return false
	
	socket = nakama_node.create_socket_from(client)
	
	# Connect socket signals
	socket.connected.connect(_on_socket_connected)
	socket.closed.connect(_on_socket_closed)
	socket.received_error.connect(_on_socket_error)
	socket.received_match_state.connect(_on_match_state_received)
	socket.received_match_presence.connect(_on_match_presence)
	socket.received_matchmaker_matched.connect(_on_matchmaker_matched)
	
	print("[Nakama] Connecting socket...")
	var result = await socket.connect_async(session)
	
	if result.is_exception():
		var error = result.get_exception().message
		print("[Nakama] Socket connection failed: ", error)
		emit_signal("socket_connection_failed", error)
		return false
	
	return true

func disconnect_socket():
	if socket != null:
		socket.close()
		socket = null
	is_socket_connected = false

func _on_socket_connected():
	is_socket_connected = true
	print("[Nakama] Socket connected!")
	emit_signal("socket_connected")

func _on_socket_closed():
	is_socket_connected = false
	is_in_match = false
	print("[Nakama] Socket closed")
	emit_signal("socket_closed")

func _on_socket_error(error):
	print("[Nakama] Socket error: ", error)

# ============================================
# MATCHMAKING
# ============================================

func start_matchmaking(min_players: int = 2, max_players: int = 2) -> bool:
	if not is_socket_connected:
		print("[Nakama] Cannot start matchmaking: socket not connected")
		return false
	
	if is_matchmaking:
		print("[Nakama] Already matchmaking")
		return false
	
	print("[Nakama] Starting matchmaking...")
	
	# Query matches for exactly 2 players in Mystic Cards
	var ticket = await socket.add_matchmaker_async(
		"*",  # Query - match anyone
		min_players,
		max_players,
		{},  # String properties
		{}   # Numeric properties
	)
	
	if ticket.is_exception():
		var error = ticket.get_exception().message
		print("[Nakama] Matchmaking failed: ", error)
		return false
	
	matchmaker_ticket = ticket.ticket
	is_matchmaking = true
	print("[Nakama] Matchmaking started with ticket: ", matchmaker_ticket)
	emit_signal("matchmaking_started")
	return true

func cancel_matchmaking() -> bool:
	if not is_matchmaking or matchmaker_ticket.is_empty():
		return false
	
	print("[Nakama] Cancelling matchmaking...")
	var result = await socket.remove_matchmaker_async(matchmaker_ticket)
	
	is_matchmaking = false
	matchmaker_ticket = ""
	emit_signal("matchmaking_cancelled")
	return true

func _on_matchmaker_matched(matched):
	print("[Nakama] Matchmaker found a match!")
	is_matchmaking = false
	matchmaker_ticket = ""
	
	# Join the match
	var match_result = await socket.join_matched_async(matched)
	
	if match_result.is_exception():
		var error = match_result.get_exception().message
		print("[Nakama] Failed to join matched game: ", error)
		emit_signal("match_join_failed", error)
		return
	
	_setup_match(match_result)

# ============================================
# MATCH MANAGEMENT
# ============================================

func create_match() -> bool:
	if not is_socket_connected:
		print("[Nakama] Cannot create match: socket not connected")
		return false
	
	print("[Nakama] Creating match...")
	var match_result = await socket.create_match_async()
	
	if match_result.is_exception():
		var error = match_result.get_exception().message
		print("[Nakama] Failed to create match: ", error)
		emit_signal("match_join_failed", error)
		return false
	
	_setup_match(match_result)
	is_host = true  # Creator is always host
	return true

func join_match(match_id: String) -> bool:
	if not is_socket_connected:
		print("[Nakama] Cannot join match: socket not connected")
		return false
	
	print("[Nakama] Joining match: ", match_id)
	var match_result = await socket.join_match_async(match_id)
	
	if match_result.is_exception():
		var error = match_result.get_exception().message
		print("[Nakama] Failed to join match: ", error)
		emit_signal("match_join_failed", error)
		return false
	
	_setup_match(match_result)
	return true

func leave_match() -> bool:
	if not is_in_match or current_match_id.is_empty():
		return false
	
	print("[Nakama] Leaving match: ", current_match_id)
	await socket.leave_match_async(current_match_id)
	
	_cleanup_match()
	emit_signal("match_left")
	return true

func _setup_match(match_result):
	current_match_id = match_result.match_id
	current_match = match_result
	my_presence = match_result.self_user
	is_in_match = true
	presences.clear()
	
	# Store my presence
	presences[my_presence.session_id] = my_presence
	
	# Determine if we're the host (first player or matchmaker position)
	var all_presences = match_result.presences
	if all_presences.size() == 0:
		is_host = true  # We're the only one, so we're host
	else:
		# Check if there are existing players - if so, we're not host
		is_host = false
		for presence in all_presences:
			presences[presence.session_id] = presence
			if presence.session_id != my_presence.session_id:
				opponent_presence = presence
	
	var match_data = {
		"match_id": current_match_id,
		"user_id": my_presence.user_id,
		"session_id": my_presence.session_id,
		"username": my_presence.username,
		"is_host": is_host,
		"opponent": opponent_presence
	}
	
	print("[Nakama] Joined match: ", current_match_id, " as ", ("host" if is_host else "client"))
	emit_signal("match_joined", match_data)
	emit_signal("match_found", current_match_id)

func _cleanup_match():
	current_match_id = ""
	current_match = null
	my_presence = null
	opponent_presence = null
	presences.clear()
	is_in_match = false
	is_host = false

func _on_match_presence(event):
	# Handle players joining/leaving
	for presence in event.joins:
		if presence.session_id != my_presence.session_id:
			print("[Nakama] Player joined: ", presence.username)
			presences[presence.session_id] = presence
			opponent_presence = presence
			emit_signal("player_joined", {
				"user_id": presence.user_id,
				"session_id": presence.session_id,
				"username": presence.username
			})
	
	for presence in event.leaves:
		print("[Nakama] Player left: ", presence.username)
		presences.erase(presence.session_id)
		if opponent_presence and presence.session_id == opponent_presence.session_id:
			opponent_presence = null
		emit_signal("player_left", {
			"user_id": presence.user_id,
			"session_id": presence.session_id,
			"username": presence.username
		})

# ============================================
# MATCH STATE / MESSAGING
# ============================================

func send_match_state(op_code: int, data: Dictionary) -> bool:
	if not is_in_match or socket == null:
		return false
	
	var json_data = JSON.stringify(data)
	socket.send_match_state_async(current_match_id, op_code, json_data)
	return true

func _on_match_state_received(match_state):
	if match_state.match_id != current_match_id:
		return
	
	var sender_id = match_state.presence.session_id
	var op_code = match_state.op_code
	var data = match_state.data  # This is already decoded from base64
	
	emit_signal("match_state_received", op_code, data, sender_id)

# ============================================
# GAME-SPECIFIC MESSAGE HELPERS
# ============================================

func send_player_info(player_name: String):
	send_match_state(OpCode.PLAYER_INFO, {
		"name": player_name
	})

func send_game_start(host_deck_seed: int, client_deck_seed: int, host_goes_first: bool):
	send_match_state(OpCode.GAME_START, {
		"host_deck_seed": host_deck_seed,
		"client_deck_seed": client_deck_seed,
		"host_goes_first": host_goes_first
	})

func send_card_play(card_type: int):
	send_match_state(OpCode.CARD_PLAY, {
		"card_type": card_type
	})

func send_reaction(did_react: bool):
	send_match_state(OpCode.REACTION, {
		"did_react": did_react
	})

func send_effect_choice(choice_data: Dictionary):
	send_match_state(OpCode.EFFECT_CHOICE, choice_data)

func send_chat(message: String):
	send_match_state(OpCode.CHAT, {
		"message": message
	})

func send_rematch_request():
	send_match_state(OpCode.REMATCH_REQUEST, {})

# ============================================
# UTILITY
# ============================================

func get_opponent_username() -> String:
	if opponent_presence:
		return opponent_presence.username
	return "Opponent"

func is_ready_to_play() -> bool:
	return is_authenticated and is_socket_connected and is_in_match and opponent_presence != null

func get_short_match_id() -> String:
	# Return a shortened match ID for display (first 8 characters)
	if current_match_id.length() > 8:
		return current_match_id.substr(0, 8).to_upper()
	return current_match_id.to_upper()

# Update server configuration
func configure_server(host: String, port: int, key: String = "defaultkey", use_ssl: bool = false):
	server_host = host
	server_port = port
	server_key = key
	server_scheme = "https" if use_ssl else "http"
	socket_scheme = "wss" if use_ssl else "ws"
	
	# Recreate client with new settings
	_create_client()
	print("[Nakama] Server configured: ", host, ":", port)

