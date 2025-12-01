extends Control
class_name BlockedOverlay

# "BLOCKED" text popup with screen shake

var animation_time: float = 0.0
var max_time: float = 2.0
var is_active: bool = false
var shake_intensity: float = 8.0
var shake_time: float = 0.0
var shake_duration: float = 0.4
var original_position: Vector2 = Vector2.ZERO
var target_node: Node = null

signal animation_finished

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchors_preset = Control.PRESET_FULL_RECT
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func play_blocked(shake_target: Node = null):
	if not SettingsManager.animations_enabled:
		emit_signal("animation_finished")
		queue_free()
		return
	
	target_node = shake_target
	if target_node:
		original_position = target_node.position
	
	animation_time = 0.0
	shake_time = 0.0
	is_active = true
	visible = true
	queue_redraw()

func _process(delta):
	if not is_active:
		return
	
	animation_time += delta
	
	# Screen shake
	if shake_time < shake_duration and target_node:
		shake_time += delta
		var shake_progress = shake_time / shake_duration
		var current_intensity = shake_intensity * (1.0 - shake_progress)
		var offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		target_node.position = original_position + offset
	elif target_node and shake_time >= shake_duration:
		target_node.position = original_position
	
	queue_redraw()
	
	if animation_time >= max_time:
		if target_node:
			target_node.position = original_position
		is_active = false
		visible = false
		emit_signal("animation_finished")
		queue_free()

func _draw():
	if not is_active:
		return
	
	var center = size / 2
	
	# Calculate alpha (fade in then out)
	var alpha = 1.0
	if animation_time < 0.2:
		alpha = animation_time / 0.2
	elif animation_time > max_time - 0.5:
		alpha = (max_time - animation_time) / 0.5
	
	# Scale animation (pop in)
	var text_scale = 1.0
	if animation_time < 0.15:
		text_scale = 0.5 + (animation_time / 0.15) * 0.7
	elif animation_time < 0.25:
		text_scale = 1.2 - ((animation_time - 0.15) / 0.1) * 0.2
	
	# Draw semi-transparent background flash
	if animation_time < 0.3:
		var flash_alpha = (0.3 - animation_time) / 0.3 * 0.3
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.3, 0.3, flash_alpha))
	
	# Draw "BLOCKED" text
	var font = ThemeDB.fallback_font
	var font_size = int(48 * text_scale)
	var text = "BLOCKED!"
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = center - text_size / 2
	
	# Shadow
	draw_string(font, text_pos + Vector2(3, 3), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, alpha * 0.5))
	
	# Outline
	for offset in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		draw_string(font, text_pos + offset, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.3, 0, 0, alpha))
	
	# Main text
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 0.2, 0.2, alpha))

