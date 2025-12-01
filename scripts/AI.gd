extends Node

func _ready():
	pass

func play_turn():
	if GameManager.ai_hand.is_empty():
		GameManager.emit_signal("message_updated", "AI has no cards to play!")
		await GameManager.end_turn()
		return
	
	# AI strategy: prioritize winning, then disruption, then draw
	var best_card_idx = choose_best_card()
	var card = GameManager.ai_hand[best_card_idx]
	
	GameManager.ai_hand.remove_at(best_card_idx)
	GameManager.emit_signal("hand_updated", false)
	
	# Place card on field IMMEDIATELY (visually) before reaction window
	GameManager.ai_field.append(card)
	GameManager.emit_signal("field_updated", false)
	GameManager.emit_signal("card_played", card, false)
	
	# Start reaction window for player
	GameManager.pending_card = card
	GameManager.pending_is_player = false
	GameManager.reaction_chain.clear()
	
	GameManager.emit_signal("message_updated", "AI played " + GameManager.CARD_NAMES[card] + "!")
	GameManager.change_state(GameManager.GameState.REACTION_WINDOW)
	await GameManager.start_reaction_window(card, true)

func choose_best_card() -> int:
	var hand = GameManager.ai_hand
	var field = GameManager.ai_field
	var best_idx = 0
	var best_score = -100
	
	for i in range(hand.size()):
		var card = hand[i]
		var score = evaluate_card(card, field)
		if score > best_score:
			best_score = score
			best_idx = i
	
	return best_idx

func evaluate_card(card: GameManager.CardType, field: Array) -> int:
	var score = 0
	var type_counts = {}
	var unique_types = {}
	
	for f_card in field:
		type_counts[f_card] = type_counts.get(f_card, 0) + 1
		unique_types[f_card] = true
	
	# Check if this card would win
	type_counts[card] = type_counts.get(card, 0) + 1
	unique_types[card] = true
	
	if type_counts[card] >= 5:
		return 1000  # Winning move!
	
	if unique_types.size() >= 5:
		return 1000  # Winning move!
	
	# Prioritize getting closer to win
	if type_counts[card] == 4:
		score += 50
	elif type_counts[card] == 3:
		score += 30
	
	if unique_types.size() == 4 and not unique_types.has(card):
		score += 40
	
	# Card-specific value
	match card:
		GameManager.CardType.FIRE:
			if GameManager.player_field.size() > 0:
				score += 25
		GameManager.CardType.GRASS:
			if GameManager.ai_discard.size() > 0:
				score += 15
		GameManager.CardType.LIGHTNING:
			score += 20  # Drawing is always good
		GameManager.CardType.DARKNESS:
			if GameManager.player_hand.size() > 0:
				score += 20
		GameManager.CardType.WATER:
			score += 10  # Utility
	
	return score

func decide_reaction(card: GameManager.CardType, chain_depth: int) -> bool:
	if chain_depth >= GameManager.max_reaction_depth - 1:
		return false
	
	var hand = GameManager.ai_hand
	
	if chain_depth == 0:
		# Initial block decision
		var water_idx = hand.find(GameManager.CardType.WATER)
		var match_idx = hand.find(card)
		
		if card == GameManager.CardType.WATER:
			if hand.count(GameManager.CardType.WATER) >= 2:
				# Only block if the card is very threatening
				return is_threatening_card(card)
			return false
		
		if water_idx != -1 and match_idx != -1:
			# Only block if the card is threatening
			return is_threatening_card(card)
	else:
		# Counter-block decision
		if hand.count(GameManager.CardType.WATER) >= 2:
			# Counter if we really want our card to resolve
			return randf() > 0.5
	
	return false

func is_threatening_card(card: GameManager.CardType) -> bool:
	match card:
		GameManager.CardType.FIRE:
			return GameManager.ai_field.size() > 2
		GameManager.CardType.DARKNESS:
			return GameManager.ai_hand.size() <= 2
		GameManager.CardType.LIGHTNING:
			return GameManager.player_hand.size() < 2
		_:
			# Check if it would help player win
			var temp_field = GameManager.player_field.duplicate()
			temp_field.append(card)
			var type_counts = {}
			var unique = {}
			for c in temp_field:
				type_counts[c] = type_counts.get(c, 0) + 1
				unique[c] = true
			
			if type_counts.get(card, 0) >= 4 or unique.size() >= 4:
				return true
	return false

func choose_fire_target() -> int:
	var field = GameManager.player_field
	if field.is_empty():
		return -1
	
	# Prioritize removing cards that player has multiples of, or unique cards toward collection
	var type_counts = {}
	for card in field:
		type_counts[card] = type_counts.get(card, 0) + 1
	
	var best_idx = 0
	var best_score = 0
	
	for i in range(field.size()):
		var card = field[i]
		var score = 0
		
		# Prefer removing a card that would complete a set
		if type_counts.size() >= 4:
			# Player close to 1-of-each win
			score += 20
		
		if type_counts[card] >= 3:
			# Player close to 5-of-same win
			score += type_counts[card] * 10
		
		if score > best_score:
			best_score = score
			best_idx = i
	
	return best_idx

func choose_grass_target() -> int:
	var discard = GameManager.ai_discard
	if discard.is_empty():
		return -1
	
	# Prefer cards that help toward winning
	var field = GameManager.ai_field
	var type_counts = {}
	var unique = {}
	for card in field:
		type_counts[card] = type_counts.get(card, 0) + 1
		unique[card] = true
	
	var best_idx = 0
	var best_score = -1
	
	for i in range(discard.size()):
		var card = discard[i]
		var score = 0
		
		if type_counts.get(card, 0) >= 3:
			score += 50  # Close to 5-of-same
		if not unique.has(card) and unique.size() >= 3:
			score += 40  # Would add new type toward 1-of-each
		if card == GameManager.CardType.WATER:
			score += 15  # Water is versatile
		
		if score > best_score:
			best_score = score
			best_idx = i
	
	return best_idx

func decide_water_effect() -> bool:
	if GameManager.ai_deck.is_empty():
		return false
	
	var top_card = GameManager.ai_deck[-1]
	
	# Keep it on top if it helps us
	var field = GameManager.ai_field
	var type_counts = {}
	for card in field:
		type_counts[card] = type_counts.get(card, 0) + 1
	
	if type_counts.get(top_card, 0) >= 3:
		return false  # Keep it, we want it
	
	# Move to bottom if it doesn't help much
	return randf() > 0.5
