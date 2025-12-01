extends Control

# Card scene for instantiation
var CardScene = preload("res://scenes/Card.tscn")

# UI References - Player area
@onready var player_hand_container: HBoxContainer = $GameLayout/MainArea/PlayArea/PlayerArea/PlayerHand
@onready var player_field_container: HBoxContainer = $GameLayout/MainArea/PlayArea/PlayerArea/FieldAndCards/PlayerField
@onready var player_deck_display: Control = $GameLayout/MainArea/PlayArea/PlayerArea/FieldAndCards/PlayerCards/PlayerDeckArea/PlayerDeckDisplay
@onready var player_deck_count: Label = $GameLayout/MainArea/PlayArea/PlayerArea/FieldAndCards/PlayerCards/PlayerDeckArea/PlayerDeckCount
@onready var player_discard_area: VBoxContainer = $GameLayout/MainArea/PlayArea/PlayerArea/FieldAndCards/PlayerCards/PlayerDiscardArea
@onready var player_discard_container: VBoxContainer = $GameLayout/MainArea/PlayArea/PlayerArea/FieldAndCards/PlayerCards/PlayerDiscardArea/PlayerDiscard
@onready var player_discard_count: Label = $GameLayout/MainArea/PlayArea/PlayerArea/FieldAndCards/PlayerCards/PlayerDiscardArea/PlayerDiscardCount
@onready var player_label: Label = $GameLayout/MainArea/PlayArea/PlayerArea/PlayerLabelContainer/PlayerLabel
@onready var player_turn_indicator: Label = $GameLayout/MainArea/PlayArea/PlayerArea/PlayerLabelContainer/PlayerTurnIndicator

# UI References - Opponent area
@onready var opponent_label: Label = $GameLayout/MainArea/PlayArea/AIArea/AILabelContainer/AILabel
@onready var opponent_turn_indicator: Label = $GameLayout/MainArea/PlayArea/AIArea/AILabelContainer/AITurnIndicator
@onready var ai_field_container: HBoxContainer = $GameLayout/MainArea/PlayArea/AIArea/FieldAndCards/AIField
@onready var ai_hand_container: HBoxContainer = $GameLayout/MainArea/PlayArea/AIArea/AIHand
@onready var ai_deck_display: Control = $GameLayout/MainArea/PlayArea/AIArea/FieldAndCards/AICards/AIDeckArea/AIDeckDisplay
@onready var ai_deck_count: Label = $GameLayout/MainArea/PlayArea/AIArea/FieldAndCards/AICards/AIDeckArea/AIDeckCount
@onready var ai_discard_area: VBoxContainer = $GameLayout/MainArea/PlayArea/AIArea/FieldAndCards/AICards/AIDiscardArea
@onready var ai_discard_container: VBoxContainer = $GameLayout/MainArea/PlayArea/AIArea/FieldAndCards/AICards/AIDiscardArea/AIDiscard
@onready var ai_discard_count: Label = $GameLayout/MainArea/PlayArea/AIArea/FieldAndCards/AICards/AIDiscardArea/AIDiscardCount

# UI References - Drop Zone
@onready var drop_zone: Panel = $DropZone

# UI References - Side Panels
@onready var log_panel: PanelContainer = $GameLayout/MainArea/SidePanels/LogPanel
@onready var log_header: Button = $GameLayout/MainArea/SidePanels/LogPanel/LogContainer/LogHeader
@onready var log_scroll: ScrollContainer = $GameLayout/MainArea/SidePanels/LogPanel/LogContainer/LogScroll
@onready var log_content: VBoxContainer = $GameLayout/MainArea/SidePanels/LogPanel/LogContainer/LogScroll/LogContent
@onready var rules_panel: PanelContainer = $GameLayout/MainArea/SidePanels/RulesPanel
@onready var rules_header: Button = $GameLayout/MainArea/SidePanels/RulesPanel/RulesContainer/RulesHeader
@onready var rules_scroll: ScrollContainer = $GameLayout/MainArea/SidePanels/RulesPanel/RulesContainer/RulesScroll
@onready var rules_content: VBoxContainer = $GameLayout/MainArea/SidePanels/RulesPanel/RulesContainer/RulesScroll/RulesContent

# UI References - Backgrounds
@onready var background: ColorRect = $Background
@onready var background_pattern: ColorRect = $BackgroundPattern

# UI References - Panels
@onready var message_label: Label = $GameLayout/TopBar/MessagePanel/MessageLabel
@onready var reaction_panel: PanelContainer = $ReactionPanel
@onready var reaction_label: Label = $ReactionPanel/VBoxContainer/ReactionLabel
@onready var reaction_timer_bar: ProgressBar = $ReactionPanel/VBoxContainer/ReactionTimerBar
@onready var react_button: Button = $ReactionPanel/VBoxContainer/ButtonContainer/ReactButton
@onready var pass_button: Button = $ReactionPanel/VBoxContainer/ButtonContainer/PassButton
@onready var effect_panel: PanelContainer = $EffectPanel
@onready var effect_label: Label = $EffectPanel/VBoxContainer/EffectLabel
@onready var effect_options: VBoxContainer = $EffectPanel/VBoxContainer/EffectOptions
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/VBoxContainer/GameOverLabel
@onready var play_again_button: Button = $GameOverPanel/VBoxContainer/PlayAgainButton
@onready var rematch_button: Button = $GameOverPanel/VBoxContainer/RematchButton
@onready var rematch_status: Label = $GameOverPanel/VBoxContainer/RematchStatus
@onready var main_menu_button: Button = $GameOverPanel/VBoxContainer/MainMenuButton
@onready var new_game_button: Button = $GameLayout/TopBar/NewGameButton
@onready var settings_button: Button = $GameLayout/TopBar/SettingsButton
@onready var back_button: Button = $GameLayout/TopBar/BackButton
@onready var discard_view_panel: PanelContainer = $DiscardViewPanel
@onready var discard_view_title: Label = $DiscardViewPanel/VBoxContainer/DiscardViewTitle
@onready var discard_view_cards: VBoxContainer = $DiscardViewPanel/VBoxContainer/ScrollContainer/DiscardViewCards
@onready var discard_view_close: Button = $DiscardViewPanel/VBoxContainer/CloseButton
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var settings_close: Button = $SettingsPanel/VBoxContainer/CloseButton
@onready var theme_option: OptionButton = $SettingsPanel/VBoxContainer/ThemeContainer/ThemeOption
@onready var animations_check: CheckBox = $SettingsPanel/VBoxContainer/AnimationsCheck

# In-game menu
@onready var game_menu_panel: PanelContainer = $GameMenuPanel
@onready var menu_button: Button = $GameLayout/TopBar/MenuButton
@onready var resume_button: Button = $GameMenuPanel/VBoxContainer/ResumeButton
@onready var menu_animations_check: CheckBox = $GameMenuPanel/VBoxContainer/AnimationsCheck
@onready var menu_theme_option: OptionButton = $GameMenuPanel/VBoxContainer/ThemeContainer/ThemeOption
@onready var menu_main_menu_button: Button = $GameMenuPanel/VBoxContainer/MainMenuButton
@onready var menu_rules_scroll: ScrollContainer = $GameMenuPanel/VBoxContainer/RulesScroll
@onready var menu_rules_content: VBoxContainer = $GameMenuPanel/VBoxContainer/RulesScroll/RulesContent

# State tracking
var reaction_timer: float = 0.0
var reaction_active: bool = false
var current_effect: String = ""
var effect_targets: Array = []
var log_expanded: bool = true
var rules_expanded: bool = false
const MAX_LOG_ENTRIES = 50

# Drag and drop state
var dragging_card: Control = null
var dragging_card_index: int = -1

func _ready():
	# Connect GameManager signals
	GameManager.hand_updated.connect(_on_hand_updated)
	GameManager.field_updated.connect(_on_field_updated)
	GameManager.deck_updated.connect(_on_deck_updated)
	GameManager.discard_updated.connect(_on_discard_updated)
	GameManager.message_updated.connect(_on_message_updated)
	GameManager.reaction_window_started.connect(_on_reaction_window_started)
	GameManager.reaction_window_ended.connect(_on_reaction_window_ended)
	GameManager.game_over.connect(_on_game_over)
	GameManager.effect_target_needed.connect(_on_effect_target_needed)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.all_visuals_reset.connect(_on_all_visuals_reset)
	GameManager.card_resolved.connect(_on_card_resolved)
	GameManager.card_blocked.connect(_on_card_blocked)
	GameManager.fire_effect_triggered.connect(_on_fire_effect_triggered)
	GameManager.darkness_effect_triggered.connect(_on_darkness_effect_triggered)
	GameManager.grass_effect_triggered.connect(_on_grass_effect_triggered)
	GameManager.lightning_effect_triggered.connect(_on_lightning_effect_triggered)
	
	# Connect NetworkManager signals
	NetworkManager.rematch_requested.connect(_on_rematch_requested)
	NetworkManager.game_started.connect(_on_network_game_started)
	
	# Connect SettingsManager
	SettingsManager.settings_changed.connect(_apply_theme)
	
	# Connect UI buttons
	react_button.pressed.connect(_on_react_pressed)
	pass_button.pressed.connect(_on_pass_pressed)
	play_again_button.pressed.connect(_on_play_again_pressed)
	rematch_button.pressed.connect(_on_rematch_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	back_button.pressed.connect(_on_back_pressed)
	discard_view_close.pressed.connect(_on_discard_view_close)
	log_header.pressed.connect(_on_log_header_pressed)
	rules_header.pressed.connect(_on_rules_header_pressed)
	settings_close.pressed.connect(_on_settings_close)
	theme_option.item_selected.connect(_on_theme_selected)
	animations_check.toggled.connect(_on_animations_toggled)
	
	# In-game menu buttons
	menu_button.pressed.connect(_on_menu_button_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	menu_animations_check.toggled.connect(_on_menu_animations_toggled)
	menu_theme_option.item_selected.connect(_on_menu_theme_selected)
	menu_main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Hide panels
	reaction_panel.visible = false
	effect_panel.visible = false
	game_over_panel.visible = false
	discard_view_panel.visible = false
	settings_panel.visible = false
	drop_zone.visible = false
	game_menu_panel.visible = false
	
	# Initialize panels
	log_expanded = true
	rules_expanded = false
	_update_log_visibility()
	_update_rules_visibility()
	_populate_rules()
	_setup_settings_panel()
	_setup_game_menu()
	_setup_drop_zone()
	_style_panels()
	
	# Apply theme
	_apply_theme()
	
	# Update labels
	_update_labels_for_game_mode()
	
	# Mobile web optimizations
	if _is_mobile_web():
		_setup_mobile_ui()
		_setup_fixed_field_size()
	
	# Start game
	await get_tree().create_timer(0.3).timeout
	
	if NetworkManager.is_multiplayer:
		NetworkManager.initialize_multiplayer_game()
	else:
		GameManager.start_new_game()

func _is_mobile_web() -> bool:
	# Detect if running in mobile browser
	if not Engine.has_singleton("JavaScriptBridge"):
		return false
	
	var user_agent = JavaScriptBridge.eval("navigator.userAgent", true)
	if user_agent:
		var ua_lower = user_agent.to_lower()
		return "mobile" in ua_lower or "android" in ua_lower or "iphone" in ua_lower or "ipad" in ua_lower
	return false

func _setup_mobile_ui():
	# Scale down cards for mobile (handled in create_card_stack)
	# Increase button sizes for touch - larger for better visibility
	menu_button.custom_minimum_size = Vector2(120, 60)
	new_game_button.custom_minimum_size = Vector2(140, 60)
	settings_button.custom_minimum_size = Vector2(140, 60)
	react_button.custom_minimum_size = Vector2(140, 70)
	pass_button.custom_minimum_size = Vector2(140, 70)
	play_again_button.custom_minimum_size = Vector2(160, 70)
	rematch_button.custom_minimum_size = Vector2(160, 70)
	main_menu_button.custom_minimum_size = Vector2(160, 70)
	back_button.custom_minimum_size = Vector2(140, 60)
	resume_button.custom_minimum_size = Vector2(140, 60)
	menu_main_menu_button.custom_minimum_size = Vector2(160, 70)
	discard_view_close.custom_minimum_size = Vector2(140, 60)
	settings_close.custom_minimum_size = Vector2(140, 60)
	
	# Increase font sizes for readability - larger for mobile
	message_label.add_theme_font_size_override("font_size", 22)
	reaction_label.add_theme_font_size_override("font_size", 20)
	game_over_label.add_theme_font_size_override("font_size", 24)
	player_label.add_theme_font_size_override("font_size", 18)
	opponent_label.add_theme_font_size_override("font_size", 18)
	player_turn_indicator.add_theme_font_size_override("font_size", 16)
	opponent_turn_indicator.add_theme_font_size_override("font_size", 16)
	
	# Increase menu panel size and font sizes - make it fit screen better
	if game_menu_panel:
		var screen_size = get_viewport().get_visible_rect().size
		var panel_width = min(400, screen_size.x * 0.9)
		var panel_height = min(600, screen_size.y * 0.85)
		game_menu_panel.offset_left = -panel_width / 2
		game_menu_panel.offset_right = panel_width / 2
		game_menu_panel.offset_top = -panel_height / 2
		game_menu_panel.offset_bottom = panel_height / 2
		if menu_rules_scroll:
			menu_rules_scroll.custom_minimum_size = Vector2(0, min(200, screen_size.y * 0.3))
	
	# Hide side panels on mobile to save space
	log_panel.visible = false
	rules_panel.visible = false

func _setup_fixed_field_size():
	# Set fixed size for field containers on mobile to prevent resizing
	if not _is_mobile_web():
		return
	
	var screen_size = get_viewport().get_visible_rect().size
	# Calculate fixed field width to fit 5 cards
	# Account for: 5 cards + 4 spacers + margins
	var available_width = screen_size.x - 40  # Margins
	var spacing_width = 4 * 8  # 4 spacers, 8px each (minimum)
	var fixed_card_width = int((available_width - spacing_width) / 5)
	var fixed_field_width = 5 * fixed_card_width + 4 * 8  # Fixed width for 5 cards
	
	# Set fixed sizes for field containers
	if player_field_container:
		player_field_container.custom_minimum_size = Vector2(fixed_field_width, 0)
		player_field_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	if ai_field_container:
		ai_field_container.custom_minimum_size = Vector2(fixed_field_width, 0)
		ai_field_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	print("[Main] Fixed field width set to: ", fixed_field_width, " (card width: ", fixed_card_width, ")")

func _validate_ui_bounds():
	# Ensure all UI elements stay within screen bounds to prevent crashes
	if not is_instance_valid(get_viewport()):
		return
		
	var screen_size = get_viewport().get_visible_rect().size
	
	# Validate field containers and adjust if needed
	if is_instance_valid(player_field_container):
		var field_rect = player_field_container.get_global_rect()
		if field_rect.position.x < 0 or field_rect.position.x + field_rect.size.x > screen_size.x:
			print("[Main] WARNING: Player field out of bounds, adjusting...")
			# Adjust card sizes if needed
			call_deferred("refresh_player_field")
	
	if is_instance_valid(ai_field_container):
		var field_rect = ai_field_container.get_global_rect()
		if field_rect.position.x < 0 or field_rect.position.x + field_rect.size.x > screen_size.x:
			print("[Main] WARNING: AI field out of bounds, adjusting...")
			call_deferred("refresh_ai_field")
	
	# Validate hand containers
	if is_instance_valid(player_hand_container):
		var hand_rect = player_hand_container.get_global_rect()
		if hand_rect.position.x < 0 or hand_rect.position.x + hand_rect.size.x > screen_size.x:
			print("[Main] WARNING: Player hand out of bounds, adjusting...")
			call_deferred("refresh_player_hand")
	
	if is_instance_valid(ai_hand_container):
		var hand_rect = ai_hand_container.get_global_rect()
		if hand_rect.position.x < 0 or hand_rect.position.x + hand_rect.size.x > screen_size.x:
			print("[Main] WARNING: AI hand out of bounds, adjusting...")
			call_deferred("refresh_ai_hand")

func _setup_mobile_menu_fonts():
	# Increase font sizes in game menu for mobile - DOUBLE the sizes (100% larger)
	var screen_size = get_viewport().get_visible_rect().size
	var base_font_size = max(32, int(screen_size.y * 0.05))  # Doubled from 0.025
	var button_height = max(100, int(screen_size.y * 0.14))  # Doubled from 0.07
	
	if resume_button:
		resume_button.add_theme_font_size_override("font_size", base_font_size)
		resume_button.custom_minimum_size = Vector2(0, button_height)
	if menu_animations_check:
		menu_animations_check.add_theme_font_size_override("font_size", base_font_size - 4)
	if menu_main_menu_button:
		menu_main_menu_button.add_theme_font_size_override("font_size", base_font_size)
		menu_main_menu_button.custom_minimum_size = Vector2(0, button_height)
	
	# Update title and labels - doubled sizes
	var title_label = game_menu_panel.get_node_or_null("VBoxContainer/TitleLabel")
	if title_label:
		title_label.add_theme_font_size_override("font_size", base_font_size + 8)  # Doubled
	
	var settings_label = game_menu_panel.get_node_or_null("VBoxContainer/SettingsLabel")
	if settings_label:
		settings_label.add_theme_font_size_override("font_size", base_font_size + 4)  # Doubled
	
	var rules_label = game_menu_panel.get_node_or_null("VBoxContainer/RulesLabel")
	if rules_label:
		rules_label.add_theme_font_size_override("font_size", base_font_size + 4)  # Doubled
	
	# Update theme option font
	if menu_theme_option:
		menu_theme_option.add_theme_font_size_override("font_size", base_font_size - 2)

func _setup_drop_zone():
	# Style the drop zone
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.8, 0.3, 0.2)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.4, 1.0, 0.4, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	drop_zone.add_theme_stylebox_override("panel", style)

func _style_panels():
	# Create opaque panel style for dialog boxes
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.12, 0.2, 1.0)  # Fully opaque dark purple
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
	
	# Apply to all dialog panels
	reaction_panel.add_theme_stylebox_override("panel", panel_style.duplicate())
	effect_panel.add_theme_stylebox_override("panel", panel_style.duplicate())
	game_over_panel.add_theme_stylebox_override("panel", panel_style.duplicate())
	discard_view_panel.add_theme_stylebox_override("panel", panel_style.duplicate())
	settings_panel.add_theme_stylebox_override("panel", panel_style.duplicate())
	game_menu_panel.add_theme_stylebox_override("panel", panel_style.duplicate())

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

func _setup_game_menu():
	# Populate theme dropdown in game menu
	menu_theme_option.clear()
	var themes = SettingsManager.get_theme_names()
	var current_idx = 0
	for i in range(themes.size()):
		menu_theme_option.add_item(themes[i]["name"], i)
		menu_theme_option.set_item_metadata(i, themes[i]["id"])
		if themes[i]["id"] == SettingsManager.current_theme:
			current_idx = i
	menu_theme_option.select(current_idx)
	menu_animations_check.button_pressed = SettingsManager.animations_enabled
	
	# Populate rules in menu
	_populate_menu_rules()

func _apply_theme():
	var theme = SettingsManager.get_theme()
	background.color = theme["background"]
	background_pattern.color = theme["background_pattern"]

func _populate_rules():
	clear_container(rules_content)
	
	var rules_text = [
		"═══ WIN CONDITIONS ═══",
		"• Get 1 of each type on your field",
		"• OR get 5 of the same type",
		"",
		"═══ TURN FLOW ═══",
		"• Draw 1 card (except first turn)",
		"• Drag a card to the field to play",
		"",
		"═══ CARD EFFECTS ═══",
		"🔥 FIRE: Remove an opponent's field card",
		"🌿 GRASS: Retrieve a card from your discard",
		"⚡ LIGHTNING: Draw an extra card",
		"🌑 DARKNESS: Discard random card from opponent's hand",
		"💧 WATER: Look at top deck card, optionally move to bottom",
		"",
		"═══ WATER REACTION ═══",
		"• Block opponent's card with Water + matching type",
		"• Counter-block with 2 Water cards",
		"• 5 second window to react"
	]
	
	for line in rules_text:
		var label = Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 11)
		
		if "═══" in line:
			label.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
		elif line.begins_with("🔥"):
			label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
		elif line.begins_with("🌿"):
			label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		elif line.begins_with("⚡"):
			label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		elif line.begins_with("🌑"):
			label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
		elif line.begins_with("💧"):
			label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		else:
			label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		
		rules_content.add_child(label)

func _populate_menu_rules():
	if not menu_rules_content:
		return
	clear_container(menu_rules_content)
	
	var rules_text = [
		"═══ WIN CONDITIONS ═══",
		"• Get 1 of each type on your field",
		"• OR get 5 of the same type",
		"",
		"═══ TURN FLOW ═══",
		"• Draw 1 card (except first turn)",
		"• " + ("Tap" if _is_mobile_web() else "Drag") + " a card to the field to play",
		"",
		"═══ CARD EFFECTS ═══",
		"🔥 FIRE: Remove an opponent's field card",
		"🌿 GRASS: Retrieve a card from your discard",
		"⚡ LIGHTNING: Draw an extra card",
		"🌑 DARKNESS: Discard random card from opponent's hand",
		"💧 WATER: Look at top deck card, optionally move to bottom",
		"",
		"═══ WATER REACTION ═══",
		"• Block opponent's card with Water + matching type",
		"• Counter-block with 2 Water cards",
		"• 5 second window to react"
	]
	
	var font_size = 16 if _is_mobile_web() else 12
	
	for line in rules_text:
		var label = Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", font_size)
		
		if "═══" in line:
			label.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
		elif line.begins_with("🔥"):
			label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
		elif line.begins_with("🌿"):
			label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		elif line.begins_with("⚡"):
			label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		elif line.begins_with("🌑"):
			label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
		elif line.begins_with("💧"):
			label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		else:
			label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		
		menu_rules_content.add_child(label)

func _update_labels_for_game_mode():
	if NetworkManager.is_multiplayer:
		var opponent_name = NetworkManager.opponent_name if NetworkManager.opponent_name else "Opponent"
		opponent_label.text = "👤 " + opponent_name
		player_label.text = "👤 " + NetworkManager.local_player_name
		new_game_button.visible = false
	else:
		opponent_label.text = "🤖 AI Opponent"
		player_label.text = "👤 You"
		new_game_button.visible = true

func _update_turn_indicators():
	var is_player_turn = GameManager.current_state in [
		GameManager.GameState.PLAYER_TURN_PLAY,
		GameManager.GameState.PLAYER_TURN_DRAW,
		GameManager.GameState.PLAYER_EFFECT
	]
	var is_opponent_turn = GameManager.current_state in [
		GameManager.GameState.AI_TURN_PLAY,
		GameManager.GameState.AI_TURN_DRAW,
		GameManager.GameState.AI_EFFECT,
		GameManager.GameState.OPPONENT_TURN
	]
	var is_reaction = GameManager.current_state == GameManager.GameState.REACTION_WINDOW
	
	if is_player_turn:
		player_turn_indicator.text = "◄ YOUR TURN"
		player_turn_indicator.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		player_turn_indicator.visible = true
	elif is_reaction and GameManager.awaiting_reaction:
		player_turn_indicator.text = "◄ REACT?"
		player_turn_indicator.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		player_turn_indicator.visible = true
	else:
		player_turn_indicator.visible = false
	
	if is_opponent_turn:
		var opponent_name = "AI" if not NetworkManager.is_multiplayer else "OPPONENT"
		opponent_turn_indicator.text = opponent_name + " TURN ►"
		opponent_turn_indicator.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		opponent_turn_indicator.visible = true
	elif is_reaction and not GameManager.awaiting_reaction and GameManager.reaction_chain.size() == 0:
		opponent_turn_indicator.text = "REACTING... ►"
		opponent_turn_indicator.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		opponent_turn_indicator.visible = true
	else:
		opponent_turn_indicator.visible = false

func _process(delta):
	if reaction_active:
		reaction_timer -= delta
		var max_time = 7.0 if _is_mobile_web() else 5.0
		reaction_timer_bar.value = (reaction_timer / max_time) * 100.0
		if reaction_timer <= 0:
			reaction_active = false
			reaction_panel.visible = false
			GameManager.player_pass_reaction()
	
	# Update drop zone position if dragging
	if dragging_card:
		_update_drop_zone_highlight()

func _update_drop_zone_highlight():
	if not dragging_card:
		return
	
	var mouse_pos = get_global_mouse_position()
	var in_zone = drop_zone.get_global_rect().has_point(mouse_pos)
	
	var style = drop_zone.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		if in_zone:
			style.bg_color = Color(0.3, 1.0, 0.3, 0.4)
			style.border_color = Color(0.5, 1.0, 0.5, 1.0)
		else:
			style.bg_color = Color(0.3, 0.8, 0.3, 0.2)
			style.border_color = Color(0.4, 1.0, 0.4, 0.8)

func _on_all_visuals_reset():
	# Add comprehensive error handling to prevent crashes
	if not is_instance_valid(get_viewport()):
		print("[Main] ERROR: Viewport is invalid in _on_all_visuals_reset!")
		return
	
	# Clear containers with error handling
	if is_instance_valid(player_hand_container):
		clear_container(player_hand_container)
	if is_instance_valid(ai_hand_container):
		clear_container(ai_hand_container)
	if is_instance_valid(player_field_container):
		clear_container(player_field_container)
	if is_instance_valid(ai_field_container):
		clear_container(ai_field_container)
	if is_instance_valid(player_discard_container):
		clear_container(player_discard_container)
	if is_instance_valid(ai_discard_container):
		clear_container(ai_discard_container)
	
	# Update labels with error handling
	if is_instance_valid(player_deck_count):
		player_deck_count.text = "25"
	if is_instance_valid(ai_deck_count):
		ai_deck_count.text = "25"
	if is_instance_valid(player_discard_count):
		player_discard_count.text = "Discard: 0"
	if is_instance_valid(ai_discard_count):
		ai_discard_count.text = "Discard: 0"
	
	current_effect = ""
	dragging_card = null
	dragging_card_index = -1
	
	if is_instance_valid(log_content):
		clear_container(log_content)
		_add_log_entry("═══ New Game Started ═══")
	
	_update_labels_for_game_mode()
	_update_turn_indicators()
	
	# Ensure UI elements stay on screen
	if _is_mobile_web():
		call_deferred("_validate_ui_bounds")

func _on_hand_updated(is_player: bool):
	# Add error handling to prevent crashes
	if not is_instance_valid(get_viewport()):
		return
	if is_player:
		if is_instance_valid(player_hand_container):
			refresh_player_hand()
		else:
			print("[Main] ERROR: player_hand_container is invalid!")
	else:
		if is_instance_valid(ai_hand_container):
			refresh_ai_hand()
		else:
			print("[Main] ERROR: ai_hand_container is invalid!")

func _on_field_updated(is_player: bool):
	# Add error handling to prevent crashes
	if not is_instance_valid(get_viewport()):
		return
	if is_player:
		if is_instance_valid(player_field_container):
			refresh_player_field()
			# Validate bounds after update
			if _is_mobile_web():
				call_deferred("_validate_ui_bounds")
		else:
			print("[Main] ERROR: player_field_container is invalid!")
	else:
		if is_instance_valid(ai_field_container):
			refresh_ai_field()
			# Validate bounds after update
			if _is_mobile_web():
				call_deferred("_validate_ui_bounds")
		else:
			print("[Main] ERROR: ai_field_container is invalid!")

func _on_deck_updated(is_player: bool):
	if is_player:
		player_deck_count.text = str(GameManager.player_deck.size())
	else:
		ai_deck_count.text = str(GameManager.ai_deck.size())

func _on_discard_updated(is_player: bool):
	if is_player:
		player_discard_count.text = "Discard: " + str(GameManager.player_discard.size())
		refresh_discard_display(player_discard_container, GameManager.player_discard, true)
	else:
		ai_discard_count.text = "Discard: " + str(GameManager.ai_discard.size())
		refresh_discard_display(ai_discard_container, GameManager.ai_discard, false)

func _on_message_updated(text: String):
	message_label.text = text
	_add_log_entry(text)

func _add_log_entry(text: String):
	if not log_content:
		return
	
	while log_content.get_child_count() >= MAX_LOG_ENTRIES:
		var oldest = log_content.get_child(0)
		log_content.remove_child(oldest)
		oldest.queue_free()
	
	var label = Label.new()
	label.text = "• " + text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	
	if "═══" in text:
		label.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
		label.text = text
	elif "blocked" in text.to_lower():
		label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	elif "win" in text.to_lower() or "victory" in text.to_lower():
		label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	elif "defeat" in text.to_lower():
		label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	elif "effect" in text.to_lower():
		label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	elif "drew" in text.to_lower():
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
	else:
		label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	
	log_content.add_child(label)
	call_deferred("_scroll_log_to_bottom")

func _scroll_log_to_bottom():
	if log_scroll and log_scroll.get_v_scroll_bar():
		log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)

func _on_log_header_pressed():
	log_expanded = not log_expanded
	_update_log_visibility()

func _update_log_visibility():
	if log_scroll:
		log_scroll.visible = log_expanded
	
	if log_expanded:
		log_header.text = "📜 Action Log ▼"
		log_panel.custom_minimum_size = Vector2(200, 0)
	else:
		log_header.text = "📜 Log ►"
		log_panel.custom_minimum_size = Vector2(80, 0)

func _on_rules_header_pressed():
	rules_expanded = not rules_expanded
	_update_rules_visibility()

func _update_rules_visibility():
	if rules_scroll:
		rules_scroll.visible = rules_expanded
	
	if rules_expanded:
		rules_header.text = "📖 Rules ▼"
		rules_panel.custom_minimum_size = Vector2(200, 0)
	else:
		rules_header.text = "📖 Rules ►"
		rules_panel.custom_minimum_size = Vector2(80, 0)

func _on_settings_pressed():
	settings_panel.visible = true

func _on_settings_close():
	settings_panel.visible = false

func _on_theme_selected(index: int):
	var theme_id = theme_option.get_item_metadata(index)
	SettingsManager.set_theme(theme_id)

func _on_animations_toggled(enabled: bool):
	SettingsManager.set_animations(enabled)

# In-game menu handlers
func _on_menu_button_pressed():
	game_menu_panel.visible = true
	# Sync current settings to menu
	menu_animations_check.button_pressed = SettingsManager.animations_enabled
	var themes = SettingsManager.get_theme_names()
	for i in range(themes.size()):
		if themes[i]["id"] == SettingsManager.current_theme:
			menu_theme_option.select(i)
			break
	
	# Refresh rules for mobile if needed
	if _is_mobile_web() and menu_rules_content:
		_populate_menu_rules()
	
	# Increase font sizes on mobile
	if _is_mobile_web():
		_setup_mobile_menu_fonts()

func _on_resume_pressed():
	game_menu_panel.visible = false

func _on_menu_animations_toggled(enabled: bool):
	SettingsManager.set_animations(enabled)
	# Sync to settings panel
	animations_check.button_pressed = enabled

func _on_menu_theme_selected(index: int):
	var theme_id = menu_theme_option.get_item_metadata(index)
	SettingsManager.set_theme(theme_id)
	# Sync to settings panel
	theme_option.select(index)


func _on_game_state_changed(new_state: GameManager.GameState):
	var can_play = new_state == GameManager.GameState.PLAYER_TURN_PLAY
	var is_mobile = _is_mobile_web()
	
	for card in player_hand_container.get_children():
		# Skip spacers
		if not card.has_method("setup"):
			continue
			
		if is_mobile:
			# Mobile: use tap-to-play instead of drag-and-drop
			card.draggable = false
			card.clickable = can_play
			# Ensure signal is connected
			if can_play and not card.card_clicked.is_connected(_on_card_clicked_to_play):
				card.card_clicked.connect(_on_card_clicked_to_play)
			elif not can_play and card.card_clicked.is_connected(_on_card_clicked_to_play):
				card.card_clicked.disconnect(_on_card_clicked_to_play)
		else:
			# Desktop: use drag-and-drop
			card.draggable = can_play
			card.clickable = false
			# Disconnect mobile handler if connected
			if card.card_clicked.is_connected(_on_card_clicked_to_play):
				card.card_clicked.disconnect(_on_card_clicked_to_play)
		card.update_highlight()
	
	# Show/hide drop zone hint
	if can_play:
		_position_drop_zone()
	else:
		drop_zone.visible = false
	
	_update_turn_indicators()

func _position_drop_zone():
	# Position drop zone over the player field area
	var field_rect = player_field_container.get_global_rect()
	drop_zone.global_position = field_rect.position - Vector2(10, 10)
	drop_zone.size = field_rect.size + Vector2(20, 20)
	drop_zone.size.x = max(drop_zone.size.x, 200)
	drop_zone.size.y = max(drop_zone.size.y, 140)

# Mobile tap-to-play handler
func _on_card_clicked_to_play(card: Control):
	print("[Main] Card clicked to play, state: ", GameManager.current_state, ", card: ", card)
	
	# Add error handling to prevent crashes
	if not is_instance_valid(card):
		print("[Main] Card is invalid, aborting")
		return
	
	if GameManager.current_state != GameManager.GameState.PLAYER_TURN_PLAY:
		print("[Main] Not player turn, ignoring click")
		return
	
	# Get the hand index from the card
	var hand_index = card.original_index
	print("[Main] Card hand index: ", hand_index, ", hand size: ", GameManager.player_hand.size())
	
	# Validate index
	if hand_index < 0 or hand_index >= GameManager.player_hand.size():
		print("[Main] Invalid hand index, trying to find card in hand")
		# Try to find the card by matching card node
		for i in range(player_hand_container.get_child_count()):
			var child = player_hand_container.get_child(i)
			# Skip spacers
			if not child.has_method("setup"):
				continue
			if child == card:
				hand_index = i
				# Adjust for spacers
				var spacer_count = 0
				for j in range(i):
					if not player_hand_container.get_child(j).has_method("setup"):
						spacer_count += 1
				hand_index = i - spacer_count
				break
		
		if hand_index < 0 or hand_index >= GameManager.player_hand.size():
			print("[Main] Could not find card in hand, aborting")
			return
	
	# Play the card directly with error handling
	print("[Main] Playing card at index: ", hand_index, ", card type: ", GameManager.player_hand[hand_index])
	
	# Wrap in error handling to prevent scene reload on error
	var error = false
	if hand_index >= 0 and hand_index < GameManager.player_hand.size():
		GameManager.player_play_card(hand_index)
	else:
		print("[Main] ERROR: Invalid hand index when trying to play card!")
		error = true
	
	if error:
		message_label.text = "Error playing card. Please try again."
		message_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))

# Drag and drop handlers (desktop only)
func _on_card_drag_started(card: Control):
	dragging_card = card
	dragging_card_index = card.original_index
	drop_zone.visible = true
	_position_drop_zone()

func _on_card_drag_ended(card: Control, _success: bool):
	var mouse_pos = get_global_mouse_position()
	var in_drop_zone = drop_zone.get_global_rect().has_point(mouse_pos)
	
	drop_zone.visible = false
	
	if in_drop_zone and GameManager.current_state == GameManager.GameState.PLAYER_TURN_PLAY:
		# Successfully dropped - play the card
		var hand_idx = dragging_card_index
		
		# Remove the dragging card
		card.queue_free()
		dragging_card = null
		dragging_card_index = -1
		
		# Play the card
		GameManager.player_play_card(hand_idx)
	else:
		# Return card to hand
		card.return_to_hand()
		dragging_card = null
		dragging_card_index = -1

# Card resolved - play success animation on the specific card
func _on_card_resolved(card_type: GameManager.CardType, is_player: bool):
	# Skip lightning - its animation is the draw effect instead
	if card_type == GameManager.CardType.LIGHTNING:
		return
	
	var card_rect = _find_last_card_rect(card_type, is_player)
	_play_success_animation(card_type, card_rect)

func _find_last_card_rect(card_type: GameManager.CardType, is_player: bool) -> Rect2:
	# Find the actual card on the field to position animations correctly
	var field_container = player_field_container if is_player else ai_field_container
	
	# Look through stacks to find the card of this type
	for stack in field_container.get_children():
		if stack is Control:
			for card in stack.get_children():
				if card.has_method("setup") and card.card_type == card_type:
					# Get the last (topmost) card in the stack
					var last_card = stack.get_child(stack.get_child_count() - 1)
					if last_card:
						return Rect2(last_card.global_position, last_card.size)
	
	# Fallback to field container center
	var field_rect = field_container.get_global_rect()
	return Rect2(field_rect.position + field_rect.size / 2 - Vector2(40, 60), Vector2(80, 120))

func _play_success_animation(card_type: GameManager.CardType, card_rect: Rect2):
	if not SettingsManager.animations_enabled:
		return
	
	var animation = CardAnimations.new()
	add_child(animation)
	
	# Position centered on the card, but larger for effect
	var center = card_rect.position + card_rect.size / 2
	var anim_size = Vector2(160, 180)
	animation.global_position = center - anim_size / 2
	animation.size = anim_size
	
	animation.play_animation(card_type)

# Card blocked - play blocked animation on the card
func _on_card_blocked(card_type: GameManager.CardType, card_owner_is_player: bool, blocker_is_player: bool):
	# Find the card's position on the field
	var card_rect = _find_last_card_rect(card_type, card_owner_is_player)
	
	# Both players see the shatter on the card
	_play_shatter_animation(card_type, card_rect)
	
	# Only the blocked player sees "BLOCKED" text and screen shake
	if card_owner_is_player:
		_play_blocked_overlay()

func _play_shatter_animation(card_type: GameManager.CardType, card_rect: Rect2):
	if not SettingsManager.animations_enabled:
		return
	
	var shatter = ShatterEffect.new()
	add_child(shatter)
	shatter.play_shatter(card_type, card_rect)

func _play_blocked_overlay():
	if not SettingsManager.animations_enabled:
		return
	
	var overlay = BlockedOverlay.new()
	add_child(overlay)
	overlay.play_blocked(self)  # Pass self for screen shake

# Fire effect - card burns on opponent's field
func _on_fire_effect_triggered(target_card: GameManager.CardType, target_is_player: bool):
	var card_rect = _find_last_card_rect(target_card, target_is_player)
	_play_fire_burn_animation(target_card, card_rect)

func _play_fire_burn_animation(card_type: GameManager.CardType, card_rect: Rect2):
	if not SettingsManager.animations_enabled:
		return
	
	var effect = EffectAnimations.FireBurnEffect.new()
	add_child(effect)
	effect.play(card_type, card_rect)

# Darkness effect - card dissolves from opponent's hand
func _on_darkness_effect_triggered(target_is_player: bool):
	var hand_container = player_hand_container if target_is_player else ai_hand_container
	_play_darkness_dissolve_animation(hand_container)

func _play_darkness_dissolve_animation(hand_container: Control):
	if not SettingsManager.animations_enabled:
		return
	
	# Pick a random card from the hand to dissolve
	if hand_container.get_child_count() > 0:
		var random_idx = randi() % hand_container.get_child_count()
		var card = hand_container.get_child(random_idx)
		var card_rect = Rect2(card.global_position, card.size)
		
		var effect = EffectAnimations.DarknessDissolveEffect.new()
		add_child(effect)
		effect.play(card_rect)

# Grass effect - card grows from discard to hand
func _on_grass_effect_triggered(card_type: GameManager.CardType, is_player: bool):
	var discard_container = player_discard_container if is_player else ai_discard_container
	var hand_container = player_hand_container if is_player else ai_hand_container
	_play_grass_grow_animation(card_type, discard_container, hand_container)

func _play_grass_grow_animation(card_type: GameManager.CardType, discard_container: Control, hand_container: Control):
	if not SettingsManager.animations_enabled:
		return
	
	var from_rect = discard_container.get_global_rect()
	var to_rect: Rect2
	
	# Target the end of the hand
	if hand_container.get_child_count() > 0:
		var last_card = hand_container.get_child(hand_container.get_child_count() - 1)
		to_rect = Rect2(last_card.global_position + Vector2(90, 0), last_card.size)
	else:
		to_rect = Rect2(hand_container.global_position, Vector2(80, 120))
	
	var effect = EffectAnimations.GrassGrowEffect.new()
	add_child(effect)
	effect.play(card_type, from_rect, to_rect)

# Lightning effect - bolt strikes and card appears in hand
func _on_lightning_effect_triggered(card_type: GameManager.CardType, is_player: bool):
	var hand_container = player_hand_container if is_player else ai_hand_container
	# Only reveal card face for player's own draws, not opponent's
	_play_lightning_strike_animation(card_type, hand_container, is_player)

func _play_lightning_strike_animation(card_type: GameManager.CardType, hand_container: Control, reveal_card: bool):
	if not SettingsManager.animations_enabled:
		return
	
	var target_rect: Rect2
	
	# Target the end of the hand where new card will appear
	if hand_container.get_child_count() > 0:
		var last_card = hand_container.get_child(hand_container.get_child_count() - 1)
		target_rect = Rect2(last_card.global_position + Vector2(90, 0), last_card.size)
	else:
		target_rect = Rect2(hand_container.global_position, Vector2(80, 120))
	
	var effect = EffectAnimations.LightningStrikeEffect.new()
	add_child(effect)
	effect.play(card_type, target_rect, reveal_card)

func refresh_player_hand():
	clear_container(player_hand_container)
	var can_play = GameManager.current_state == GameManager.GameState.PLAYER_TURN_PLAY
	
	# Mobile: adjust spacing
	var spacing = 10
	if _is_mobile_web():
		spacing = 5
	
	for i in range(GameManager.player_hand.size()):
		if i > 0 and _is_mobile_web():
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(spacing, 0)
			player_hand_container.add_child(spacer)
		
		var card_type = GameManager.player_hand[i]
		var card = CardScene.instantiate()
		player_hand_container.add_child(card)
		card.setup(card_type, true, false)
		
		# Store the hand index for playing
		card.original_index = i
		
		# Scale card size for mobile - use FIXED size to match field
		if _is_mobile_web():
			var screen_width = get_viewport().get_visible_rect().size.x
			# Use same fixed card width as field to prevent resizing
			var available_width = screen_width - 40
			var spacing_width = 4 * 8  # Fixed spacing
			var card_width = int((available_width - spacing_width) / 5)  # Fixed size
			var card_height = int(card_width * 1.4)
			card.custom_minimum_size = Vector2(card_width, card_height)
			card.size = Vector2(card_width, card_height)
		
		# Mobile: tap-to-play, Desktop: drag-and-drop
		var is_mobile = _is_mobile_web()
		if is_mobile:
			card.draggable = false
			card.clickable = can_play
			if can_play:
				# Disconnect any existing connections first
				if card.card_clicked.is_connected(_on_card_clicked_to_play):
					card.card_clicked.disconnect(_on_card_clicked_to_play)
				card.card_clicked.connect(_on_card_clicked_to_play)
		else:
			card.draggable = can_play
			card.clickable = false
			# Disconnect mobile click handler if connected
			if card.card_clicked.is_connected(_on_card_clicked_to_play):
				card.card_clicked.disconnect(_on_card_clicked_to_play)
			card.card_drag_started.connect(_on_card_drag_started)
			card.card_drag_ended.connect(_on_card_drag_ended)

func refresh_ai_hand():
	clear_container(ai_hand_container)
	
	# Mobile: adjust spacing
	var spacing = 10
	if _is_mobile_web():
		spacing = 5
	
	for i in range(GameManager.ai_hand.size()):
		if i > 0 and _is_mobile_web():
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(spacing, 0)
			ai_hand_container.add_child(spacer)
		
		var card = CardScene.instantiate()
		ai_hand_container.add_child(card)
		card.setup(GameManager.CardType.FIRE, false, false)
		
		# Scale card size for mobile - use FIXED size to match field
		if _is_mobile_web():
			var screen_width = get_viewport().get_visible_rect().size.x
			# Use same fixed card width as field to prevent resizing
			var available_width = screen_width - 40
			var spacing_width = 4 * 8  # Fixed spacing
			var card_width = int((available_width - spacing_width) / 5)  # Fixed size
			var card_height = int(card_width * 1.4)
			card.custom_minimum_size = Vector2(card_width, card_height)
			card.size = Vector2(card_width, card_height)

func refresh_player_field():
	clear_container(player_field_container)
	var cards_by_type = group_cards_by_type(GameManager.player_field)
	
	# Mobile: use FIXED spacing to prevent resizing
	var spacing = 15
	if _is_mobile_web():
		# Fixed spacing - never changes
		spacing = 8
		# Ensure field container has fixed size
		if player_field_container:
			var screen_width = get_viewport().get_visible_rect().size.x
			var available_width = screen_width - 40
			var spacing_width = 4 * 8  # 4 spacers
			var fixed_card_width = int((available_width - spacing_width) / 5)
			var fixed_field_width = 5 * fixed_card_width + 4 * 8
			player_field_container.custom_minimum_size = Vector2(fixed_field_width, 0)
	
	var first = true
	for type in cards_by_type:
		if not first:
			# Add horizontal spacer between card type stacks
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(spacing, 0)
			player_field_container.add_child(spacer)
		first = false
		var stack = create_card_stack(cards_by_type[type], type, true)
		player_field_container.add_child(stack)

func refresh_ai_field():
	clear_container(ai_field_container)
	var cards_by_type = group_cards_by_type(GameManager.ai_field)
	
	# Mobile: use FIXED spacing to prevent resizing
	var spacing = 15
	if _is_mobile_web():
		# Fixed spacing - never changes
		spacing = 8
		# Ensure field container has fixed size
		if ai_field_container:
			var screen_width = get_viewport().get_visible_rect().size.x
			var available_width = screen_width - 40
			var spacing_width = 4 * 8  # 4 spacers
			var fixed_card_width = int((available_width - spacing_width) / 5)
			var fixed_field_width = 5 * fixed_card_width + 4 * 8
			ai_field_container.custom_minimum_size = Vector2(fixed_field_width, 0)
	
	var first = true
	for type in cards_by_type:
		if not first:
			# Add horizontal spacer between card type stacks
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(spacing, 0)
			ai_field_container.add_child(spacer)
		first = false
		var stack = create_card_stack(cards_by_type[type], type, false)
		ai_field_container.add_child(stack)

func group_cards_by_type(field: Array) -> Dictionary:
	var result = {}
	for card in field:
		if not result.has(card):
			result[card] = []
		result[card].append(card)
	return result

func create_card_stack(cards: Array, card_type: GameManager.CardType, is_player: bool) -> Control:
	var container = Control.new()
	
	# Mobile: use FIXED card size to prevent field resizing
	var card_width = 80
	var card_height = 120
	var stack_offset = 25
	
	if _is_mobile_web():
		var screen_width = get_viewport().get_visible_rect().size.x
		# Calculate FIXED card width to fit 5 cards - this never changes
		var available_width = screen_width - 40  # Margins
		var spacing_width = 4 * 8  # 4 spacers, 8px each (fixed)
		card_width = int((available_width - spacing_width) / 5)  # Fixed size
		card_height = int(card_width * 1.4)
		stack_offset = int(card_width * 0.3)
		
		# Set FIXED container size - never changes regardless of number of cards
		# Use max stack height to prevent resizing
		var max_stack_height = card_height + (4 * stack_offset)  # Max 5 cards in a stack
		container.custom_minimum_size = Vector2(card_width, max_stack_height)
		container.size = Vector2(card_width, max_stack_height)
	else:
		container.custom_minimum_size = Vector2(card_width, card_height + (cards.size() - 1) * stack_offset)
	
	for i in range(cards.size()):
		var card = CardScene.instantiate()
		container.add_child(card)
		card.setup(card_type, true, false)
		card.on_field = true  # Enable passive field animations
		
		# Scale card size for mobile
		if _is_mobile_web():
			card.custom_minimum_size = Vector2(card_width, card_height)
			card.size = Vector2(card_width, card_height)
		
		card.position = Vector2(0, i * stack_offset)
		
		if current_effect == "fire" and not is_player:
			var field_idx = find_card_index_in_field(card_type, i, is_player)
			card.clickable = true
			card.card_clicked.connect(_on_fire_target_clicked.bind(field_idx))
	
	return container

func find_card_index_in_field(card_type: GameManager.CardType, stack_idx: int, is_player: bool) -> int:
	var field = GameManager.player_field if is_player else GameManager.ai_field
	var count = 0
	for i in range(field.size()):
		if field[i] == card_type:
			if count == stack_idx:
				return i
			count += 1
	return -1

func refresh_discard_display(container: VBoxContainer, discard: Array, is_player: bool):
	clear_container(container)
	if not discard.is_empty():
		var card = CardScene.instantiate()
		container.add_child(card)
		card.setup(discard[-1], true, true)
		
		# Scale for mobile - larger for better visibility
		if _is_mobile_web():
			var screen_width = get_viewport().get_visible_rect().size.x
			var card_width = int(screen_width * 0.12)  # Increased from 8% to 12%
			var card_height = int(card_width * 1.4)
			card.custom_minimum_size = Vector2(card_width, card_height)
		else:
			card.custom_minimum_size = Vector2(60, 90)
		
		card.card_clicked.connect(_on_discard_pile_clicked.bind(is_player))

func _on_discard_pile_clicked(card_node: Control, is_player: bool):
	var discard = GameManager.player_discard if is_player else GameManager.ai_discard
	var title = "Your Discard Pile" if is_player else (GameManager.get_opponent_name() + "'s Discard Pile")
	show_discard_view(discard, title, is_player)

func show_discard_view(discard: Array, title: String, is_player: bool):
	discard_view_title.text = title + " (" + str(discard.size()) + " cards)"
	clear_container(discard_view_cards)
	
	if discard.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No cards in discard pile"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		discard_view_cards.add_child(empty_label)
	else:
		for i in range(discard.size() - 1, -1, -1):
			var card_type = discard[i]
			var card_row = HBoxContainer.new()
			card_row.alignment = BoxContainer.ALIGNMENT_CENTER
			
			var card = CardScene.instantiate()
			card_row.add_child(card)
			card.setup(card_type, true, false)
			
			# Scale for mobile
			if _is_mobile_web():
				var screen_width = get_viewport().get_visible_rect().size.x
				var card_width = int(screen_width * 0.08)
				var card_height = int(card_width * 1.4)
				card.custom_minimum_size = Vector2(card_width, card_height)
			else:
				card.custom_minimum_size = Vector2(60, 90)
			
			if current_effect == "grass" and is_player:
				card.clickable = true
				card.card_clicked.connect(_on_grass_target_from_view.bind(i))
			
			discard_view_cards.add_child(card_row)
	
	discard_view_panel.visible = true

func _on_grass_target_from_view(card_node: Control, discard_idx: int):
	discard_view_panel.visible = false
	_on_grass_target_clicked(discard_idx)

func _on_discard_view_close():
	discard_view_panel.visible = false

func clear_container(container: Node):
	if not container:
		return
	for child in container.get_children():
		child.queue_free()

func _on_reaction_window_started(card_played: GameManager.CardType, is_player_reacting: bool):
	_update_turn_indicators()
	
	if is_player_reacting:
		# Always reset and show the reaction panel for local player
		reaction_active = true
		reaction_timer = 7.0 if _is_mobile_web() else 5.0  # More time on mobile
		reaction_panel.visible = true
		
		var card_name = GameManager.CARD_NAMES[card_played]
		var chain_depth = GameManager.reaction_chain.size()
		
		print("[Main] Reaction window for player, chain depth: ", chain_depth)
		
		if chain_depth == 0:
			reaction_label.text = "Block " + card_name + " with Water + " + card_name + "?"
			var can_block = can_player_block(card_played)
			react_button.disabled = not can_block
		else:
			reaction_label.text = "Counter-block with 2 Water?"
			var can_counter = GameManager.player_hand.count(GameManager.CardType.WATER) >= 2
			react_button.disabled = not can_counter
	else:
		# Opponent's turn to react - hide our panel
		reaction_active = false
		reaction_panel.visible = false

func can_player_block(card: GameManager.CardType) -> bool:
	var hand = GameManager.player_hand
	var water_count = hand.count(GameManager.CardType.WATER)
	var match_count = hand.count(card)
	
	if card == GameManager.CardType.WATER:
		return water_count >= 2
	else:
		return water_count >= 1 and match_count >= 1

func _on_reaction_window_ended():
	reaction_active = false
	reaction_panel.visible = false
	_update_turn_indicators()

func _on_react_pressed():
	reaction_active = false
	reaction_panel.visible = false
	GameManager.player_react()

func _on_pass_pressed():
	reaction_active = false
	reaction_panel.visible = false
	GameManager.player_pass_reaction()

func _on_effect_target_needed(effect_type: String):
	current_effect = effect_type
	
	match effect_type:
		"fire":
			# Show compact prompt at the top, out of the way
			effect_panel.visible = true
			effect_label.text = "🔥 Click opponent's card to destroy"
			effect_label.add_theme_font_size_override("font_size", 14)
			effect_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
			clear_container(effect_options)
			# Position the panel at top-right, out of the play area
			effect_panel.anchors_preset = Control.PRESET_TOP_RIGHT
			effect_panel.offset_left = -220
			effect_panel.offset_right = -20
			effect_panel.offset_top = 70
			effect_panel.offset_bottom = 120
			refresh_ai_field()  # This will make opponent cards clickable
		"grass":
			_reset_effect_panel_position()
			effect_panel.visible = true
			effect_label.text = "Choose card from your discard:"
			effect_label.remove_theme_font_size_override("font_size")
			effect_label.remove_theme_color_override("font_color")
			show_grass_options()
		"water":
			_reset_effect_panel_position()
			effect_panel.visible = true
			effect_label.text = "Move top card to bottom?"
			effect_label.remove_theme_font_size_override("font_size")
			effect_label.remove_theme_color_override("font_color")
			show_water_options()

func _reset_effect_panel_position():
	# Reset to center position for non-fire effects
	effect_panel.anchors_preset = Control.PRESET_CENTER
	effect_panel.offset_left = -150
	effect_panel.offset_right = 150
	effect_panel.offset_top = -120
	effect_panel.offset_bottom = 120

func show_grass_options():
	clear_container(effect_options)
	for i in range(GameManager.player_discard.size()):
		var card_type = GameManager.player_discard[i]
		var btn = Button.new()
		btn.text = GameManager.CARD_SYMBOLS[card_type] + " " + GameManager.CARD_NAMES[card_type]
		btn.pressed.connect(_on_grass_target_clicked.bind(i))
		effect_options.add_child(btn)

func show_water_options():
	clear_container(effect_options)
	
	if not GameManager.player_deck.is_empty():
		var top_card = GameManager.player_deck[-1]
		var info = Label.new()
		info.text = "Top card: " + GameManager.CARD_SYMBOLS[top_card] + " " + GameManager.CARD_NAMES[top_card]
		effect_options.add_child(info)
	
	var yes_btn = Button.new()
	yes_btn.text = "Move to Bottom"
	yes_btn.pressed.connect(_on_water_choice.bind(true))
	effect_options.add_child(yes_btn)
	
	var no_btn = Button.new()
	no_btn.text = "Leave on Top"
	no_btn.pressed.connect(_on_water_choice.bind(false))
	effect_options.add_child(no_btn)

func _on_fire_target_clicked(card_node: Control, field_idx: int):
	effect_panel.visible = false
	current_effect = ""
	message_label.text = "Fire effect activating..."
	GameManager.complete_fire_effect(true, field_idx)
	# Refresh to remove clickable state from remaining cards
	refresh_ai_field()

func _on_grass_target_clicked(discard_idx: int):
	effect_panel.visible = false
	discard_view_panel.visible = false
	current_effect = ""
	GameManager.complete_grass_effect(true, discard_idx)

func _on_water_choice(move_to_bottom: bool):
	effect_panel.visible = false
	current_effect = ""
	GameManager.complete_water_effect(true, move_to_bottom)

func _on_game_over(player_won: bool):
	game_over_panel.visible = true
	
	if player_won:
		game_over_label.text = "🎉 Victory! 🎉\nYou defeated " + GameManager.get_opponent_name() + "!"
		_add_log_entry("═══ VICTORY! ═══")
	else:
		game_over_label.text = "💀 Defeat 💀\n" + GameManager.get_opponent_name() + " has won..."
		_add_log_entry("═══ DEFEAT ═══")
	
	_update_turn_indicators()
	
	if NetworkManager.is_multiplayer:
		play_again_button.visible = false
		rematch_button.visible = true
		rematch_button.disabled = false
		rematch_button.text = "🔄 Rematch"
		rematch_status.visible = false
	else:
		play_again_button.visible = true
		rematch_button.visible = false
		rematch_status.visible = false

func _on_play_again_pressed():
	game_over_panel.visible = false
	GameManager.start_new_game()

func _on_rematch_pressed():
	rematch_button.disabled = true
	rematch_button.text = "Waiting..."
	rematch_status.visible = true
	rematch_status.text = "Waiting for " + NetworkManager.opponent_name + "..."
	NetworkManager.request_rematch()

func _on_rematch_requested():
	if NetworkManager.local_wants_rematch:
		rematch_status.text = "Starting new game..."
	else:
		rematch_status.visible = true
		rematch_status.text = NetworkManager.opponent_name + " wants a rematch!"
		rematch_button.text = "🔄 Accept Rematch"
		rematch_button.disabled = false

func _on_network_game_started():
	game_over_panel.visible = false
	NetworkManager.initialize_multiplayer_game()

func _on_main_menu_pressed():
	_return_to_title()

func _on_new_game_pressed():
	reaction_panel.visible = false
	effect_panel.visible = false
	game_over_panel.visible = false
	discard_view_panel.visible = false
	settings_panel.visible = false
	drop_zone.visible = false
	game_menu_panel.visible = false
	GameManager.start_new_game()

func _on_back_pressed():
	_return_to_title()

func _return_to_title():
	if NetworkManager.is_multiplayer:
		NetworkManager.disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
