extends Control

signal card_clicked(card_node: Control)
signal card_drag_started(card_node: Control)
signal card_drag_ended(card_node: Control, success: bool)

@export var card_type: GameManager.CardType = GameManager.CardType.FIRE
@export var face_up: bool = true
@export var clickable: bool = false
@export var highlighted: bool = false
@export var on_field: bool = false  # Track if card is on the field for passive animations
@export var draggable: bool = false  # Enable drag and drop

@onready var background: Panel = $Background
@onready var symbol_label: Label = $SymbolLabel
@onready var name_label: Label = $NameLabel
@onready var glow: Panel = $Glow

var hover: bool = false

# Drag state
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var original_parent: Node = null
var original_index: int = 0

# Passive animation state
var animation_time: float = 0.0
var particles: Array = []
var particle_regen_timer: float = 0.0

# Animation constants per type - faster regen = more particles
const PARTICLE_REGEN_INTERVAL = {
	GameManager.CardType.FIRE: 0.05,
	GameManager.CardType.WATER: 0.08,
	GameManager.CardType.GRASS: 0.12,
	GameManager.CardType.DARKNESS: 0.06,
	GameManager.CardType.LIGHTNING: 0.1
}

func _ready():
	# Enable input processing for touch events
	mouse_filter = Control.MOUSE_FILTER_STOP
	update_visuals()
	# Update visuals when theme changes
	if not SettingsManager.settings_changed.is_connected(_on_settings_changed):
		SettingsManager.settings_changed.connect(_on_settings_changed)

func _on_settings_changed():
	update_visuals()

func setup(type: GameManager.CardType, is_face_up: bool = true, is_clickable: bool = false):
	card_type = type
	face_up = is_face_up
	clickable = is_clickable
	update_visuals()

func _process(delta):
	# Handle dragging
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset
	
	# Only animate cards on the field with animations enabled
	if on_field and face_up and SettingsManager.animations_enabled:
		animation_time += delta
		particle_regen_timer += delta
		
		var regen_interval = PARTICLE_REGEN_INTERVAL.get(card_type, 0.15)
		if particle_regen_timer >= regen_interval:
			particle_regen_timer = 0.0
			_generate_passive_particles()
		
		_update_particles(delta)
		queue_redraw()

func _generate_passive_particles():
	var card_size = size
	var margin = 4.0
	
	match card_type:
		GameManager.CardType.FIRE:
			# Flame particles rising from bottom and sides
			if particles.size() < 15:
				var x_pos = randf_range(margin, card_size.x - margin)
				particles.append({
					"pos": Vector2(x_pos, card_size.y - margin + randf_range(-5, 5)),
					"vel": Vector2(randf_range(-15, 15), randf_range(-60, -30)),
					"size": randf_range(4, 9),
					"life": randf_range(0.5, 0.9),
					"max_life": 0.9,
					"color_t": randf()
				})
		
		GameManager.CardType.WATER:
			# Water droplets/bubbles rising
			if particles.size() < 12:
				particles.append({
					"pos": Vector2(randf_range(margin, card_size.x - margin), card_size.y - margin),
					"vel": Vector2(randf_range(-8, 8), randf_range(-45, -20)),
					"size": randf_range(3, 7),
					"life": randf_range(0.6, 1.0),
					"max_life": 1.0,
					"wobble_phase": randf() * TAU
				})
		
		GameManager.CardType.GRASS:
			# Floating leaf particles all around
			if particles.size() < 8:
				var side = randi() % 4  # 0=top, 1=right, 2=bottom, 3=left
				var start_pos: Vector2
				match side:
					0: start_pos = Vector2(randf_range(margin, card_size.x - margin), margin)
					1: start_pos = Vector2(card_size.x - margin, randf_range(margin, card_size.y - margin))
					2: start_pos = Vector2(randf_range(margin, card_size.x - margin), card_size.y - margin)
					3: start_pos = Vector2(margin, randf_range(margin, card_size.y - margin))
				
				particles.append({
					"pos": start_pos,
					"vel": Vector2(randf_range(-20, 20), randf_range(-20, 20)),
					"rotation": randf() * TAU,
					"rot_speed": randf_range(-4, 4),
					"size": randf_range(6, 10),
					"life": randf_range(0.9, 1.4),
					"max_life": 1.4
				})
		
		GameManager.CardType.DARKNESS:
			# Dark swirling orbs around the card
			if particles.size() < 10:
				var center = card_size / 2
				var angle = randf() * TAU
				var dist = randf_range(20, 45)
				particles.append({
					"pos": center + Vector2(cos(angle), sin(angle)) * dist,
					"center": center,
					"angle": angle,
					"dist": dist,
					"size": randf_range(6, 14),
					"life": randf_range(0.7, 1.2),
					"max_life": 1.2,
					"orbit_speed": randf_range(2.5, 5) * (1 if randf() > 0.5 else -1)
				})
		
		GameManager.CardType.LIGHTNING:
			# Electric bolts along edges
			if particles.size() < 6:
				_add_lightning_bolt()

func _add_lightning_bolt():
	var card_size = size
	var margin = 4.0
	var edge = randi() % 4
	var start: Vector2
	var end: Vector2
	var horizontal: bool
	
	match edge:
		0:  # Top
			start = Vector2(margin, margin)
			end = Vector2(card_size.x - margin, margin)
			horizontal = true
		1:  # Bottom
			start = Vector2(margin, card_size.y - margin)
			end = Vector2(card_size.x - margin, card_size.y - margin)
			horizontal = true
		2:  # Left
			start = Vector2(margin, margin)
			end = Vector2(margin, card_size.y - margin)
			horizontal = false
		3:  # Right
			start = Vector2(card_size.x - margin, margin)
			end = Vector2(card_size.x - margin, card_size.y - margin)
			horizontal = false
	
	var points: Array = []
	var segments = randi_range(4, 6)
	for i in range(segments + 1):
		var t = float(i) / segments
		var base_pos = start.lerp(end, t)
		if i > 0 and i < segments:
			var offset = randf_range(-3, 3)
			if horizontal:
				base_pos.y += offset
			else:
				base_pos.x += offset
		points.append(base_pos)
	
	particles.append({
		"type": "bolt",
		"points": points,
		"life": randf_range(0.1, 0.2),
		"max_life": 0.2
	})

func _update_particles(delta):
	for p in particles:
		p["life"] -= delta
		
		if p.has("vel"):
			p["pos"] += p["vel"] * delta
		
		if p.has("rotation") and p.has("rot_speed"):
			p["rotation"] += p["rot_speed"] * delta
		
		if p.has("orbit_speed") and p.has("angle") and p.has("center"):
			p["angle"] += p["orbit_speed"] * delta
			p["pos"] = p["center"] + Vector2(cos(p["angle"]), sin(p["angle"])) * p["dist"]
		
		if p.has("wobble_phase"):
			p["wobble_phase"] += delta * 5
			p["pos"].x += sin(p["wobble_phase"]) * 0.5
	
	particles = particles.filter(func(p): return p["life"] > 0)

func _draw():
	if not on_field or not face_up or not SettingsManager.animations_enabled:
		return
	
	match card_type:
		GameManager.CardType.FIRE:
			_draw_fire_passive()
		GameManager.CardType.WATER:
			_draw_water_passive()
		GameManager.CardType.GRASS:
			_draw_grass_passive()
		GameManager.CardType.DARKNESS:
			_draw_darkness_passive()
		GameManager.CardType.LIGHTNING:
			_draw_lightning_passive()

func _draw_fire_passive():
	for p in particles:
		var alpha = clamp(p["life"] / p["max_life"], 0, 1)
		var t = p["color_t"]
		# Outer glow
		var glow_color = Color(1.0, 0.5, 0.1, alpha * 0.3)
		draw_circle(p["pos"], p["size"] * alpha * 1.5, glow_color)
		# Main flame
		var color = Color(1.0, 0.7 - t * 0.4, 0.2 - t * 0.2, alpha * 0.9)
		draw_circle(p["pos"], p["size"] * alpha, color)
		# Bright core
		draw_circle(p["pos"], p["size"] * alpha * 0.4, Color(1, 1, 0.7, alpha))

func _draw_water_passive():
	for p in particles:
		var alpha = clamp(p["life"] / p["max_life"], 0, 1)
		# Outer glow
		draw_circle(p["pos"], p["size"] * alpha * 1.3, Color(0.3, 0.6, 1.0, alpha * 0.3))
		# Main droplet
		var color = Color(0.4, 0.75, 1.0, alpha * 0.8)
		draw_circle(p["pos"], p["size"] * alpha, color)
		# Highlight
		draw_circle(p["pos"] + Vector2(-2, -2), p["size"] * alpha * 0.35, Color(0.9, 0.97, 1.0, alpha * 0.7))

func _draw_grass_passive():
	for p in particles:
		var alpha = clamp(p["life"] / p["max_life"], 0, 1)
		var leaf_size = p["size"] * alpha
		var rot = p["rotation"]
		var pos = p["pos"]
		
		# Leaf shape
		var points = PackedVector2Array()
		points.append(pos + Vector2(0, -leaf_size).rotated(rot))
		points.append(pos + Vector2(leaf_size * 0.5, 0).rotated(rot))
		points.append(pos + Vector2(0, leaf_size * 0.4).rotated(rot))
		points.append(pos + Vector2(-leaf_size * 0.5, 0).rotated(rot))
		
		# Draw with bright green
		var color = Color(0.3, 0.9, 0.3, alpha * 0.9)
		draw_colored_polygon(points, color)
		# Lighter center vein
		draw_line(pos + Vector2(0, -leaf_size * 0.8).rotated(rot), 
				  pos + Vector2(0, leaf_size * 0.3).rotated(rot),
				  Color(0.5, 1.0, 0.5, alpha * 0.6), 1.5)

func _draw_darkness_passive():
	for p in particles:
		var alpha = clamp(p["life"] / p["max_life"], 0, 1)
		# Outer void glow
		draw_circle(p["pos"], p["size"] * alpha * 1.4, Color(0.2, 0.0, 0.3, alpha * 0.4))
		# Dark orb
		var color = Color(0.1, 0.0, 0.2, alpha * 0.8)
		draw_circle(p["pos"], p["size"] * alpha, color)
		# Purple rim
		draw_arc(p["pos"], p["size"] * alpha, 0, TAU, 16, Color(0.6, 0.2, 0.8, alpha * 0.7), 2)
		# Dark core
		draw_circle(p["pos"], p["size"] * alpha * 0.4, Color(0.0, 0.0, 0.05, alpha))

func _draw_lightning_passive():
	for p in particles:
		if not p.has("type") or p["type"] != "bolt":
			continue
		
		var alpha = clamp(p["life"] / p["max_life"], 0, 1)
		var points = p["points"]
		
		if points.size() < 2:
			continue
		
		# Draw bolts with glow
		for i in range(points.size() - 1):
			# Outer glow
			draw_line(points[i], points[i + 1], Color(0.5, 0.7, 1.0, alpha * 0.3), 6)
			# Mid layer
			draw_line(points[i], points[i + 1], Color(0.7, 0.85, 1.0, alpha * 0.6), 3)
			# Bright core
			draw_line(points[i], points[i + 1], Color(1, 1, 1, alpha), 1.5)

func update_visuals():
	if not is_inside_tree():
		await ready
	
	var card_style = SettingsManager.get_card_style()
	var theme = SettingsManager.get_theme()
	var corner = card_style["corner_radius"]
	var border = card_style["border_width"]
	var style_type = card_style["style"]
	
	if face_up:
		var color = GameManager.CARD_COLORS[card_type]
		var style = StyleBoxFlat.new()
		
		# Apply theme-specific card styling
		match style_type:
			"pixel":
				# Sharp edges, thick border, slightly darker
				style.bg_color = color.darkened(0.1)
				style.border_color = color.lightened(0.4)
				style.shadow_color = Color(0, 0, 0, 0)
			"elegant":
				# Gradient-like effect with gold trim
				style.bg_color = color
				style.border_color = Color(0.9, 0.8, 0.4)  # Gold border
				style.shadow_color = Color(0, 0, 0, 0.4)
				style.shadow_size = 6
				style.shadow_offset = Vector2(3, 3)
			"neon":
				# Dark card with glowing border
				style.bg_color = color.darkened(0.4)
				style.border_color = color.lightened(0.5)
				style.shadow_color = color
				style.shadow_size = 8
				style.shadow_offset = Vector2(0, 0)
			"nature":
				# Earthy, organic feel
				style.bg_color = color.lerp(Color(0.4, 0.3, 0.2), 0.15)
				style.border_color = Color(0.5, 0.4, 0.3)
				style.shadow_color = Color(0, 0, 0, 0.25)
				style.shadow_size = 3
				style.shadow_offset = Vector2(2, 2)
			_:  # classic/mystic
				style.bg_color = color
				style.border_color = color.lightened(0.3)
				style.shadow_color = Color(0, 0, 0, 0.3)
				style.shadow_size = 4
				style.shadow_offset = Vector2(2, 2)
		
		style.corner_radius_top_left = corner
		style.corner_radius_top_right = corner
		style.corner_radius_bottom_left = corner
		style.corner_radius_bottom_right = corner
		style.border_width_left = border
		style.border_width_right = border
		style.border_width_top = border
		style.border_width_bottom = border
		
		background.add_theme_stylebox_override("panel", style)
		symbol_label.text = GameManager.CARD_SYMBOLS[card_type]
		name_label.text = GameManager.CARD_NAMES[card_type]
		symbol_label.visible = true
		name_label.visible = true
		
		# Adjust text colors for neon theme
		if style_type == "neon":
			symbol_label.add_theme_color_override("font_color", color.lightened(0.6))
			name_label.add_theme_color_override("font_color", color.lightened(0.6))
		else:
			symbol_label.remove_theme_color_override("font_color")
			name_label.remove_theme_color_override("font_color")
	else:
		var style = StyleBoxFlat.new()
		var back_color = theme.get("background", Color(0.2, 0.15, 0.3)).lightened(0.15)
		
		match style_type:
			"pixel":
				style.bg_color = Color(0.15, 0.15, 0.2)
				style.border_color = Color(0.4, 0.4, 0.5)
			"elegant":
				style.bg_color = Color(0.15, 0.1, 0.2)
				style.border_color = Color(0.6, 0.5, 0.3)
			"neon":
				style.bg_color = Color(0.05, 0.05, 0.1)
				style.border_color = theme.get("accent", Color(0, 1, 1)).darkened(0.3)
			"nature":
				style.bg_color = Color(0.2, 0.18, 0.15)
				style.border_color = Color(0.4, 0.35, 0.3)
			_:
				style.bg_color = Color(0.2, 0.15, 0.3)
				style.border_color = Color(0.5, 0.4, 0.6)
		
		style.corner_radius_top_left = corner
		style.corner_radius_top_right = corner
		style.corner_radius_bottom_left = corner
		style.corner_radius_bottom_right = corner
		style.border_width_left = border
		style.border_width_right = border
		style.border_width_top = border
		style.border_width_bottom = border
		
		background.add_theme_stylebox_override("panel", style)
		symbol_label.text = "✦"
		name_label.text = ""
		symbol_label.visible = true
		name_label.visible = false
	
	update_highlight()

func update_highlight():
	if glow:
		var glow_style = StyleBoxFlat.new()
		glow_style.bg_color = Color(0, 0, 0, 0)
		glow_style.corner_radius_top_left = 10
		glow_style.corner_radius_top_right = 10
		glow_style.corner_radius_bottom_left = 10
		glow_style.corner_radius_bottom_right = 10
		
		if highlighted or (hover and clickable) or is_dragging:
			glow_style.border_width_left = 3
			glow_style.border_width_right = 3
			glow_style.border_width_top = 3
			glow_style.border_width_bottom = 3
			glow_style.border_color = Color(1, 0.9, 0.4, 0.9)
			glow_style.shadow_color = Color(1, 0.8, 0.2, 0.5)
			glow_style.shadow_size = 8
		else:
			glow_style.border_color = Color(0, 0, 0, 0)
		
		glow.add_theme_stylebox_override("panel", glow_style)

func _gui_input(event: InputEvent):
	# Handle both mouse and touch events
	# On web, touch events are converted to mouse events, so we check for mouse button
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if draggable:
				_start_drag()
				get_viewport().set_input_as_handled()
			elif clickable:
				print("[Card] Card clicked, emitting signal. clickable=", clickable, ", draggable=", draggable)
				emit_signal("card_clicked", self)
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		# Direct touch event (for native mobile)
		if event.pressed:
			if draggable:
				_start_drag()
				get_viewport().set_input_as_handled()
			elif clickable:
				print("[Card] Card touched, emitting signal. clickable=", clickable, ", draggable=", draggable)
				emit_signal("card_clicked", self)
				get_viewport().set_input_as_handled()

func _input(event: InputEvent):
	# Handle mouse release during drag (must use _input since card is reparented)
	if is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_end_drag()
			get_viewport().set_input_as_handled()

func _start_drag():
	is_dragging = true
	drag_offset = get_local_mouse_position()
	original_position = global_position
	original_parent = get_parent()
	original_index = get_index()
	
	# Move to top level for dragging
	var root = get_tree().root
	var global_pos = global_position
	original_parent.remove_child(self)
	root.add_child(self)
	global_position = global_pos
	z_index = 100
	
	update_highlight()
	emit_signal("card_drag_started", self)

func _end_drag():
	is_dragging = false
	z_index = 0
	update_highlight()
	emit_signal("card_drag_ended", self, false)  # Main.gd will handle success detection

func return_to_hand():
	# Return card to original position in hand
	var root = get_tree().root
	if get_parent() == root:
		root.remove_child(self)
		original_parent.add_child(self)
		original_parent.move_child(self, original_index)
	
	is_dragging = false
	z_index = 0
	update_highlight()

func _on_mouse_entered():
	hover = true
	update_highlight()
	if (clickable or draggable) and not is_dragging:
		scale = Vector2(1.05, 1.05)

func _on_mouse_exited():
	hover = false
	update_highlight()
	if not is_dragging:
		scale = Vector2(1.0, 1.0)
