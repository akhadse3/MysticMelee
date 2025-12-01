extends Control

# Main menu buttons
@onready var single_player_btn: Button = $VBoxContainer/MenuButtons/SinglePlayerButton
@onready var multiplayer_btn: Button = $VBoxContainer/MenuButtons/MultiplayerButton
@onready var settings_btn: Button = $VBoxContainer/MenuButtons/SettingsButton
@onready var quit_btn: Button = $VBoxContainer/MenuButtons/QuitButton
@onready var title_label: Label = $VBoxContainer/Title

# Multiplayer panel
@onready var multiplayer_panel: PanelContainer = $MultiplayerPanel
@onready var player_name_input: LineEdit = $MultiplayerPanel/VBoxContainer/NameContainer/NameInput
@onready var status_label: Label = $MultiplayerPanel/VBoxContainer/StatusLabel
@onready var waiting_label: Label = $MultiplayerPanel/VBoxContainer/WaitingLabel
@onready var start_game_btn: Button = $MultiplayerPanel/VBoxContainer/StartGameButton
@onready var cancel_btn: Button = $MultiplayerPanel/VBoxContainer/CancelButton
@onready var back_btn: Button = $MultiplayerPanel/VBoxContainer/BackButton

# Online play buttons
@onready var quick_match_btn: Button = $MultiplayerPanel/VBoxContainer/QuickMatchButton
@onready var online_host_btn: Button = $MultiplayerPanel/VBoxContainer/OnlineHostButton
@onready var online_join_btn: Button = $MultiplayerPanel/VBoxContainer/OnlineJoinButton
@onready var online_match_id_container: HBoxContainer = $MultiplayerPanel/VBoxContainer/OnlineMatchIdContainer
@onready var match_id_value: Label = $MultiplayerPanel/VBoxContainer/OnlineMatchIdContainer/MatchIdValue
@onready var copy_match_id_btn: Button = $MultiplayerPanel/VBoxContainer/OnlineMatchIdContainer/CopyMatchIdButton
@onready var online_join_container: HBoxContainer = $MultiplayerPanel/VBoxContainer/OnlineJoinContainer
@onready var online_match_id_input: LineEdit = $MultiplayerPanel/VBoxContainer/OnlineJoinContainer/OnlineMatchIdInput
@onready var online_join_connect_btn: Button = $MultiplayerPanel/VBoxContainer/OnlineJoinContainer/OnlineJoinConnectButton

# LAN play buttons
@onready var host_btn: Button = $MultiplayerPanel/VBoxContainer/HostButton
@onready var join_btn: Button = $MultiplayerPanel/VBoxContainer/JoinButton
@onready var room_code_container: HBoxContainer = $MultiplayerPanel/VBoxContainer/RoomCodeContainer
@onready var room_code_display: Label = $MultiplayerPanel/VBoxContainer/RoomCodeContainer/RoomCodeLabel
@onready var copy_code_btn: Button = $MultiplayerPanel/VBoxContainer/RoomCodeContainer/CopyCodeButton
@onready var join_container: HBoxContainer = $MultiplayerPanel/VBoxContainer/JoinContainer
@onready var join_code_input: LineEdit = $MultiplayerPanel/VBoxContainer/JoinContainer/JoinCodeInput
@onready var join_connect_btn: Button = $MultiplayerPanel/VBoxContainer/JoinContainer/JoinConnectButton

# Settings panel
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var settings_close: Button = $SettingsPanel/VBoxContainer/CloseButton
@onready var theme_option: OptionButton = $SettingsPanel/VBoxContainer/ThemeContainer/ThemeOption
@onready var animations_check: CheckBox = $SettingsPanel/VBoxContainer/AnimationsCheck

# Background
@onready var background: ColorRect = $Background
@onready var background_pattern: ColorRect = $BackgroundPattern

# State
var is_host: bool = false
var is_online_mode: bool = false
var is_matchmaking: bool = false

func _ready():
	# Main menu buttons
	single_player_btn.pressed.connect(_on_single_player)
	multiplayer_btn.pressed.connect(_on_multiplayer)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	
	# Online play buttons
	quick_match_btn.pressed.connect(_on_quick_match)
	online_host_btn.pressed.connect(_on_online_host)
	online_join_btn.pressed.connect(_on_online_join)
	copy_match_id_btn.pressed.connect(_on_copy_match_id)
	online_join_connect_btn.pressed.connect(_on_online_join_connect)
	
	# LAN play buttons
	host_btn.pressed.connect(_on_host)
	join_btn.pressed.connect(_on_join)
	copy_code_btn.pressed.connect(_on_copy_code)
	join_connect_btn.pressed.connect(_on_join_connect)
	
	# Common buttons
	start_game_btn.pressed.connect(_on_start_game)
	cancel_btn.pressed.connect(_on_cancel)
	back_btn.pressed.connect(_on_back)
	
	# Settings
	settings_close.pressed.connect(_on_settings_close)
	theme_option.item_selected.connect(_on_theme_selected)
	animations_check.toggled.connect(_on_animations_toggled)
	
	# NetworkManager signals
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.game_started.connect(_on_game_started)
	
	# NakamaManager signals (connect after a frame to ensure it's loaded)
	_connect_nakama_signals()
	
	# SettingsManager
	SettingsManager.settings_changed.connect(_apply_theme)
	
	# Initialize UI
	multiplayer_panel.visible = false
	settings_panel.visible = false
	_reset_multiplayer_ui()
	
	_setup_settings_panel()
	_style_panels()
	_apply_theme()
	
	# Apply magical font to title (all platforms)
	_setup_title_font()
	
	# Mobile web optimizations
	if _is_mobile_web():
		_setup_mobile_title_ui()
		_setup_mobile_title_text()
	
	# Setup paste support for input fields
	_setup_paste_support()

func _is_mobile_web() -> bool:
	# Detect if running in mobile browser
	if not Engine.has_singleton("JavaScriptBridge"):
		return false
	
	var user_agent = JavaScriptBridge.eval("navigator.userAgent", true)
	if user_agent:
		var ua_lower = user_agent.to_lower()
		return "mobile" in ua_lower or "android" in ua_lower or "iphone" in ua_lower or "ipad" in ua_lower
	return false

func _setup_mobile_title_ui():
	var screen_size = get_viewport().get_visible_rect().size
	var base_font = max(32, int(screen_size.y * 0.04))  # Scale with screen
	var button_height = max(80, int(screen_size.y * 0.1))
	var input_height = max(80, int(screen_size.y * 0.1))
	
	# Main menu buttons - properly sized
	single_player_btn.custom_minimum_size = Vector2(min(400, screen_size.x * 0.8), button_height)
	multiplayer_btn.custom_minimum_size = Vector2(min(400, screen_size.x * 0.8), button_height)
	settings_btn.custom_minimum_size = Vector2(min(400, screen_size.x * 0.8), button_height)
	quit_btn.custom_minimum_size = Vector2(min(400, screen_size.x * 0.8), button_height)
	
	# Input field - properly sized
	player_name_input.custom_minimum_size = Vector2(0, input_height)
	player_name_input.add_theme_font_size_override("font_size", base_font)
	
	# Multiplayer panel - scale to screen
	var panel_width = min(500, screen_size.x * 0.9)
	multiplayer_panel.offset_left = -panel_width / 2
	multiplayer_panel.offset_right = panel_width / 2
	multiplayer_panel.offset_top = -min(400, screen_size.y * 0.5)
	multiplayer_panel.offset_bottom = min(400, screen_size.y * 0.5)
	
	# Multiplayer panel buttons - properly sized
	quick_match_btn.custom_minimum_size = Vector2(0, button_height)
	online_host_btn.custom_minimum_size = Vector2(0, button_height)
	online_join_btn.custom_minimum_size = Vector2(0, button_height)
	host_btn.custom_minimum_size = Vector2(0, button_height)
	join_btn.custom_minimum_size = Vector2(0, button_height)
	start_game_btn.custom_minimum_size = Vector2(0, button_height)
	cancel_btn.custom_minimum_size = Vector2(0, button_height)
	back_btn.custom_minimum_size = Vector2(0, button_height)
	online_join_connect_btn.custom_minimum_size = Vector2(0, button_height)
	join_connect_btn.custom_minimum_size = Vector2(0, button_height)
	copy_match_id_btn.custom_minimum_size = Vector2(0, button_height * 0.8)
	copy_code_btn.custom_minimum_size = Vector2(0, button_height * 0.8)
	settings_close.custom_minimum_size = Vector2(0, button_height * 0.8)
	
	# Input fields - properly sized to fit text
	online_match_id_input.custom_minimum_size = Vector2(0, input_height)
	online_match_id_input.add_theme_font_size_override("font_size", base_font)
	join_code_input.custom_minimum_size = Vector2(0, input_height)
	join_code_input.add_theme_font_size_override("font_size", base_font)
	
	# Labels - properly sized
	var title_label = multiplayer_panel.get_node_or_null("VBoxContainer/Title")
	if title_label:
		title_label.add_theme_font_size_override("font_size", base_font + 8)
	
	var name_label = multiplayer_panel.get_node_or_null("VBoxContainer/NameContainer/NameLabel")
	if name_label:
		name_label.add_theme_font_size_override("font_size", base_font)
		name_label.custom_minimum_size = Vector2(80, 0)
	
	var mode_label = multiplayer_panel.get_node_or_null("VBoxContainer/ModeLabel")
	if mode_label:
		mode_label.add_theme_font_size_override("font_size", base_font - 4)
	
	var lan_label = multiplayer_panel.get_node_or_null("VBoxContainer/LanLabel")
	if lan_label:
		lan_label.add_theme_font_size_override("font_size", base_font - 4)
	
	# Font sizes - properly sized
	single_player_btn.add_theme_font_size_override("font_size", base_font)
	multiplayer_btn.add_theme_font_size_override("font_size", base_font)
	settings_btn.add_theme_font_size_override("font_size", base_font)
	quit_btn.add_theme_font_size_override("font_size", base_font)
	status_label.add_theme_font_size_override("font_size", base_font - 4)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	match_id_value.add_theme_font_size_override("font_size", base_font)
	room_code_display.add_theme_font_size_override("font_size", base_font + 4)
	
	# Match ID and Room Code labels
	var match_id_label = multiplayer_panel.get_node_or_null("VBoxContainer/OnlineMatchIdContainer/MatchIdLabel")
	if match_id_label:
		match_id_label.add_theme_font_size_override("font_size", base_font)
	
	var room_code_label = multiplayer_panel.get_node_or_null("VBoxContainer/RoomCodeContainer/RoomCodeLabel")
	if room_code_label:
		room_code_label.add_theme_font_size_override("font_size", base_font + 4)
	
	# Waiting label
	if waiting_label:
		waiting_label.add_theme_font_size_override("font_size", base_font - 4)
	
	# Increase font sizes for all clickable buttons to fill their boxes
	quick_match_btn.add_theme_font_size_override("font_size", base_font)
	online_host_btn.add_theme_font_size_override("font_size", base_font)
	online_join_btn.add_theme_font_size_override("font_size", base_font)
	host_btn.add_theme_font_size_override("font_size", base_font)
	join_btn.add_theme_font_size_override("font_size", base_font)
	start_game_btn.add_theme_font_size_override("font_size", base_font)
	cancel_btn.add_theme_font_size_override("font_size", base_font)
	back_btn.add_theme_font_size_override("font_size", base_font)
	online_join_connect_btn.add_theme_font_size_override("font_size", base_font)
	join_connect_btn.add_theme_font_size_override("font_size", base_font)
	copy_match_id_btn.add_theme_font_size_override("font_size", base_font - 4)
	copy_code_btn.add_theme_font_size_override("font_size", base_font - 4)

func _setup_title_font():
	# Apply magical font to all title instances
	if title_label:
		# Make it more magical with gradient-like colors and outline
		title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))  # Bright gold
		title_label.add_theme_color_override("font_outline_color", Color(0.9, 0.4, 1.0))  # Bright purple outline
		title_label.add_theme_color_override("font_shadow_color", Color(0.6, 0.2, 0.8, 0.8))  # Purple shadow
		title_label.add_theme_constant_override("outline_size", 6)  # Thicker outline
		title_label.add_theme_constant_override("shadow_offset_x", 4)
		title_label.add_theme_constant_override("shadow_offset_y", 4)
		title_label.add_theme_constant_override("shadow_outline_size", 8)
	
	# Also apply to multiplayer panel title
	var mp_title = multiplayer_panel.get_node_or_null("VBoxContainer/Title")
	if mp_title:
		mp_title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
		mp_title.add_theme_color_override("font_outline_color", Color(0.9, 0.4, 1.0))
		mp_title.add_theme_color_override("font_shadow_color", Color(0.6, 0.2, 0.8, 0.8))
		mp_title.add_theme_constant_override("outline_size", 4)
		mp_title.add_theme_constant_override("shadow_offset_x", 2)
		mp_title.add_theme_constant_override("shadow_offset_y", 2)
		mp_title.add_theme_constant_override("shadow_outline_size", 4)
	
	# Also apply to settings panel title
	var settings_title = settings_panel.get_node_or_null("VBoxContainer/TitleLabel")
	if settings_title:
		settings_title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
		settings_title.add_theme_color_override("font_outline_color", Color(0.9, 0.4, 1.0))
		settings_title.add_theme_constant_override("outline_size", 4)

func _setup_mobile_title_text():
	# Make title fit screen size on mobile (not too large)
	if title_label:
		var screen_size = get_viewport().get_visible_rect().size
		var title_font_size = max(48, int(screen_size.y * 0.10))  # 10% of screen height, min 48px - FITS SCREEN
		title_label.add_theme_font_size_override("font_size", title_font_size)
		title_label.custom_minimum_size = Vector2(0, title_font_size + 20)

func _setup_paste_support():
	# Enable paste via Ctrl+V / Cmd+V for input fields
	# This is handled automatically by LineEdit, but we can add visual feedback
	if online_match_id_input:
		var paste_hint = "Tap Paste button or Ctrl+V" if _is_mobile_web() else "Ctrl+V to paste"
		online_match_id_input.placeholder_text = "Enter Match ID (" + paste_hint + ")"
	if join_code_input:
		var paste_hint = "Tap Paste button or Ctrl+V" if _is_mobile_web() else "Ctrl+V to paste"
		join_code_input.placeholder_text = "Enter Room Code (" + paste_hint + ")"
	
	# Add paste button for both mobile and browser
	_add_paste_button_to_input(online_match_id_input, online_join_container)
	_add_paste_button_to_input(join_code_input, join_container)

func _add_paste_button_to_input(input_field: LineEdit, container: HBoxContainer):
	if not input_field or not container:
		return
	
	# Check if paste button already exists
	for child in container.get_children():
		if child.name == "PasteButton":
			return
	
	# Create paste button
	var paste_btn = Button.new()
	paste_btn.name = "PasteButton"
	paste_btn.text = "📋 Paste"
	paste_btn.custom_minimum_size = Vector2(100, 0)
	paste_btn.pressed.connect(_on_paste_button_pressed.bind(input_field))
	container.add_child(paste_btn)

func _on_paste_button_pressed(input_field: LineEdit):
	# Focus the input field first - this is required for paste to work
	input_field.grab_focus()
	input_field.select_all()
	
	# For web (both browser and mobile), use clipboard API with proper async handling
	if Engine.has_singleton("JavaScriptBridge"):
		# Initialize result storage
		var js_init = """
		(function() {
			window._godot_paste_result = null;
			window._godot_paste_done = false;
			return 'init';
		})();
		"""
		JavaScriptBridge.eval(js_init, true)
		
		# Use clipboard API - this works with user gesture (button click)
		var js_clipboard = """
		(function() {
			if (navigator.clipboard && navigator.clipboard.readText) {
				navigator.clipboard.readText().then(function(text) {
					window._godot_paste_result = text || '';
					window._godot_paste_done = true;
				}).catch(function(err) {
					window._godot_paste_result = '';
					window._godot_paste_done = true;
				});
			} else {
				window._godot_paste_done = true;
			}
			return 'started';
		})();
		"""
		JavaScriptBridge.eval(js_clipboard, true)
		
		# Poll for result with proper async waiting
		var clipboard_text = ""
		for i in range(40):  # 40 × 25ms = 1 second max wait
			await get_tree().create_timer(0.025).timeout
			var js_check = """
			(function() {
				if (window._godot_paste_done) {
					var text = window._godot_paste_result || '';
					window._godot_paste_result = null;
					window._godot_paste_done = false;
					return text;
				}
				return '';
			})();
			"""
			var result = JavaScriptBridge.eval(js_check, true)
			if result and result != "":
				clipboard_text = result
				break
		
		# If clipboard API didn't work, try execCommand as fallback
		if not clipboard_text or clipboard_text == "":
			var js_exec = """
			(function() {
				var textarea = document.createElement('textarea');
				textarea.style.position = 'fixed';
				textarea.style.left = '0';
				textarea.style.top = '0';
				textarea.style.width = '1px';
				textarea.style.height = '1px';
				textarea.style.opacity = '0';
				textarea.style.pointerEvents = 'none';
				document.body.appendChild(textarea);
				textarea.focus();
				try {
					var pasted = document.execCommand('paste');
					var text = textarea.value || '';
					document.body.removeChild(textarea);
					return text;
				} catch (e) {
					document.body.removeChild(textarea);
					return '';
				}
			})();
			"""
			clipboard_text = JavaScriptBridge.eval(js_exec, true)
		
		if clipboard_text and clipboard_text != "":
			# Clean and set the text
			var clean_text = clipboard_text.strip_edges()
			input_field.text = clean_text
			status_label.text = "Pasted: " + clean_text.substr(0, 25)
			status_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
			await get_tree().create_timer(2.0).timeout
			status_label.text = ""
		else:
			# Show instruction
			input_field.grab_focus()
			input_field.select_all()
			if _is_mobile_web():
				status_label.text = "Long-press in field, select Paste"
			else:
				status_label.text = "Use Ctrl+V / Cmd+V to paste"
			status_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
			await get_tree().create_timer(3.0).timeout
			status_label.text = ""
	elif DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		var clipboard_text = DisplayServer.clipboard_get()
		if clipboard_text:
			input_field.text = clipboard_text.strip_edges()
			status_label.text = "Pasted from clipboard"
			status_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
			await get_tree().create_timer(2.0).timeout
			status_label.text = ""

func _connect_nakama_signals():
	await get_tree().process_frame
	
	var nakama = get_node_or_null("/root/NakamaManager")
	if nakama:
		nakama.authenticated.connect(_on_nakama_authenticated)
		nakama.authentication_failed.connect(_on_nakama_auth_failed)
		nakama.socket_connected.connect(_on_nakama_socket_connected)
		nakama.socket_connection_failed.connect(_on_nakama_socket_failed)
		nakama.matchmaking_started.connect(_on_nakama_matchmaking_started)
		nakama.matchmaking_cancelled.connect(_on_nakama_matchmaking_cancelled)
		nakama.match_found.connect(_on_nakama_match_found)
		nakama.match_joined.connect(_on_nakama_match_joined)
		nakama.match_join_failed.connect(_on_nakama_match_join_failed)
		nakama.player_joined.connect(_on_nakama_player_joined)
		nakama.player_left.connect(_on_nakama_player_left)
		print("[TitleScreen] Connected to NakamaManager signals")

func _setup_settings_panel():
	theme_option.clear()
	var themes = SettingsManager.get_theme_names()
	var current_idx = 0
	for i in range(themes.size()):
		theme_option.add_item(themes[i]["name"], i)
		theme_option.set_item_metadata(i, themes[i]["id"])
		if themes[i]["id"] == SettingsManager.current_theme:
			current_idx = i
	theme_option.select(current_idx)
	animations_check.button_pressed = SettingsManager.animations_enabled

func _style_panels():
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.12, 0.2, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.4, 0.3, 0.5)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(4, 4)
	panel_style.content_margin_left = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 15
	panel_style.content_margin_bottom = 15
	
	multiplayer_panel.add_theme_stylebox_override("panel", panel_style)
	settings_panel.add_theme_stylebox_override("panel", panel_style.duplicate())

func _apply_theme():
	var theme = SettingsManager.get_theme()
	background.color = theme["background"]
	background_pattern.color = theme["background_pattern"]

func _reset_multiplayer_ui():
	room_code_container.visible = false
	join_container.visible = false
	online_match_id_container.visible = false
	online_join_container.visible = false
	start_game_btn.visible = false
	waiting_label.visible = false
	cancel_btn.visible = false
	
	host_btn.disabled = false
	join_btn.disabled = false
	quick_match_btn.disabled = false
	online_host_btn.disabled = false
	online_join_btn.disabled = false
	join_connect_btn.disabled = false
	online_join_connect_btn.disabled = false
	
	status_label.text = ""
	is_matchmaking = false
	is_online_mode = false

# ============================================
# MAIN MENU
# ============================================

func _on_single_player():
	NetworkManager.is_multiplayer = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_multiplayer():
	multiplayer_panel.visible = true

func _on_settings():
	settings_panel.visible = true

func _on_quit():
	get_tree().quit()

# ============================================
# ONLINE PLAY - Quick Match
# ============================================

func _on_quick_match():
	is_online_mode = true
	is_host = false
	
	# Auto-generate random name if empty
	var player_name = player_name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player_" + str(randi() % 100000)
		player_name_input.text = player_name  # Update UI so user sees their name
	
	status_label.text = "Connecting to server..."
	status_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	_disable_all_buttons()
	cancel_btn.visible = true
	
	# Start online multiplayer
	var success = await NetworkManager.start_online_multiplayer(player_name)
	if not success:
		status_label.text = "Failed to connect to server"
		status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		_enable_all_buttons()
		cancel_btn.visible = false
		return
	
	# Start matchmaking
	status_label.text = "Searching for opponent..."
	is_matchmaking = true
	
	success = await NetworkManager.start_online_matchmaking()
	if not success:
		status_label.text = "Failed to start matchmaking"
		status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		_enable_all_buttons()
		cancel_btn.visible = false
		is_matchmaking = false

# ============================================
# ONLINE PLAY - Create Room
# ============================================

func _on_online_host():
	is_online_mode = true
	is_host = true
	
	var player_name = player_name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Host"
	
	status_label.text = "Connecting to server..."
	status_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	_disable_all_buttons()
	cancel_btn.visible = true
	
	# Start online multiplayer
	var success = await NetworkManager.start_online_multiplayer(player_name)
	if not success:
		status_label.text = "Failed to connect to server"
		status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		_enable_all_buttons()
		cancel_btn.visible = false
		return
	
	# Create match
	status_label.text = "Creating room..."
	success = await NetworkManager.create_online_match()
	if not success:
		status_label.text = "Failed to create room"
		status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		_enable_all_buttons()
		cancel_btn.visible = false

# ============================================
# ONLINE PLAY - Join Room
# ============================================

func _on_online_join():
	is_online_mode = true
	is_host = false
	
	var player_name = player_name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	
	online_join_container.visible = true
	_disable_all_buttons()
	online_join_connect_btn.disabled = false
	cancel_btn.visible = true
	
	status_label.text = "Enter the Match ID to join"
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func _on_online_join_connect():
	var match_id = online_match_id_input.text.strip_edges()
	if match_id.is_empty():
		status_label.text = "Please enter a Match ID"
		status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		return
	
	var player_name = player_name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	
	status_label.text = "Connecting to server..."
	status_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	online_join_connect_btn.disabled = true
	
	# Start online multiplayer
	var success = await NetworkManager.start_online_multiplayer(player_name)
	if not success:
		status_label.text = "Failed to connect to server"
		status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		online_join_connect_btn.disabled = false
		return
	
	# Join match
	status_label.text = "Joining room..."
	success = await NetworkManager.join_online_match(match_id)
	if not success:
		status_label.text = "Failed to join room - check Match ID"
		status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		online_join_connect_btn.disabled = false

func _on_copy_match_id():
	var nakama = get_node_or_null("/root/NakamaManager")
	if nakama and nakama.current_match_id:
		var match_id = nakama.current_match_id
		
		# Try web clipboard API first (works in browsers)
		if Engine.has_singleton("JavaScriptBridge"):
			var js_code = """
			(async function() {
				try {
					await navigator.clipboard.writeText('%s');
					return 'success';
				} catch (err) {
					// Fallback: select text in a temporary element
					var textarea = document.createElement('textarea');
					textarea.value = '%s';
					textarea.style.position = 'fixed';
					textarea.style.opacity = '0';
					document.body.appendChild(textarea);
					textarea.select();
					try {
						document.execCommand('copy');
						document.body.removeChild(textarea);
						return 'success';
					} catch (e) {
						document.body.removeChild(textarea);
						return 'failed';
					}
				}
			})();
			""" % [match_id, match_id]
			var result = JavaScriptBridge.eval(js_code, true)
			
			if result == "success":
				copy_match_id_btn.text = "Copied!"
				await get_tree().create_timer(1.5).timeout
				copy_match_id_btn.text = "📋 Copy"
				return
		
		# Desktop fallback
		if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
			DisplayServer.clipboard_set(match_id)
			copy_match_id_btn.text = "Copied!"
			await get_tree().create_timer(1.5).timeout
			copy_match_id_btn.text = "📋 Copy"
		else:
			# Last resort: show the ID prominently and select it
			match_id_value.text = match_id
			match_id_value.add_theme_color_override("font_color", Color(1, 1, 0.5))
			copy_match_id_btn.text = "Tap ID to copy"

# ============================================
# NAKAMA CALLBACKS
# ============================================

func _on_nakama_authenticated():
	print("[TitleScreen] Nakama authenticated")

func _on_nakama_auth_failed(error: String):
	status_label.text = "Auth failed: " + error
	status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	_enable_all_buttons()
	cancel_btn.visible = false

func _on_nakama_socket_connected():
	print("[TitleScreen] Nakama socket connected")

func _on_nakama_socket_failed(error: String):
	status_label.text = "Connection failed: " + error
	status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	_enable_all_buttons()
	cancel_btn.visible = false

func _on_nakama_matchmaking_started():
	status_label.text = "Searching for opponent..."
	status_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	waiting_label.visible = true
	waiting_label.text = "This may take a moment..."

func _on_nakama_matchmaking_cancelled():
	status_label.text = "Matchmaking cancelled"
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_enable_all_buttons()
	cancel_btn.visible = false
	waiting_label.visible = false
	is_matchmaking = false

func _on_nakama_match_found(match_id: String):
	print("[TitleScreen] Match found: ", match_id)

func _on_nakama_match_joined(match_data: Dictionary):
	print("[TitleScreen] Joined match: ", match_data)
	is_host = match_data.get("is_host", false)
	
	var nakama = get_node_or_null("/root/NakamaManager")
	
	if is_host and not is_matchmaking:
		# Show match ID for others to join
		online_match_id_container.visible = true
		if nakama:
			match_id_value.text = nakama.get_short_match_id()
		status_label.text = "Room created! Share the Match ID"
		status_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
		waiting_label.visible = true
		waiting_label.text = "Waiting for opponent to join..."
	else:
		# We joined someone else's match or via matchmaking
		var opponent = match_data.get("opponent")
		if opponent:
			var opponent_name = opponent.username if opponent.username else "Opponent"
			status_label.text = "Matched with " + opponent_name + "!"
			status_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
			
			if is_matchmaking:
				# Auto-start for matchmaking
				if is_host:
					await get_tree().create_timer(0.5).timeout
					NetworkManager.start_multiplayer_game_as_host()

func _on_nakama_match_join_failed(error: String):
	status_label.text = "Failed to join: " + error
	status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	_enable_all_buttons()
	cancel_btn.visible = false
	waiting_label.visible = false

func _on_nakama_player_joined(presence: Dictionary):
	var opponent_name = presence.get("username", "Opponent")
	status_label.text = opponent_name + " joined!"
	status_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	waiting_label.visible = false
	
	if is_host:
		start_game_btn.visible = true
	else:
		waiting_label.visible = true
		waiting_label.text = "Waiting for host to start..."

func _on_nakama_player_left(presence: Dictionary):
	status_label.text = "Opponent disconnected"
	status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	start_game_btn.visible = false
	waiting_label.visible = true
	waiting_label.text = "Waiting for opponent..."

# ============================================
# LAN PLAY - Host
# ============================================

func _on_host():
	is_host = true
	is_online_mode = false
	
	var player_name = player_name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Host"
	NetworkManager.local_player_name = player_name
	
	var result = NetworkManager.host_game(player_name)
	if result == OK:
		var room_code = NetworkManager.generate_room_code()
		room_code_display.text = room_code
		room_code_container.visible = true
		join_container.visible = false
		host_btn.disabled = true
		join_btn.disabled = true
		online_host_btn.disabled = true
		online_join_btn.disabled = true
		quick_match_btn.disabled = true
		cancel_btn.visible = true
		status_label.text = "Waiting for opponent..."
		status_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	else:
		status_label.text = "Failed to create game"
		status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))

# ============================================
# LAN PLAY - Join
# ============================================

func _on_join():
	is_host = false
	is_online_mode = false
	
	var player_name = player_name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	NetworkManager.local_player_name = player_name
	
	join_container.visible = true
	room_code_container.visible = false
	host_btn.disabled = true
	join_btn.disabled = true
	online_host_btn.disabled = true
	online_join_btn.disabled = true
	quick_match_btn.disabled = true
	cancel_btn.visible = true
	status_label.text = "Enter room code to join"
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func _on_join_connect():
	var room_code = join_code_input.text.strip_edges().to_upper()
	if room_code.is_empty():
		status_label.text = "Please enter a room code"
		status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		return
	
	var result = NetworkManager.join_with_code(NetworkManager.local_player_name, room_code)
	if result != OK:
		status_label.text = "Invalid code format"
		status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	else:
		status_label.text = "Connecting..."
		status_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
		join_connect_btn.disabled = true

func _on_copy_code():
	var room_code = room_code_display.text
	
	# Try web clipboard API first (works in browsers)
	if Engine.has_singleton("JavaScriptBridge"):
		var js_code = """
		(async function() {
			try {
				await navigator.clipboard.writeText('%s');
				return 'success';
			} catch (err) {
				// Fallback: select text in a temporary element
				var textarea = document.createElement('textarea');
				textarea.value = '%s';
				textarea.style.position = 'fixed';
				textarea.style.opacity = '0';
				document.body.appendChild(textarea);
				textarea.select();
				try {
					document.execCommand('copy');
					document.body.removeChild(textarea);
					return 'success';
				} catch (e) {
					document.body.removeChild(textarea);
					return 'failed';
				}
			}
		})();
		""" % [room_code, room_code]
		var result = JavaScriptBridge.eval(js_code, true)
		
		if result == "success":
			copy_code_btn.text = "Copied!"
			await get_tree().create_timer(1.5).timeout
			copy_code_btn.text = "📋 Copy"
			return
	
	# Desktop fallback
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set(room_code)
		copy_code_btn.text = "Copied!"
		await get_tree().create_timer(1.5).timeout
		copy_code_btn.text = "📋 Copy"
	else:
		# Last resort: highlight the code
		room_code_display.add_theme_color_override("font_color", Color(1, 1, 0.5))
		copy_code_btn.text = "Tap code to copy"

# ============================================
# COMMON CALLBACKS
# ============================================

func _on_start_game():
	if NetworkManager.opponent_id != 0 or (is_online_mode and get_node_or_null("/root/NakamaManager") and get_node_or_null("/root/NakamaManager").opponent_presence):
		NetworkManager.start_multiplayer_game_as_host()
	else:
		status_label.text = "Waiting for opponent to connect..."
		status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))

func _on_cancel():
	if is_matchmaking:
		NetworkManager.cancel_online_matchmaking()
	else:
		NetworkManager.disconnect_from_game()
	_reset_multiplayer_ui()

func _on_back():
	NetworkManager.disconnect_from_game()
	multiplayer_panel.visible = false
	_reset_multiplayer_ui()

func _disable_all_buttons():
	host_btn.disabled = true
	join_btn.disabled = true
	quick_match_btn.disabled = true
	online_host_btn.disabled = true
	online_join_btn.disabled = true
	join_connect_btn.disabled = true
	online_join_connect_btn.disabled = true

func _enable_all_buttons():
	host_btn.disabled = false
	join_btn.disabled = false
	quick_match_btn.disabled = false
	online_host_btn.disabled = false
	online_join_btn.disabled = false
	join_connect_btn.disabled = false
	online_join_connect_btn.disabled = false

# LAN connection callbacks
func _on_connection_succeeded():
	status_label.text = "Connected! Waiting for host to start..."
	status_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	waiting_label.visible = true
	waiting_label.text = "Waiting for host to start the game..."

func _on_connection_failed():
	status_label.text = "Connection failed!"
	status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	_enable_all_buttons()
	cancel_btn.visible = false

func _on_player_connected(id: int):
	if is_host and not is_online_mode:
		status_label.text = "Opponent connected: " + NetworkManager.opponent_name
		status_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
		start_game_btn.visible = true

func _on_player_disconnected(id: int):
	status_label.text = "Opponent disconnected"
	status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	start_game_btn.visible = false

func _on_game_started():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# Settings
func _on_settings_close():
	settings_panel.visible = false

func _on_theme_selected(index: int):
	var theme_id = theme_option.get_item_metadata(index)
	SettingsManager.set_theme(theme_id)

func _on_animations_toggled(enabled: bool):
	SettingsManager.set_animations(enabled)
