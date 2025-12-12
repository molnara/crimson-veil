extends Node

"""
SettingsManager - Singleton for managing game settings persistence and application

ARCHITECTURE:
- Autoload singleton (add to Project Settings)
- Saves to user://settings.cfg using ConfigFile
- Applies settings at startup and runtime

DEPENDENCIES:
- None (accessed globally via SettingsManager singleton)

INTEGRATION:
- Call apply_all_settings() after loading
- Listen to setting_changed signal for runtime updates
- Access current values via get_setting()
"""

# Settings file path
const SETTINGS_FILE = "user://settings.cfg"

# Config file instance
var config: ConfigFile = ConfigFile.new()

# Default settings
var default_settings = {
	"display": {
		"resolution": "1152x648",
		"fullscreen": false,
		"vsync": true,
		"msaa": 0  # 0=disabled, 1=2x, 2=4x, 3=8x
	},
	"graphics": {
		"shadow_quality": 1,  # 0=low, 1=medium, 2=high
		"fog_enabled": true,
		"cloud_count": 20,
		"view_distance": 4,
		"quality_preset": "medium"  # low, medium, high, ultra, custom
	},
	"performance": {
		"max_fps": 60  # 0=unlimited
	},
	"audio": {
		"master_volume": 1.0,   # 0.0 - 1.0
		"sfx_volume": 0.75,     # 0.0 - 1.0
		"music_volume": 0.35,   # 0.0 - 1.0
		"ambient_volume": 0.25, # 0.0 - 1.0
		"ui_volume": 0.60       # 0.0 - 1.0
	}
}

# Available resolution presets
var resolution_presets = [
	"1152x648",   # Default (16:9)
	"1280x720",   # HD (16:9)
	"1920x1080",  # Full HD (16:9)
	"2048x1152",  # QHD- (16:9) - Between 1080p and 1440p
	"2560x1440",  # QHD (16:9)
	"3840x2160"   # 4K (16:9)
]

# Quality preset definitions
var quality_presets = {
	"low": {
		"msaa": 0,
		"shadow_quality": 0,
		"fog_enabled": false,
		"cloud_count": 10,
		"view_distance": 2
	},
	"medium": {
		"msaa": 0,
		"shadow_quality": 1,
		"fog_enabled": true,
		"cloud_count": 20,
		"view_distance": 4
	},
	"high": {
		"msaa": 1,  # 2x
		"shadow_quality": 2,
		"fog_enabled": true,
		"cloud_count": 30,
		"view_distance": 6
	},
	"ultra": {
		"msaa": 2,  # 4x
		"shadow_quality": 2,
		"fog_enabled": true,
		"cloud_count": 40,
		"view_distance": 8
	}
}

# Signals
signal setting_changed(section: String, key: String, value)
signal settings_applied()

func _ready():
	# Add to settings group for easy access
	add_to_group("settings_manager")
	
	# Load settings from file
	load_settings()
	
	# Apply all settings
	call_deferred("apply_all_settings")
	
	# Monitor window size changes to prevent manual resizing
	get_window().size_changed.connect(_on_window_size_changed)

func _on_window_size_changed():
	"""Snap window back to set resolution if manually resized"""
	# Skip if we're applying settings (avoid infinite loop)
	if get_meta("applying_resolution", false):
		return
	
	# Get target resolution
	var target = parse_resolution(get_setting("display", "resolution"))
	if not target:
		return
	
	# If current size doesn't match target, restore it
	var current = get_window().size
	if current != target:
		print("Window resized to ", current, " - restoring to ", target)
		call_deferred("_restore_resolution", target)

func _restore_resolution(target: Vector2i):
	"""Restore window to target resolution"""
	set_meta("applying_resolution", true)
	get_window().size = target
	await get_tree().process_frame
	set_meta("applying_resolution", false)

func load_settings():
	"""Load settings from config file, using defaults if file doesn't exist"""
	var err = config.load(SETTINGS_FILE)
	var actual_path = ProjectSettings.globalize_path(SETTINGS_FILE)
	
	if err != OK:
		print("Settings file not found at: ", actual_path)
		print("Creating new settings file with defaults")
		# Set all default values
		for section in default_settings:
			for key in default_settings[section]:
				config.set_value(section, key, default_settings[section][key])
		save_settings()
	else:
		print("Settings loaded from user://settings.cfg")
		print("Actual file location: ", actual_path)
		# Ensure all default keys exist (for new settings added in updates)
		var settings_updated = false
		for section in default_settings:
			for key in default_settings[section]:
				if not config.has_section_key(section, key):
					config.set_value(section, key, default_settings[section][key])
					settings_updated = true
		
		if settings_updated:
			save_settings()

func save_settings():
	"""Save current settings to config file"""
	var err = config.save(SETTINGS_FILE)
	if err == OK:
		var actual_path = ProjectSettings.globalize_path(SETTINGS_FILE)
		print("Settings saved to user://settings.cfg")
		print("Actual file location: ", actual_path)
	else:
		print("Error saving settings: ", err)

func get_setting(section: String, key: String, default_value = null):
	"""Get a setting value, with optional default"""
	if config.has_section_key(section, key):
		return config.get_value(section, key)
	elif default_value != null:
		return default_value
	elif default_settings.has(section) and default_settings[section].has(key):
		return default_settings[section][key]
	return null

func set_setting(section: String, key: String, value, auto_save: bool = true):
	"""Set a setting value and optionally save"""
	config.set_value(section, key, value)
	
	if auto_save:
		save_settings()
	
	emit_signal("setting_changed", section, key, value)

func apply_all_settings():
	"""Apply all settings to the game"""
	apply_display_settings()
	apply_graphics_settings()
	apply_performance_settings()
	apply_audio_settings()
	
	emit_signal("settings_applied")
	print("All settings applied")

func apply_display_settings():
	"""Apply display-related settings"""
	set_meta("applying_resolution", true)
	
	# Resolution
	var resolution_string = get_setting("display", "resolution")
	var resolution = parse_resolution(resolution_string)
	if resolution:
		get_window().size = resolution
		print("Resolution set to: ", resolution)
	
	# Make window non-resizable to prevent manual resizing breaking the set resolution
	get_window().unresizable = true
	
	# Fullscreen - don't apply in editor
	var fullscreen = get_setting("display", "fullscreen")
	if OS.has_feature("editor"):
		print("Fullscreen disabled - running in editor")
		if fullscreen:
			print("Note: Fullscreen only works in exported builds, not in editor")
	else:
		if fullscreen:
			get_window().mode = Window.MODE_FULLSCREEN
		else:
			get_window().mode = Window.MODE_WINDOWED
		print("Fullscreen: ", fullscreen)
	
	# VSync
	var vsync = get_setting("display", "vsync")
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	print("VSync: ", vsync)
	
	# MSAA
	var msaa = get_setting("display", "msaa")
	match msaa:
		0:
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		1:
			get_viewport().msaa_3d = Viewport.MSAA_2X
		2:
			get_viewport().msaa_3d = Viewport.MSAA_4X
		3:
			get_viewport().msaa_3d = Viewport.MSAA_8X
	print("MSAA: ", msaa)
	
	await get_tree().process_frame
	set_meta("applying_resolution", false)

func apply_graphics_settings():
	"""Apply graphics-related settings (requires game world to exist)"""
	# These will be applied by world.gd on startup
	# and updated at runtime when settings change
	print("Graphics settings ready to apply")

func apply_performance_settings():
	"""Apply performance-related settings"""
	var max_fps = get_setting("performance", "max_fps")
	Engine.max_fps = max_fps
	print("Max FPS: ", max_fps if max_fps > 0 else "Unlimited")

func apply_audio_settings():
	"""Apply audio-related settings"""
	if not AudioManager:
		print("AudioManager not found - skipping audio settings")
		return
	
	var master = get_setting("audio", "master_volume")
	var sfx = get_setting("audio", "sfx_volume")
	var music = get_setting("audio", "music_volume")
	var ambient = get_setting("audio", "ambient_volume")
	var ui = get_setting("audio", "ui_volume")
	
	AudioManager.set_master_volume(master)
	AudioManager.set_sfx_volume(sfx)
	AudioManager.set_music_volume(music)
	AudioManager.set_ambient_volume(ambient)
	AudioManager.set_ui_volume(ui)
	
	print("Audio settings applied: Master=%.2f, SFX=%.2f, Music=%.2f, Ambient=%.2f, UI=%.2f" % [
		master, sfx, music, ambient, ui
	])

func parse_resolution(resolution_string: String) -> Vector2i:
	"""Parse resolution string like '1920x1080' into Vector2i"""
	var parts = resolution_string.split("x")
	if parts.size() == 2:
		return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i(0, 0)

func apply_quality_preset(preset: String):
	"""Apply a quality preset (low, medium, high, ultra)"""
	if not quality_presets.has(preset):
		print("Unknown quality preset: ", preset)
		return
	
	var preset_values = quality_presets[preset]
	
	# Set all graphics settings from preset
	set_setting("display", "msaa", preset_values["msaa"], false)
	set_setting("graphics", "shadow_quality", preset_values["shadow_quality"], false)
	set_setting("graphics", "fog_enabled", preset_values["fog_enabled"], false)
	set_setting("graphics", "cloud_count", preset_values["cloud_count"], false)
	set_setting("graphics", "view_distance", preset_values["view_distance"], false)
	set_setting("graphics", "quality_preset", preset, false)
	
	# Save once after all changes
	save_settings()
	
	# Apply changes
	apply_all_settings()
	
	print("Applied quality preset: ", preset)

func detect_current_preset() -> String:
	"""Detect if current settings match a preset, return 'custom' if not"""
	var current_msaa = get_setting("display", "msaa")
	var current_shadow = get_setting("graphics", "shadow_quality")
	var current_fog = get_setting("graphics", "fog_enabled")
	var current_clouds = get_setting("graphics", "cloud_count")
	var current_view = get_setting("graphics", "view_distance")
	
	for preset_name in quality_presets:
		var preset = quality_presets[preset_name]
		if (preset["msaa"] == current_msaa and
			preset["shadow_quality"] == current_shadow and
			preset["fog_enabled"] == current_fog and
			preset["cloud_count"] == current_clouds and
			preset["view_distance"] == current_view):
			return preset_name
	
	return "custom"

func reset_to_defaults():
	"""Reset all settings to defaults"""
	for section in default_settings:
		for key in default_settings[section]:
			config.set_value(section, key, default_settings[section][key])
	
	save_settings()
	apply_all_settings()
	print("Settings reset to defaults")

func get_all_settings() -> Dictionary:
	"""Get all current settings as a dictionary"""
	var settings = {}
	for section in config.get_sections():
		settings[section] = {}
		for key in config.get_section_keys(section):
			settings[section][key] = config.get_value(section, key)
	return settings
