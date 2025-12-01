extends Node

# Signals
signal settings_changed

# Settings
var animations_enabled: bool = true
var current_theme: String = "mystic"  # mystic, ocean, forest, ember, void

# Theme definitions - includes colors AND card frame style
const THEMES = {
	"mystic": {
		"name": "Mystic Classic",
		"background": Color(0.12, 0.08, 0.18),
		"background_pattern": Color(0.15, 0.1, 0.22, 0.3),
		"accent": Color(0.9, 0.8, 1.0),
		"player_color": Color(0.6, 0.8, 0.6),
		"opponent_color": Color(0.8, 0.6, 0.6),
		"text_color": Color(1.0, 0.95, 0.8),
		"card_style": "classic",
		"border_width": 2,
		"corner_radius": 8
	},
	"pixel": {
		"name": "Pixel Retro",
		"background": Color(0.1, 0.1, 0.15),
		"background_pattern": Color(0.15, 0.15, 0.2, 0.4),
		"accent": Color(0.0, 1.0, 0.5),
		"player_color": Color(0.0, 0.8, 0.4),
		"opponent_color": Color(1.0, 0.3, 0.3),
		"text_color": Color(1.0, 1.0, 1.0),
		"card_style": "pixel",
		"border_width": 4,
		"corner_radius": 0
	},
	"elegant": {
		"name": "Royal Elegant",
		"background": Color(0.05, 0.05, 0.1),
		"background_pattern": Color(0.1, 0.08, 0.15, 0.3),
		"accent": Color(1.0, 0.85, 0.4),
		"player_color": Color(0.9, 0.8, 0.5),
		"opponent_color": Color(0.7, 0.5, 0.6),
		"text_color": Color(1.0, 0.95, 0.85),
		"card_style": "elegant",
		"border_width": 3,
		"corner_radius": 12
	},
	"neon": {
		"name": "Cyber Neon",
		"background": Color(0.02, 0.02, 0.05),
		"background_pattern": Color(0.05, 0.02, 0.1, 0.4),
		"accent": Color(0.0, 1.0, 1.0),
		"player_color": Color(0.0, 1.0, 0.8),
		"opponent_color": Color(1.0, 0.0, 0.5),
		"text_color": Color(0.9, 1.0, 1.0),
		"card_style": "neon",
		"border_width": 2,
		"corner_radius": 4
	},
	"nature": {
		"name": "Forest Nature",
		"background": Color(0.08, 0.12, 0.08),
		"background_pattern": Color(0.1, 0.15, 0.1, 0.3),
		"accent": Color(0.7, 1.0, 0.7),
		"player_color": Color(0.5, 0.9, 0.5),
		"opponent_color": Color(0.9, 0.7, 0.5),
		"text_color": Color(0.95, 1.0, 0.9),
		"card_style": "nature",
		"border_width": 3,
		"corner_radius": 15
	}
}

func _ready():
	load_settings()

func get_theme() -> Dictionary:
	return THEMES.get(current_theme, THEMES["mystic"])

func set_theme(theme_id: String):
	if THEMES.has(theme_id):
		current_theme = theme_id
		save_settings()
		emit_signal("settings_changed")

func set_animations(enabled: bool):
	animations_enabled = enabled
	save_settings()
	emit_signal("settings_changed")

func save_settings():
	var config = ConfigFile.new()
	config.set_value("settings", "animations_enabled", animations_enabled)
	config.set_value("settings", "current_theme", current_theme)
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		animations_enabled = config.get_value("settings", "animations_enabled", true)
		current_theme = config.get_value("settings", "current_theme", "mystic")

func get_theme_names() -> Array:
	var names = []
	for key in THEMES:
		names.append({"id": key, "name": THEMES[key]["name"]})
	return names

# Get card style properties for the current theme
func get_card_style() -> Dictionary:
	var theme = get_theme()
	return {
		"style": theme.get("card_style", "classic"),
		"border_width": theme.get("border_width", 2),
		"corner_radius": theme.get("corner_radius", 8)
	}
