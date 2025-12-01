extends Control

# Lightning bolt effect for Lightning cards

var bolts: Array = []
var lifetime: float = 0.0
var max_lifetime: float = 0.8
var is_active: bool = false

func _ready():
	visible = false

func play_effect():
	if not SettingsManager.animations_enabled:
		queue_free()
		return
	
	visible = true
	is_active = true
	lifetime = 0.0
	
	# Generate random lightning bolts
	bolts.clear()
	for i in range(randi_range(3, 5)):
		bolts.append(generate_bolt())
	
	queue_redraw()

func generate_bolt() -> Array:
	var points = []
	var start = Vector2(size.x * randf(), 0)
	var end = Vector2(size.x * randf(), size.y)
	
	var segments = randi_range(5, 8)
	for i in range(segments + 1):
		var t = float(i) / segments
		var base_pos = start.lerp(end, t)
		
		# Add random offset for jagged look
		if i > 0 and i < segments:
			base_pos.x += randf_range(-30, 30)
			base_pos.y += randf_range(-10, 10)
		
		points.append(base_pos)
	
	return points

func _process(delta):
	if not is_active:
		return
	
	lifetime += delta
	
	# Regenerate bolts occasionally for flickering effect
	if fmod(lifetime, 0.1) < delta:
		bolts.clear()
		for i in range(randi_range(2, 4)):
			bolts.append(generate_bolt())
	
	queue_redraw()
	
	if lifetime >= max_lifetime:
		is_active = false
		visible = false
		queue_free()

func _draw():
	if not is_active:
		return
	
	var alpha = 1.0 - (lifetime / max_lifetime)
	
	# Draw glow background
	var glow_color = Color(0.8, 0.9, 1.0, alpha * 0.3)
	draw_rect(Rect2(Vector2.ZERO, size), glow_color)
	
	# Draw each bolt
	for bolt in bolts:
		if bolt.size() < 2:
			continue
		
		# Main bolt (thick, bright)
		var main_color = Color(1.0, 1.0, 0.9, alpha)
		for i in range(bolt.size() - 1):
			draw_line(bolt[i], bolt[i + 1], main_color, 3.0)
		
		# Glow effect (wider, dimmer)
		var glow = Color(0.6, 0.8, 1.0, alpha * 0.5)
		for i in range(bolt.size() - 1):
			draw_line(bolt[i], bolt[i + 1], glow, 8.0)
		
		# Core (thin, white)
		var core_color = Color(1.0, 1.0, 1.0, alpha)
		for i in range(bolt.size() - 1):
			draw_line(bolt[i], bolt[i + 1], core_color, 1.5)
	
	# Add some sparkles
	var sparkle_color = Color(1.0, 1.0, 0.8, alpha)
	for i in range(8):
		var pos = Vector2(randf() * size.x, randf() * size.y)
		var sparkle_size = randf_range(2, 5)
		draw_circle(pos, sparkle_size, sparkle_color)

