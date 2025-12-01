extends Control
class_name ShatterEffect

# Block symbol animation - 🚫 slams down on blocked card

var animation_time: float = 0.0
var max_time: float = 1.2
var is_active: bool = false
var card_color: Color = Color.WHITE
var card_rect: Rect2
var symbol_scale: float = 0.0
var symbol_y_offset: float = -100.0
var impact_shake: float = 0.0

signal animation_finished

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func play_shatter(type: GameManager.CardType, rect: Rect2):
	if not SettingsManager.animations_enabled:
		emit_signal("animation_finished")
		queue_free()
		return
	
	card_color = GameManager.CARD_COLORS[type]
	card_rect = rect
	
	# Position to cover the whole screen for the effect
	global_position = Vector2.ZERO
	size = get_viewport_rect().size
	
	animation_time = 0.0
	symbol_scale = 2.5  # Start big
	symbol_y_offset = -150.0  # Start above
	impact_shake = 0.0
	is_active = true
	visible = true
	
	queue_redraw()

func _process(delta):
	if not is_active:
		return
	
	animation_time += delta
	var t = animation_time / max_time
	
	# Phase 1: Symbol slams down (0 - 0.3)
	if t < 0.3:
		var slam_t = t / 0.3
		# Ease in (accelerate as it falls)
		var ease_t = slam_t * slam_t
		symbol_y_offset = lerp(-150.0, 0.0, ease_t)
		symbol_scale = lerp(2.5, 1.0, ease_t)
	
	# Phase 2: Impact (0.3 - 0.5)
	elif t < 0.5:
		var impact_t = (t - 0.3) / 0.2
		symbol_y_offset = 0.0
		symbol_scale = 1.0
		# Shake on impact
		impact_shake = (1.0 - impact_t) * 8.0
	
	# Phase 3: Hold and fade (0.5 - 1.0)
	else:
		symbol_y_offset = 0.0
		symbol_scale = 1.0
		impact_shake = 0.0
	
	queue_redraw()
	
	if animation_time >= max_time:
		is_active = false
		visible = false
		emit_signal("animation_finished")
		queue_free()

func _draw():
	if not is_active:
		return
	
	var t = animation_time / max_time
	var center = card_rect.position + card_rect.size / 2
	
	# Apply shake
	if impact_shake > 0:
		center += Vector2(randf_range(-impact_shake, impact_shake), randf_range(-impact_shake, impact_shake))
	
	center.y += symbol_y_offset
	
	# Calculate alpha (fade out in last phase)
	var alpha = 1.0
	if t > 0.7:
		alpha = 1.0 - (t - 0.7) / 0.3
	
	# Draw darkened card underneath
	if t >= 0.3:
		var dark_color = card_color.darkened(0.5)
		dark_color.a = alpha * 0.8
		draw_rect(card_rect, dark_color)
		draw_rect(card_rect, Color(0.3, 0.3, 0.3, alpha * 0.5), false, 2)
	
	# Symbol size based on card
	var symbol_radius = min(card_rect.size.x, card_rect.size.y) * 0.5 * symbol_scale
	
	# Draw shadow (offset and darker)
	if t < 0.3:
		var shadow_offset = Vector2(5, 5) * symbol_scale
		var shadow_alpha = alpha * 0.3
		_draw_block_symbol(center + shadow_offset, symbol_radius, Color(0, 0, 0, shadow_alpha))
	
	# Draw red glow behind symbol on impact
	if t >= 0.3 and t < 0.6:
		var glow_alpha = (1.0 - (t - 0.3) / 0.3) * alpha * 0.5
		draw_circle(center, symbol_radius * 1.3, Color(1, 0.2, 0.2, glow_alpha))
	
	# Draw the block symbol (🚫)
	var symbol_color = Color(1, 0.15, 0.15, alpha)
	_draw_block_symbol(center, symbol_radius, symbol_color)
	
	# Draw "BLOCKED" text below on impact
	if t >= 0.3:
		var text_alpha = alpha
		var font = ThemeDB.fallback_font
		var text = "BLOCKED"
		var font_size = 20
		var text_pos = center + Vector2(0, symbol_radius + 25)
		
		# Shadow
		draw_string(font, text_pos + Vector2(2, 2), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, text_alpha * 0.5))
		# Text
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 0.2, 0.2, text_alpha))

func _draw_block_symbol(center: Vector2, radius: float, color: Color):
	# Draw circle (ring)
	var ring_width = radius * 0.15
	draw_arc(center, radius, 0, TAU, 32, color, ring_width)
	
	# Draw diagonal line (from top-left to bottom-right)
	var line_start = center + Vector2(-radius * 0.7, -radius * 0.7)
	var line_end = center + Vector2(radius * 0.7, radius * 0.7)
	draw_line(line_start, line_end, color, ring_width)
	
	# Add white highlight on the ring for depth
	var highlight_color = Color(1, 1, 1, color.a * 0.3)
	draw_arc(center, radius * 0.85, -PI * 0.75, -PI * 0.25, 8, highlight_color, ring_width * 0.3)

