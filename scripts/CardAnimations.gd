extends Control
class_name CardAnimations

# One-time success animations for when cards are successfully played

var animation_time: float = 0.0
var max_time: float = 1.2
var is_active: bool = false
var card_type: GameManager.CardType
var particles: Array = []

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func play_animation(type: GameManager.CardType):
	if not SettingsManager.animations_enabled:
		_finish()
		return
	
	card_type = type
	animation_time = 0.0
	is_active = true
	visible = true
	_generate_particles()
	queue_redraw()

func _generate_particles():
	particles.clear()
	var center = size / 2
	
	match card_type:
		GameManager.CardType.FIRE:
			# Fire particles rising up
			for i in range(25):
				particles.append({
					"pos": Vector2(center.x + randf_range(-30, 30), size.y),
					"vel": Vector2(randf_range(-20, 20), randf_range(-150, -80)),
					"size": randf_range(4, 10),
					"life": randf_range(0.6, 1.0),
					"color_shift": randf()
				})
		
		GameManager.CardType.WATER:
			# Water splash droplets
			for i in range(30):
				var angle = randf() * TAU
				var speed = randf_range(80, 180)
				particles.append({
					"pos": center,
					"vel": Vector2(cos(angle) * speed, sin(angle) * speed - 50),
					"size": randf_range(3, 8),
					"life": randf_range(0.5, 0.9),
					"gravity": 200
				})
		
		GameManager.CardType.GRASS:
			# Leaf burst
			for i in range(20):
				var angle = randf() * TAU
				var speed = randf_range(60, 140)
				particles.append({
					"pos": center,
					"vel": Vector2(cos(angle) * speed, sin(angle) * speed),
					"rotation": randf() * TAU,
					"rot_speed": randf_range(-5, 5),
					"size": randf_range(6, 12),
					"life": randf_range(0.7, 1.1),
					"gravity": 80
				})
		
		GameManager.CardType.DARKNESS:
			# Dark swirling vortexes
			for i in range(15):
				var angle = (float(i) / 15) * TAU
				var dist = randf_range(20, 50)
				particles.append({
					"pos": center + Vector2(cos(angle), sin(angle)) * dist,
					"angle": angle,
					"dist": dist,
					"size": randf_range(8, 18),
					"life": randf_range(0.8, 1.2),
					"orbit_speed": randf_range(3, 6) * (1 if randf() > 0.5 else -1)
				})
		
		GameManager.CardType.LIGHTNING:
			# Electric burst
			for i in range(12):
				var angle = randf() * TAU
				particles.append({
					"start": center,
					"angle": angle,
					"length": randf_range(30, 60),
					"life": randf_range(0.3, 0.6),
					"segments": randi_range(3, 5)
				})

func _process(delta):
	if not is_active:
		return
	
	animation_time += delta
	
	# Update particles
	for p in particles:
		p["life"] -= delta
		
		if p.has("vel"):
			p["pos"] += p["vel"] * delta
			if p.has("gravity"):
				p["vel"].y += p["gravity"] * delta
		
		if p.has("rotation") and p.has("rot_speed"):
			p["rotation"] += p["rot_speed"] * delta
		
		if p.has("orbit_speed") and p.has("angle"):
			p["angle"] += p["orbit_speed"] * delta
			var center = size / 2
			p["pos"] = center + Vector2(cos(p["angle"]), sin(p["angle"])) * p["dist"]
	
	# Remove dead particles
	particles = particles.filter(func(p): return p["life"] > 0)
	
	queue_redraw()
	
	if animation_time >= max_time or particles.is_empty():
		_finish()

func _finish():
	is_active = false
	visible = false
	queue_free()

func _draw():
	if not is_active:
		return
	
	match card_type:
		GameManager.CardType.FIRE:
			_draw_fire()
		GameManager.CardType.WATER:
			_draw_water()
		GameManager.CardType.GRASS:
			_draw_grass()
		GameManager.CardType.DARKNESS:
			_draw_darkness()
		GameManager.CardType.LIGHTNING:
			_draw_lightning_burst()

func _draw_fire():
	for p in particles:
		var alpha = clamp(p["life"], 0, 1)
		var t = p["color_shift"]
		# Gradient from yellow to orange to red
		var color = Color(1.0, 0.8 - t * 0.5, 0.2 - t * 0.2, alpha * 0.8)
		draw_circle(p["pos"], p["size"] * alpha, color)
		# Inner bright core
		draw_circle(p["pos"], p["size"] * alpha * 0.5, Color(1, 1, 0.8, alpha))

func _draw_water():
	for p in particles:
		var alpha = clamp(p["life"], 0, 1)
		var color = Color(0.3, 0.6, 1.0, alpha * 0.7)
		draw_circle(p["pos"], p["size"] * alpha, color)
		# Highlight
		var highlight = Color(0.7, 0.9, 1.0, alpha * 0.5)
		draw_circle(p["pos"] + Vector2(-1, -1), p["size"] * alpha * 0.3, highlight)

func _draw_grass():
	for p in particles:
		var alpha = clamp(p["life"], 0, 1)
		var color = Color(0.3, 0.8, 0.3, alpha * 0.8)
		
		# Draw leaf shape
		var leaf_size = p["size"] * alpha
		var points = PackedVector2Array()
		var rot = p["rotation"]
		var pos = p["pos"]
		
		# Simple leaf shape
		points.append(pos + Vector2(0, -leaf_size).rotated(rot))
		points.append(pos + Vector2(leaf_size * 0.4, 0).rotated(rot))
		points.append(pos + Vector2(0, leaf_size * 0.3).rotated(rot))
		points.append(pos + Vector2(-leaf_size * 0.4, 0).rotated(rot))
		
		draw_colored_polygon(points, color)

func _draw_darkness():
	var center = size / 2
	
	# Draw swirling dark background
	var bg_alpha = clamp(1.0 - animation_time / max_time, 0, 0.4)
	draw_circle(center, 40, Color(0.1, 0, 0.15, bg_alpha))
	
	for p in particles:
		var alpha = clamp(p["life"] / 1.2, 0, 1)
		# Dark purple/black swirls
		var color = Color(0.2, 0.1, 0.3, alpha * 0.7)
		draw_circle(p["pos"], p["size"] * alpha, color)
		# Darker core
		draw_circle(p["pos"], p["size"] * alpha * 0.6, Color(0.05, 0, 0.1, alpha * 0.9))
		# Purple rim
		draw_arc(p["pos"], p["size"] * alpha, 0, TAU, 16, Color(0.5, 0.2, 0.6, alpha * 0.5), 2)

func _draw_lightning_burst():
	var center = size / 2
	
	for p in particles:
		if p["life"] <= 0:
			continue
		
		var alpha = clamp(p["life"] / 0.6, 0, 1)
		var points = [center]
		var current = center
		var direction = Vector2(cos(p["angle"]), sin(p["angle"]))
		var segment_length = p["length"] / p["segments"]
		
		for i in range(p["segments"]):
			var next = current + direction * segment_length
			# Add jitter
			next += Vector2(randf_range(-8, 8), randf_range(-8, 8))
			points.append(next)
			current = next
		
		# Draw bolt
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], Color(0.6, 0.8, 1.0, alpha * 0.5), 4)
			draw_line(points[i], points[i + 1], Color(0.9, 0.95, 1.0, alpha * 0.8), 2)
			draw_line(points[i], points[i + 1], Color(1, 1, 1, alpha), 1)

