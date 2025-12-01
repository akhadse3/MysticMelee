extends Control
class_name EffectAnimations

# Animation for Fire effect - card burns away
class FireBurnEffect extends Control:
	var card_type: GameManager.CardType
	var card_color: Color
	var animation_time: float = 0.0
	var max_time: float = 1.5
	var particles: Array = []
	var card_alpha: float = 1.0
	var card_size: Vector2
	
	signal animation_finished
	
	func _ready():
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	func play(type: GameManager.CardType, rect: Rect2):
		if not SettingsManager.animations_enabled:
			emit_signal("animation_finished")
			queue_free()
			return
		
		card_type = type
		card_color = GameManager.CARD_COLORS[type]
		global_position = rect.position
		size = rect.size
		card_size = rect.size
		visible = true
		_generate_fire_particles()
	
	func _generate_fire_particles():
		for i in range(30):
			particles.append({
				"pos": Vector2(randf() * card_size.x, card_size.y * randf()),
				"vel": Vector2(randf_range(-20, 20), randf_range(-80, -30)),
				"size": randf_range(5, 12),
				"life": randf_range(0.8, 1.5),
				"max_life": 1.5,
				"delay": randf() * 0.5,
				"color_t": randf()
			})
	
	func _process(delta):
		animation_time += delta
		card_alpha = max(0, 1.0 - (animation_time / max_time) * 1.5)
		
		# Add more particles over time
		if animation_time < 0.8 and randf() < 0.3:
			particles.append({
				"pos": Vector2(randf() * card_size.x, randf() * card_size.y),
				"vel": Vector2(randf_range(-15, 15), randf_range(-60, -25)),
				"size": randf_range(4, 10),
				"life": randf_range(0.5, 1.0),
				"max_life": 1.0,
				"delay": 0,
				"color_t": randf()
			})
		
		for p in particles:
			if p["delay"] > 0:
				p["delay"] -= delta
				continue
			p["life"] -= delta
			p["pos"] += p["vel"] * delta
			p["vel"].y -= 20 * delta  # Rise faster
		
		particles = particles.filter(func(p): return p["life"] > 0 or p["delay"] > 0)
		queue_redraw()
		
		if animation_time >= max_time:
			emit_signal("animation_finished")
			queue_free()
	
	func _draw():
		# Draw burning card
		if card_alpha > 0:
			var burn_color = card_color
			burn_color.a = card_alpha
			# Add orange tint as it burns
			burn_color = burn_color.lerp(Color(1, 0.5, 0.1), 1.0 - card_alpha)
			draw_rect(Rect2(Vector2.ZERO, card_size), burn_color)
			
			# Draw card border
			var border_color = Color(1, 0.6, 0.2, card_alpha)
			draw_rect(Rect2(Vector2.ZERO, card_size), border_color, false, 2)
		
		# Draw fire particles
		for p in particles:
			if p["delay"] > 0:
				continue
			var alpha = clamp(p["life"] / p["max_life"], 0, 1)
			var t = p["color_t"]
			# Glow
			draw_circle(p["pos"], p["size"] * 1.5, Color(1, 0.5, 0.1, alpha * 0.3))
			# Flame
			var color = Color(1.0, 0.7 - t * 0.5, 0.1, alpha * 0.9)
			draw_circle(p["pos"], p["size"], color)
			# Core
			draw_circle(p["pos"], p["size"] * 0.4, Color(1, 1, 0.7, alpha))


# Animation for Darkness effect - card dissolves from hand
class DarknessDissolveEffect extends Control:
	var animation_time: float = 0.0
	var max_time: float = 1.2
	var particles: Array = []
	var card_size: Vector2 = Vector2(80, 120)
	var dissolve_progress: float = 0.0
	
	signal animation_finished
	
	func _ready():
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	func play(rect: Rect2):
		if not SettingsManager.animations_enabled:
			emit_signal("animation_finished")
			queue_free()
			return
		
		global_position = rect.position
		size = rect.size
		card_size = rect.size
		visible = true
		_generate_dissolve_particles()
	
	func _generate_dissolve_particles():
		# Create grid of particles representing the card
		var cols = 8
		var rows = 12
		var cell_w = card_size.x / cols
		var cell_h = card_size.y / rows
		
		for row in range(rows):
			for col in range(cols):
				var delay = (row * 0.05) + randf() * 0.2  # Top dissolves first
				particles.append({
					"pos": Vector2(col * cell_w + cell_w/2, row * cell_h + cell_h/2),
					"original_pos": Vector2(col * cell_w + cell_w/2, row * cell_h + cell_h/2),
					"vel": Vector2(randf_range(-30, 30), randf_range(-50, -20)),
					"size": max(cell_w, cell_h) * 0.6,
					"alpha": 1.0,
					"delay": delay,
					"dissolving": false
				})
	
	func _process(delta):
		animation_time += delta
		dissolve_progress = animation_time / max_time
		
		for p in particles:
			if p["delay"] > 0:
				p["delay"] -= delta
				if p["delay"] <= 0:
					p["dissolving"] = true
				continue
			
			if p["dissolving"]:
				p["pos"] += p["vel"] * delta
				p["vel"] += Vector2(randf_range(-10, 10), -30) * delta
				p["alpha"] = max(0, p["alpha"] - delta * 1.5)
				p["size"] *= 0.98
		
		queue_redraw()
		
		if animation_time >= max_time:
			emit_signal("animation_finished")
			queue_free()
	
	func _draw():
		# Draw card back being dissolved
		for p in particles:
			if p["alpha"] <= 0:
				continue
			
			var color: Color
			if not p["dissolving"]:
				color = Color(0.2, 0.15, 0.3, p["alpha"])
			else:
				color = Color(0.3, 0.1, 0.4, p["alpha"] * 0.8)
			
			draw_circle(p["pos"], p["size"], color)
			
			# Purple void effect on dissolving particles
			if p["dissolving"]:
				draw_circle(p["pos"], p["size"] * 0.5, Color(0.5, 0.2, 0.6, p["alpha"] * 0.5))


# Animation for Grass effect - card grows from discard with vines
class GrassGrowEffect extends Control:
	var card_type: GameManager.CardType
	var card_color: Color
	var animation_time: float = 0.0
	var max_time: float = 1.5
	var start_pos: Vector2
	var end_pos: Vector2
	var card_size: Vector2
	var vines: Array = []
	var current_pos: Vector2
	
	signal animation_finished
	
	func _ready():
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	func play(type: GameManager.CardType, from_rect: Rect2, to_rect: Rect2):
		if not SettingsManager.animations_enabled:
			emit_signal("animation_finished")
			queue_free()
			return
		
		card_type = type
		card_color = GameManager.CARD_COLORS[type]
		start_pos = from_rect.position + from_rect.size / 2
		end_pos = to_rect.position + to_rect.size / 2
		card_size = to_rect.size
		current_pos = start_pos
		
		# Position at screen level
		global_position = Vector2.ZERO
		size = get_viewport_rect().size
		visible = true
		
		_generate_vines()
	
	func _generate_vines():
		# Create trailing vines
		for i in range(5):
			vines.append({
				"offset": Vector2(randf_range(-20, 20), randf_range(20, 40)),
				"segments": [],
				"growth": 0.0
			})
	
	func _process(delta):
		animation_time += delta
		var t = clamp(animation_time / max_time, 0, 1)
		
		# Ease out movement
		var ease_t = 1.0 - pow(1.0 - t, 3)
		current_pos = start_pos.lerp(end_pos, ease_t)
		
		# Update vine growth
		for vine in vines:
			vine["growth"] = min(1.0, vine["growth"] + delta * 2)
			
			# Add segments trailing behind the card
			if vine["segments"].size() < 20 and randf() < 0.4:
				var trail_t = max(0, ease_t - 0.1)
				var trail_pos = start_pos.lerp(end_pos, trail_t)
				vine["segments"].append({
					"pos": trail_pos + vine["offset"] + Vector2(randf_range(-10, 10), randf_range(-10, 10)),
					"size": randf_range(3, 6),
					"alpha": 1.0
				})
		
		# Fade out vine segments
		for vine in vines:
			for seg in vine["segments"]:
				seg["alpha"] = max(0, seg["alpha"] - delta * 0.8)
			vine["segments"] = vine["segments"].filter(func(s): return s["alpha"] > 0)
		
		queue_redraw()
		
		if animation_time >= max_time:
			emit_signal("animation_finished")
			queue_free()
	
	func _draw():
		# Draw vines trailing from discard
		for vine in vines:
			var prev_pos = current_pos + vine["offset"]
			for seg in vine["segments"]:
				var color = Color(0.3, 0.7, 0.3, seg["alpha"] * 0.8)
				draw_line(prev_pos, seg["pos"], color, 3)
				draw_circle(seg["pos"], seg["size"], Color(0.2, 0.6, 0.2, seg["alpha"]))
				prev_pos = seg["pos"]
			
			# Draw leaves on vine
			if vine["segments"].size() > 0:
				for i in range(0, vine["segments"].size(), 3):
					var seg = vine["segments"][i]
					var leaf_color = Color(0.4, 0.85, 0.4, seg["alpha"] * 0.9)
					_draw_leaf(seg["pos"], randf() * TAU, seg["size"] * 1.5, leaf_color)
		
		# Draw the card
		var card_rect = Rect2(current_pos - card_size / 2, card_size)
		draw_rect(card_rect, card_color)
		draw_rect(card_rect, card_color.lightened(0.3), false, 2)
		
		# Draw card symbol
		var font = ThemeDB.fallback_font
		var symbol = GameManager.CARD_SYMBOLS[card_type]
		var symbol_pos = current_pos - Vector2(10, -5)
		draw_string(font, symbol_pos, symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
		
		# Draw roots at bottom of card
		var root_base = current_pos + Vector2(0, card_size.y / 2)
		for i in range(3):
			var root_end = root_base + Vector2(randf_range(-20, 20), randf_range(10, 25))
			draw_line(root_base, root_end, Color(0.4, 0.3, 0.2, 0.8), 2)
	
	func _draw_leaf(pos: Vector2, rot: float, leaf_size: float, color: Color):
		var points = PackedVector2Array()
		points.append(pos + Vector2(0, -leaf_size).rotated(rot))
		points.append(pos + Vector2(leaf_size * 0.4, 0).rotated(rot))
		points.append(pos + Vector2(0, leaf_size * 0.3).rotated(rot))
		points.append(pos + Vector2(-leaf_size * 0.4, 0).rotated(rot))
		draw_colored_polygon(points, color)


# Animation for Lightning effect - bolt strikes and card appears
class LightningStrikeEffect extends Control:
	var card_type: GameManager.CardType
	var card_color: Color
	var animation_time: float = 0.0
	var max_time: float = 0.8
	var target_pos: Vector2
	var card_size: Vector2
	var bolt_points: Array = []
	var flash_alpha: float = 0.0
	var card_alpha: float = 0.0
	var show_card_face: bool = true  # Whether to reveal the card type
	
	signal animation_finished
	
	func _ready():
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	func play(type: GameManager.CardType, target_rect: Rect2, reveal_card: bool = true):
		if not SettingsManager.animations_enabled:
			emit_signal("animation_finished")
			queue_free()
			return
		
		card_type = type
		card_color = GameManager.CARD_COLORS[type]
		show_card_face = reveal_card
		target_pos = target_rect.position + target_rect.size / 2
		card_size = target_rect.size
		
		global_position = Vector2.ZERO
		size = get_viewport_rect().size
		visible = true
		
		_generate_bolt()
	
	func _generate_bolt():
		bolt_points.clear()
		var start = Vector2(target_pos.x + randf_range(-50, 50), -50)
		var end = target_pos
		
		var segments = 8
		bolt_points.append(start)
		
		for i in range(1, segments):
			var t = float(i) / segments
			var pos = start.lerp(end, t)
			pos.x += randf_range(-40, 40)
			bolt_points.append(pos)
		
		bolt_points.append(end)
	
	func _process(delta):
		animation_time += delta
		var t = animation_time / max_time
		
		# Flash at the start
		if t < 0.1:
			flash_alpha = t / 0.1 * 0.5
		elif t < 0.3:
			flash_alpha = 0.5 * (1.0 - (t - 0.1) / 0.2)
		else:
			flash_alpha = 0.0
		
		# Card fades in after bolt
		if t > 0.2:
			card_alpha = min(1.0, (t - 0.2) / 0.3)
		
		# Regenerate bolt for flickering
		if t < 0.4 and int(animation_time * 30) % 3 == 0:
			_generate_bolt()
		
		queue_redraw()
		
		if animation_time >= max_time:
			emit_signal("animation_finished")
			queue_free()
	
	func _draw():
		# Draw flash
		if flash_alpha > 0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, flash_alpha))
		
		# Draw lightning bolt
		var bolt_alpha = 1.0 - clamp((animation_time - 0.3) / 0.2, 0, 1)
		if bolt_alpha > 0 and bolt_points.size() > 1:
			for i in range(bolt_points.size() - 1):
				# Glow
				draw_line(bolt_points[i], bolt_points[i + 1], Color(0.5, 0.7, 1.0, bolt_alpha * 0.4), 12)
				# Main bolt
				draw_line(bolt_points[i], bolt_points[i + 1], Color(0.8, 0.9, 1.0, bolt_alpha * 0.8), 4)
				# Core
				draw_line(bolt_points[i], bolt_points[i + 1], Color(1, 1, 1, bolt_alpha), 2)
			
			# Sparks at impact point
			for j in range(5):
				var spark_pos = target_pos + Vector2(randf_range(-30, 30), randf_range(-30, 30))
				draw_circle(spark_pos, randf_range(2, 5), Color(1, 1, 0.8, bolt_alpha * 0.8))
		
		# Draw card appearing
		if card_alpha > 0:
			var card_rect = Rect2(target_pos - card_size / 2, card_size)
			
			if show_card_face:
				# Show actual card color and type
				var color = card_color
				color.a = card_alpha
				draw_rect(card_rect, color)
				draw_rect(card_rect, color.lightened(0.3), false, 2)
			else:
				# Show card back (opponent's draw - don't reveal card type)
				var back_color = Color(0.2, 0.15, 0.3, card_alpha)
				draw_rect(card_rect, back_color)
				draw_rect(card_rect, Color(0.5, 0.4, 0.6, card_alpha), false, 2)
				# Draw card back pattern
				var center = target_pos
				var pattern_color = Color(0.4, 0.3, 0.5, card_alpha * 0.5)
				draw_circle(center, 15, pattern_color)
				draw_rect(card_rect.grow(-10), pattern_color, false, 1)
			
			# Electric glow around new card
			var glow_alpha = card_alpha * (1.0 - (animation_time - 0.5) / 0.3)
			if glow_alpha > 0:
				draw_rect(card_rect.grow(5), Color(0.7, 0.9, 1.0, glow_alpha * 0.5), false, 3)
