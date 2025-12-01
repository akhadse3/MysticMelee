extends Node

# Card Types
enum CardType { FIRE, GRASS, LIGHTNING, DARKNESS, WATER }

# Game States
enum GameState { 
	SETUP,
	PLAYER_TURN_DRAW,
	PLAYER_TURN_PLAY,
	PLAYER_EFFECT,
	AI_TURN_DRAW,
	AI_TURN_PLAY,
	AI_EFFECT,
	OPPONENT_TURN,  # For multiplayer - waiting for remote opponent
	REACTION_WINDOW,
	GAME_OVER
}

# Signals
signal game_state_changed(new_state: GameState)
signal hand_updated(is_player: bool)
signal field_updated(is_player: bool)
signal deck_updated(is_player: bool)
signal discard_updated(is_player: bool)
signal message_updated(text: String)
signal reaction_window_started(card_played: CardType, is_player_reacting: bool)
signal reaction_window_ended
signal game_over(player_won: bool)
signal effect_target_needed(effect_type: String)
signal all_visuals_reset
signal player_effect_completed
signal card_played(card_type: CardType, is_player: bool)
signal card_resolved(card_type: CardType, is_player: bool)  # Card successfully placed on field
signal card_blocked(card_type: CardType, is_player: bool, blocker_is_player: bool)  # Card was blocked
signal fire_effect_triggered(target_card: CardType, target_is_player: bool)  # Fire removes a card
signal darkness_effect_triggered(target_is_player: bool)  # Darkness discards from hand
signal grass_effect_triggered(card_type: CardType, is_player: bool)  # Grass retrieves card
signal lightning_effect_triggered(card_type: CardType, is_player: bool)  # Lightning draws card

# Game Data - Each player has their own deck
var player_deck: Array[CardType] = []
var ai_deck: Array[CardType] = []  # Also used for opponent in multiplayer
var player_hand: Array[CardType] = []
var player_field: Array[CardType] = []
var player_discard: Array[CardType] = []
var ai_hand: Array[CardType] = []  # Also "opponent_hand" in multiplayer
var ai_field: Array[CardType] = []
var ai_discard: Array[CardType] = []

var current_state: GameState = GameState.SETUP
var is_player_first: bool = true
var is_first_turn: bool = true
var turn_count: int = 0
var waiting_for_player_effect: bool = false

# Multiplayer state
var is_multiplayer_game: bool = false
var is_local_player_one: bool = true  # True = host/bottom player

# Reaction system
var pending_card: CardType
var pending_is_player: bool  # In multiplayer: true = local player's card
var reaction_chain: Array = []
var max_reaction_depth: int = 5
var awaiting_reaction: bool = false

# Card type names and colors
const CARD_NAMES = {
	CardType.FIRE: "Fire",
	CardType.GRASS: "Grass", 
	CardType.LIGHTNING: "Lightning",
	CardType.DARKNESS: "Darkness",
	CardType.WATER: "Water"
}

const CARD_COLORS = {
	CardType.FIRE: Color(0.9, 0.3, 0.2),
	CardType.GRASS: Color(0.3, 0.8, 0.3),
	CardType.LIGHTNING: Color(1.0, 0.9, 0.3),
	CardType.DARKNESS: Color(0.4, 0.2, 0.5),
	CardType.WATER: Color(0.3, 0.5, 0.9)
}

const CARD_SYMBOLS = {
	CardType.FIRE: "🔥",
	CardType.GRASS: "🌿",
	CardType.LIGHTNING: "⚡",
	CardType.DARKNESS: "🌑",
	CardType.WATER: "💧"
}

func _ready():
	# Connect multiplayer signals
	if NetworkManager:
		NetworkManager.opponent_played_card.connect(_on_opponent_played_card)
		NetworkManager.opponent_reacted.connect(_on_opponent_reacted)
		NetworkManager.opponent_effect_choice.connect(_on_opponent_effect_choice)

func create_deck_with_seed(seed_value: int) -> Array[CardType]:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var deck: Array[CardType] = []
	for type in CardType.values():
		for i in range(5):
			deck.append(type)
	
	# Shuffle with seeded RNG
	for i in range(deck.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var temp = deck[i]
		deck[i] = deck[j]
		deck[j] = temp
	
	return deck

func create_full_deck() -> Array[CardType]:
	var deck: Array[CardType] = []
	for type in CardType.values():
		for i in range(5):
			deck.append(type)
	deck.shuffle()
	return deck

func start_new_game():
	# Single player vs AI
	is_multiplayer_game = false
	waiting_for_player_effect = false
	awaiting_reaction = false
	
	player_deck = create_full_deck()
	ai_deck = create_full_deck()
	
	_initialize_game()
	
	is_player_first = randf() > 0.5
	
	if is_player_first:
		emit_signal("message_updated", "You go first! (No draw on first turn)")
		start_player_turn()
	else:
		emit_signal("message_updated", "AI goes first!")
		start_ai_turn()

func start_multiplayer_game(host_deck_seed: int, client_deck_seed: int, host_goes_first: bool, is_host: bool):
	is_multiplayer_game = true
	is_local_player_one = is_host
	waiting_for_player_effect = false
	awaiting_reaction = false
	
	# Create deterministic decks based on seeds
	if is_host:
		player_deck = create_deck_with_seed(host_deck_seed)
		ai_deck = create_deck_with_seed(client_deck_seed)  # "ai_deck" is opponent's deck
	else:
		player_deck = create_deck_with_seed(client_deck_seed)
		ai_deck = create_deck_with_seed(host_deck_seed)
	
	_initialize_game()
	
	# Determine who goes first from local perspective
	if is_host:
		is_player_first = host_goes_first
	else:
		is_player_first = not host_goes_first
	
	var opponent_name = NetworkManager.opponent_name if NetworkManager else "Opponent"
	
	if is_player_first:
		emit_signal("message_updated", "You go first! (No draw on first turn)")
		start_player_turn()
	else:
		emit_signal("message_updated", opponent_name + " goes first!")
		start_opponent_turn_multiplayer()

func _initialize_game():
	player_hand.clear()
	player_field.clear()
	player_discard.clear()
	ai_hand.clear()
	ai_field.clear()
	ai_discard.clear()
	
	emit_signal("all_visuals_reset")
	emit_signal("field_updated", true)
	emit_signal("field_updated", false)
	emit_signal("hand_updated", true)
	emit_signal("hand_updated", false)
	emit_signal("deck_updated", true)
	emit_signal("deck_updated", false)
	emit_signal("discard_updated", true)
	emit_signal("discard_updated", false)
	
	# Draw starting hands
	for i in range(3):
		player_hand.append(draw_card_from_deck(true))
		ai_hand.append(draw_card_from_deck(false))
	
	is_first_turn = true
	turn_count = 0
	reaction_chain.clear()
	
	emit_signal("hand_updated", true)
	emit_signal("hand_updated", false)
	emit_signal("deck_updated", true)
	emit_signal("deck_updated", false)

func draw_card_from_deck(is_player: bool) -> CardType:
	var deck = player_deck if is_player else ai_deck
	
	if deck.is_empty():
		reshuffle_discard_into_deck(is_player)
		deck = player_deck if is_player else ai_deck
	
	if deck.is_empty():
		return CardType.FIRE
	
	var card = deck.pop_back()
	emit_signal("deck_updated", is_player)
	return card

func reshuffle_discard_into_deck(is_player: bool):
	if is_player:
		player_deck.append_array(player_discard)
		player_discard.clear()
		player_deck.shuffle()
	else:
		ai_deck.append_array(ai_discard)
		ai_discard.clear()
		ai_deck.shuffle()
	
	var player_name = "Your" if is_player else ("Opponent's" if is_multiplayer_game else "AI's")
	emit_signal("message_updated", player_name + " deck reshuffled from discard!")
	emit_signal("discard_updated", is_player)
	emit_signal("deck_updated", is_player)

func start_player_turn():
	if not (is_first_turn and is_player_first):
		player_hand.append(draw_card_from_deck(true))
		emit_signal("hand_updated", true)
		emit_signal("message_updated", "You drew a card.")
		await get_tree().create_timer(0.5).timeout
	
	is_first_turn = false
	change_state(GameState.PLAYER_TURN_PLAY)
	emit_signal("message_updated", "Your turn - Play a card from your hand.")

func start_ai_turn():
	if not (is_first_turn and not is_player_first):
		ai_hand.append(draw_card_from_deck(false))
		emit_signal("hand_updated", false)
		emit_signal("message_updated", "AI drew a card.")
		await get_tree().create_timer(0.5).timeout
	
	is_first_turn = false
	change_state(GameState.AI_TURN_PLAY)
	emit_signal("message_updated", "AI is thinking...")
	
	await get_tree().create_timer(1.0).timeout
	AI.play_turn()

func start_opponent_turn_multiplayer():
	# Opponent draws a card (we don't see their hand in detail)
	if not (is_first_turn and not is_player_first):
		ai_hand.append(draw_card_from_deck(false))
		emit_signal("hand_updated", false)
		var opponent_name = NetworkManager.opponent_name if NetworkManager else "Opponent"
		emit_signal("message_updated", opponent_name + " drew a card.")
		await get_tree().create_timer(0.5).timeout
	
	is_first_turn = false
	change_state(GameState.OPPONENT_TURN)
	var opponent_name = NetworkManager.opponent_name if NetworkManager else "Opponent"
	emit_signal("message_updated", "Waiting for " + opponent_name + "'s move...")

func change_state(new_state: GameState):
	current_state = new_state
	emit_signal("game_state_changed", new_state)

func player_play_card(hand_index: int):
	# Add error handling to prevent crashes
	if current_state != GameState.PLAYER_TURN_PLAY:
		print("[GameManager] ERROR: Cannot play card, not player turn. State: ", current_state)
		return
	if hand_index < 0 or hand_index >= player_hand.size():
		print("[GameManager] ERROR: Invalid hand index: ", hand_index, ", hand size: ", player_hand.size())
		return
	
	# Validate hand is not empty
	if player_hand.is_empty():
		print("[GameManager] ERROR: Cannot play card, hand is empty!")
		return
	
	var card = player_hand[hand_index]
	
	# Remove card from hand with error handling
	if hand_index < player_hand.size():
		player_hand.remove_at(hand_index)
	else:
		print("[GameManager] ERROR: Hand index out of bounds when removing card!")
		return
	
	emit_signal("hand_updated", true)
	
	# Place card on field IMMEDIATELY (visually) before reaction window
	player_field.append(card)
	emit_signal("field_updated", true)
	emit_signal("card_played", card, true)
	
	# In multiplayer, broadcast the play with error handling
	if is_multiplayer_game and NetworkManager:
		if NetworkManager.has_method("broadcast_card_play"):
			NetworkManager.broadcast_card_play(card)
		else:
			print("[GameManager] WARNING: NetworkManager.broadcast_card_play not available")
	
	pending_card = card
	pending_is_player = true
	reaction_chain.clear()
	
	var opponent_name = "Opponent" if is_multiplayer_game else "AI"
	if NetworkManager and is_multiplayer_game:
		opponent_name = NetworkManager.opponent_name if NetworkManager.opponent_name else "Opponent"
	
	emit_signal("message_updated", "You played " + CARD_NAMES[card] + ". " + opponent_name + " can react...")
	change_state(GameState.REACTION_WINDOW)
	
	# Wrap reaction window in error handling
	var reaction_error = false
	if start_reaction_window:
		# Use call_deferred to prevent crashes
		await start_reaction_window(card, false)
	else:
		print("[GameManager] ERROR: start_reaction_window is not a valid function!")
		reaction_error = true
	
	if reaction_error:
		# Fallback: just continue the game
		print("[GameManager] Reaction window failed, continuing game")
		change_state(GameState.AI_TURN_PLAY if not is_multiplayer_game else GameState.OPPONENT_TURN)

# Called when remote opponent plays a card (multiplayer)
func _on_opponent_played_card(card_type: int):
	if not is_multiplayer_game:
		return
	
	var card = card_type as CardType
	
	# Remove the specific card from opponent's hand
	var card_idx = ai_hand.find(card)
	if card_idx >= 0:
		ai_hand.remove_at(card_idx)
	elif ai_hand.size() > 0:
		# Fallback: remove first card if specific card not found (shouldn't happen)
		ai_hand.remove_at(0)
		print("[GameManager] Warning: Opponent played card not in our view of their hand")
	emit_signal("hand_updated", false)
	
	# Place card on field IMMEDIATELY before reaction window
	ai_field.append(card)
	emit_signal("field_updated", false)
	emit_signal("card_played", card, false)
	
	pending_card = card
	pending_is_player = false
	reaction_chain.clear()
	
	var opponent_name = NetworkManager.opponent_name if NetworkManager else "Opponent"
	emit_signal("message_updated", opponent_name + " played " + CARD_NAMES[card] + "!")
	change_state(GameState.REACTION_WINDOW)
	
	# Start reaction window - local player can react
	await start_reaction_window(card, true)

func start_reaction_window(card: CardType, is_player_reacting: bool):
	awaiting_reaction = true
	emit_signal("reaction_window_started", card, is_player_reacting)
	
	if is_player_reacting:
		emit_signal("message_updated", "React with Water + " + CARD_NAMES[card] + "? (5 seconds)")
	else:
		if is_multiplayer_game:
			# Wait for remote opponent's reaction
			var opponent_name = NetworkManager.opponent_name if NetworkManager else "Opponent"
			emit_signal("message_updated", "Waiting for " + opponent_name + "'s reaction...")
			# Reaction will come via _on_opponent_reacted
		else:
			# AI decides
			await get_tree().create_timer(1.5).timeout
			if awaiting_reaction:
				var ai_reacts = AI.decide_reaction(card, reaction_chain.size())
				if ai_reacts:
					await execute_reaction(false)
				else:
					await end_reaction_window(false)

func execute_reaction(is_player: bool):
	var reactor_hand = player_hand if is_player else ai_hand
	var reactor_discard = player_discard if is_player else ai_discard
	
	var is_counter_block = reaction_chain.size() > 0 and reaction_chain[-1]["is_player"] != is_player
	
	# In multiplayer, if it's the opponent's reaction, trust their claim
	# (they already validated on their end before sending)
	var is_remote_reaction = is_multiplayer_game and not is_player
	
	if is_counter_block:
		var water_count = reactor_hand.count(CardType.WATER)
		if water_count >= 2 or is_remote_reaction:
			# Remove 2 water cards if we can find them
			var removed_count = 0
			for i in range(2):
				var idx = reactor_hand.find(CardType.WATER)
				if idx >= 0:
					var water_card = reactor_hand[idx]
					reactor_hand.remove_at(idx)
					reactor_discard.append(water_card)
					removed_count += 1
			# If remote reaction and we couldn't find enough waters, still remove cards to sync count
			while removed_count < 2 and reactor_hand.size() > 0 and is_remote_reaction:
				reactor_discard.append(reactor_hand[0])
				reactor_hand.remove_at(0)
				removed_count += 1
			
			reaction_chain.append({"is_player": is_player, "type": "counter_block"})
			emit_signal("hand_updated", is_player)
			emit_signal("discard_updated", is_player)
			
			var reactor_name = "You" if is_player else (NetworkManager.opponent_name if is_multiplayer_game and NetworkManager else "AI")
			emit_signal("message_updated", reactor_name + " counter-blocked with 2 Water!")
			
			if reaction_chain.size() < max_reaction_depth:
				await get_tree().create_timer(0.5).timeout
				# Give the other player a chance to counter
				print("[GameManager] Starting counter-block window for: ", "player" if not is_player else "opponent")
				await start_reaction_window(pending_card, not is_player)
			else:
				await end_reaction_window(true)
		else:
			emit_signal("message_updated", "Not enough Water cards to counter-block!")
	else:
		var water_idx = reactor_hand.find(CardType.WATER)
		var match_idx = reactor_hand.find(pending_card)
		
		if pending_card == CardType.WATER and water_idx == match_idx:
			if reactor_hand.count(CardType.WATER) >= 2:
				match_idx = -1
				for i in range(reactor_hand.size()):
					if reactor_hand[i] == CardType.WATER and i != water_idx:
						match_idx = i
						break
		
		# Valid block if we can find the cards OR if it's a remote reaction (trust opponent)
		var can_block = (water_idx != -1 and match_idx != -1 and water_idx != match_idx) or is_remote_reaction
		
		if can_block:
			# Remove the cards if we can find them
			if water_idx != -1 and match_idx != -1 and water_idx != match_idx:
				var cards_to_remove = [water_idx, match_idx]
				cards_to_remove.sort()
				cards_to_remove.reverse()
				for idx in cards_to_remove:
					reactor_discard.append(reactor_hand[idx])
					reactor_hand.remove_at(idx)
			elif is_remote_reaction:
				# Trust the opponent - remove 2 cards from their hand
				# Try to find the specific cards, otherwise remove any 2
				var removed = 0
				var w_idx = reactor_hand.find(CardType.WATER)
				if w_idx >= 0:
					reactor_discard.append(reactor_hand[w_idx])
					reactor_hand.remove_at(w_idx)
					removed += 1
				var m_idx = reactor_hand.find(pending_card)
				if m_idx >= 0:
					reactor_discard.append(reactor_hand[m_idx])
					reactor_hand.remove_at(m_idx)
					removed += 1
				# If we couldn't find the right cards, still remove cards to keep count synced
				while removed < 2 and reactor_hand.size() > 0:
					reactor_discard.append(reactor_hand[0])
					reactor_hand.remove_at(0)
					removed += 1
			
			reaction_chain.append({"is_player": is_player, "type": "block"})
			emit_signal("hand_updated", is_player)
			emit_signal("discard_updated", is_player)
			
			var reactor_name = "You" if is_player else (NetworkManager.opponent_name if is_multiplayer_game and NetworkManager else "AI")
			emit_signal("message_updated", reactor_name + " blocked with Water + " + CARD_NAMES[pending_card] + "!")
			
			if reaction_chain.size() < max_reaction_depth:
				await get_tree().create_timer(0.5).timeout
				# Give the other player a chance to counter-block
				print("[GameManager] Starting counter-block window for: ", "player" if not is_player else "opponent")
				await start_reaction_window(pending_card, not is_player)
			else:
				await end_reaction_window(true)
		else:
			emit_signal("message_updated", "Cannot block - need Water + " + CARD_NAMES[pending_card])

func player_react():
	if awaiting_reaction:
		if is_multiplayer_game and NetworkManager:
			NetworkManager.broadcast_reaction(true)
		await execute_reaction(true)

func player_pass_reaction():
	if awaiting_reaction:
		if is_multiplayer_game and NetworkManager:
			NetworkManager.broadcast_reaction(false)
		await end_reaction_window(false)

func _on_opponent_reacted(did_react: bool):
	if not awaiting_reaction:
		print("[GameManager] Received reaction but not awaiting - ignoring")
		return
	
	print("[GameManager] Opponent reacted: ", did_react, ", chain size: ", reaction_chain.size())
	
	if did_react:
		# Opponent is blocking/counter-blocking - process their reaction
		# This will give us a chance to counter-block if successful
		awaiting_reaction = false  # Reset before processing
		await execute_reaction(false)
	else:
		await end_reaction_window(false)

func end_reaction_window(was_blocked: bool):
	awaiting_reaction = false
	emit_signal("reaction_window_ended")
	
	var blocked = false
	var blocker_is_player = false
	if reaction_chain.size() > 0:
		blocked = reaction_chain.size() % 2 == 1
		if blocked:
			blocker_is_player = reaction_chain[-1]["is_player"]
	
	if blocked:
		# Card is already on field - emit blocked signal (animation will play on the card)
		emit_signal("card_blocked", pending_card, pending_is_player, blocker_is_player)
		
		var player_name = "Your" if pending_is_player else (NetworkManager.opponent_name + "'s" if is_multiplayer_game and NetworkManager else "AI's")
		emit_signal("message_updated", player_name + " " + CARD_NAMES[pending_card] + " was blocked!")
		
		# Wait for block animation to complete
		await get_tree().create_timer(2.5).timeout
		
		# NOW remove from field and add to discard
		var field = player_field if pending_is_player else ai_field
		var discard_pile = player_discard if pending_is_player else ai_discard
		
		# Find and remove the pending card from field
		var card_idx = field.rfind(pending_card)
		if card_idx >= 0:
			field.remove_at(card_idx)
		discard_pile.append(pending_card)
		
		emit_signal("field_updated", pending_is_player)
		emit_signal("discard_updated", pending_is_player)
		
		await end_turn()
	else:
		await resolve_card()

func resolve_card():
	# Card is already on field from when it was played - just emit resolved signal
	# Emit resolved signal for success animation
	emit_signal("card_resolved", pending_card, pending_is_player)
	
	var player_name = "You" if pending_is_player else (NetworkManager.opponent_name if is_multiplayer_game and NetworkManager else "AI")
	emit_signal("message_updated", player_name + "'s " + CARD_NAMES[pending_card] + " resolved!")
	
	if check_win_condition(pending_is_player):
		return
	
	# Wait for success animation
	await get_tree().create_timer(1.2).timeout
	await execute_effect(pending_card, pending_is_player)
	
	if check_win_condition(true) or check_win_condition(false):
		return
	
	await end_turn()

func execute_effect(card: CardType, is_player: bool):
	match card:
		CardType.FIRE:
			await fire_effect(is_player)
		CardType.GRASS:
			await grass_effect(is_player)
		CardType.LIGHTNING:
			await lightning_effect(is_player)
		CardType.DARKNESS:
			await darkness_effect(is_player)
		CardType.WATER:
			await water_effect(is_player)

func fire_effect(is_player: bool):
	var opponent_field = ai_field if is_player else player_field
	
	if opponent_field.is_empty():
		emit_signal("message_updated", "Fire effect: No cards to remove.")
		return
	
	if is_player:
		emit_signal("message_updated", "Fire effect: Choose an opponent's card to remove.")
		emit_signal("effect_target_needed", "fire")
		change_state(GameState.PLAYER_EFFECT)
		waiting_for_player_effect = true
		await player_effect_completed
		waiting_for_player_effect = false
	else:
		if is_multiplayer_game:
			# Wait for opponent's choice
			emit_signal("message_updated", "Waiting for opponent to choose target...")
			change_state(GameState.AI_EFFECT)
			waiting_for_player_effect = true
			await player_effect_completed
			waiting_for_player_effect = false
		else:
			var target_idx = AI.choose_fire_target()
			complete_fire_effect(false, target_idx)

func complete_fire_effect(is_player: bool, target_idx: int):
	var opponent_field = ai_field if is_player else player_field
	var opponent_discard = ai_discard if is_player else player_discard
	
	if target_idx >= 0 and target_idx < opponent_field.size():
		var removed = opponent_field[target_idx]
		
		# Emit signal for animation BEFORE removing card
		emit_signal("fire_effect_triggered", removed, not is_player)
		
		# Wait for animation
		await get_tree().create_timer(1.5).timeout
		
		opponent_field.remove_at(target_idx)
		opponent_discard.append(removed)
		emit_signal("field_updated", not is_player)
		emit_signal("discard_updated", not is_player)
		emit_signal("message_updated", "Fire removed " + CARD_NAMES[removed] + " from opponent's field!")
	
	if is_player and is_multiplayer_game and NetworkManager:
		NetworkManager.broadcast_effect_choice({"type": "fire", "target": target_idx})
	
	if is_player or (is_multiplayer_game and not is_player):
		emit_signal("player_effect_completed")

func grass_effect(is_player: bool):
	var discard = player_discard if is_player else ai_discard
	
	if discard.is_empty():
		emit_signal("message_updated", "Grass effect: No cards in discard.")
		return
	
	if is_player:
		emit_signal("message_updated", "Grass effect: Choose a card from your discard.")
		emit_signal("effect_target_needed", "grass")
		change_state(GameState.PLAYER_EFFECT)
		waiting_for_player_effect = true
		await player_effect_completed
		waiting_for_player_effect = false
	else:
		if is_multiplayer_game:
			emit_signal("message_updated", "Waiting for opponent to choose card...")
			change_state(GameState.AI_EFFECT)
			waiting_for_player_effect = true
			await player_effect_completed
			waiting_for_player_effect = false
		else:
			var target_idx = AI.choose_grass_target()
			complete_grass_effect(false, target_idx)

func complete_grass_effect(is_player: bool, target_idx: int):
	var discard = player_discard if is_player else ai_discard
	var hand = player_hand if is_player else ai_hand
	
	if target_idx >= 0 and target_idx < discard.size():
		var retrieved = discard[target_idx]
		
		# Emit signal for animation BEFORE moving card
		emit_signal("grass_effect_triggered", retrieved, is_player)
		
		# Wait for animation
		await get_tree().create_timer(1.5).timeout
		
		discard.remove_at(target_idx)
		hand.append(retrieved)
		emit_signal("discard_updated", is_player)
		emit_signal("hand_updated", is_player)
		var player_name = "You" if is_player else (NetworkManager.opponent_name if is_multiplayer_game and NetworkManager else "AI")
		emit_signal("message_updated", player_name + " retrieved " + CARD_NAMES[retrieved] + " from discard!")
	
	if is_player and is_multiplayer_game and NetworkManager:
		NetworkManager.broadcast_effect_choice({"type": "grass", "target": target_idx})
	
	if is_player or (is_multiplayer_game and not is_player):
		emit_signal("player_effect_completed")

func lightning_effect(is_player: bool):
	var hand = player_hand if is_player else ai_hand
	var drawn_card = draw_card_from_deck(is_player)
	
	# Emit signal for animation BEFORE adding to hand
	emit_signal("lightning_effect_triggered", drawn_card, is_player)
	
	# Wait for animation
	await get_tree().create_timer(0.8).timeout
	
	hand.append(drawn_card)
	emit_signal("hand_updated", is_player)
	var player_name = "You" if is_player else (NetworkManager.opponent_name if is_multiplayer_game and NetworkManager else "AI")
	emit_signal("message_updated", player_name + " drew a card from Lightning effect!")

func darkness_effect(is_player: bool):
	var opponent_hand = ai_hand if is_player else player_hand
	
	if opponent_hand.is_empty():
		emit_signal("message_updated", "Darkness effect: Opponent has no cards in hand.")
		return
	
	# Emit signal for animation BEFORE removing card
	emit_signal("darkness_effect_triggered", not is_player)
	
	# Wait for animation
	await get_tree().create_timer(1.2).timeout
	
	var random_idx = randi() % opponent_hand.size()
	var discarded = opponent_hand[random_idx]
	opponent_hand.remove_at(random_idx)
	var opponent_discard = ai_discard if is_player else player_discard
	opponent_discard.append(discarded)
	
	emit_signal("hand_updated", not is_player)
	emit_signal("discard_updated", not is_player)
	
	var player_name = "You" if is_player else (NetworkManager.opponent_name if is_multiplayer_game and NetworkManager else "AI")
	emit_signal("message_updated", player_name + " discarded a random card from opponent's hand!")

func water_effect(is_player: bool):
	var deck = player_deck if is_player else ai_deck
	
	if deck.is_empty():
		reshuffle_discard_into_deck(is_player)
		deck = player_deck if is_player else ai_deck
	
	if deck.is_empty():
		emit_signal("message_updated", "Water effect: No cards in deck to look at.")
		return
	
	if is_player:
		var top_card = player_deck[-1]
		emit_signal("message_updated", "Water: Top card is " + CARD_NAMES[top_card] + ". Move to bottom?")
		emit_signal("effect_target_needed", "water")
		change_state(GameState.PLAYER_EFFECT)
		waiting_for_player_effect = true
		await player_effect_completed
		waiting_for_player_effect = false
	else:
		if is_multiplayer_game:
			emit_signal("message_updated", "Waiting for opponent's choice...")
			change_state(GameState.AI_EFFECT)
			waiting_for_player_effect = true
			await player_effect_completed
			waiting_for_player_effect = false
		else:
			var move_to_bottom = AI.decide_water_effect()
			complete_water_effect(false, move_to_bottom)

func complete_water_effect(is_player: bool, move_to_bottom: bool):
	var deck = player_deck if is_player else ai_deck
	
	if move_to_bottom and not deck.is_empty():
		if is_player:
			var top_card = player_deck.pop_back()
			player_deck.insert(0, top_card)
		else:
			var top_card = ai_deck.pop_back()
			ai_deck.insert(0, top_card)
		emit_signal("message_updated", "Card moved to bottom of deck.")
	else:
		emit_signal("message_updated", "Card left on top.")
	
	if is_player and is_multiplayer_game and NetworkManager:
		NetworkManager.broadcast_effect_choice({"type": "water", "move_to_bottom": move_to_bottom})
	
	if is_player or (is_multiplayer_game and not is_player):
		emit_signal("player_effect_completed")

func _on_opponent_effect_choice(choice_data: Dictionary):
	if not is_multiplayer_game:
		return
	
	match choice_data.get("type", ""):
		"fire":
			complete_fire_effect(false, choice_data.get("target", 0))
		"grass":
			complete_grass_effect(false, choice_data.get("target", 0))
		"water":
			complete_water_effect(false, choice_data.get("move_to_bottom", false))

func check_win_condition(is_player: bool) -> bool:
	var field = player_field if is_player else ai_field
	
	var types_present = {}
	for card in field:
		types_present[card] = true
	if types_present.size() == 5:
		declare_winner(is_player, "one of each type")
		return true
	
	var type_counts = {}
	for card in field:
		type_counts[card] = type_counts.get(card, 0) + 1
		if type_counts[card] >= 5:
			declare_winner(is_player, "5 " + CARD_NAMES[card] + " cards")
			return true
	
	return false

func declare_winner(is_player: bool, reason: String):
	change_state(GameState.GAME_OVER)
	var winner = "You win" if is_player else (NetworkManager.opponent_name + " wins" if is_multiplayer_game and NetworkManager else "AI wins")
	emit_signal("message_updated", winner + " with " + reason + "!")
	emit_signal("game_over", is_player)

func end_turn():
	turn_count += 1
	reaction_chain.clear()
	
	await get_tree().create_timer(0.5).timeout
	
	if pending_is_player:
		if is_multiplayer_game:
			await start_opponent_turn_multiplayer()
		else:
			await start_ai_turn()
	else:
		await start_player_turn()

func get_opponent_name() -> String:
	if is_multiplayer_game and NetworkManager:
		return NetworkManager.opponent_name
	return "AI"
