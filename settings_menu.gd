extends Control

"""
SettingsMenu - UI for configuring game settings

ARCHITECTURE:
- Tabbed interface: Display, Graphics, Performance
- Reads/writes via SettingsManager singleton
- Apply/Cancel/Reset buttons

INTEGRATION:
- Add to pause menu or main menu
- Listens to SettingsManager.setting_changed signal
"""

# Tab references
@onready var tab_container = $Panel/MarginContainer/VBoxContainer/TabContainer

# Display tab
@onready var resolution_option = $Panel/MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/ResolutionOption
@onready var fullscreen_check = $Panel/MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/FullscreenCheck
@onready var vsync_check = $Panel/MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/VSyncCheck
@onready var msaa_option = $Panel/MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/MSAAOption

# Graphics tab
@onready var quality_preset_option = $Panel/MarginContainer/VBoxContainer/TabContainer/Graphics/VBoxContainer/QualityPresetOption
@onready var shadow_quality_option = $Panel/MarginContainer/VBoxContainer/TabContainer/Graphics/VBoxContainer/ShadowQualityOption
@onready var fog_check = $Panel/MarginContainer/VBoxContainer/TabContainer/Graphics/VBoxContainer/FogCheck
@onready var cloud_count_slider = $Panel/MarginContainer/VBoxContainer/TabContainer/Graphics/VBoxContainer/CloudCountSlider
@onready var cloud_count_label = $Panel/MarginContainer/VBoxContainer/TabContainer/Graphics/VBoxContainer/CloudCountLabel
@onready var view_distance_slider = $Panel/MarginContainer/VBoxContainer/TabContainer/Graphics/VBoxContainer/ViewDistanceSlider
@onready var view_distance_label = $Panel/MarginContainer/VBoxContainer/TabContainer/Graphics/VBoxContainer/ViewDistanceLabel

# Performance tab
@onready var max_fps_option = $Panel/MarginContainer/VBoxContainer/TabContainer/Performance/VBoxContainer/MaxFPSOption

# Audio tab
@onready var master_slider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MasterSlider
@onready var master_label = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MasterLabel
@onready var sfx_slider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/SFXSlider
@onready var sfx_label = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/SFXLabel
@onready var music_slider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MusicSlider
@onready var music_label = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MusicLabel
@onready var ambient_slider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/AmbientSlider
@onready var ambient_label = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/AmbientLabel
@onready var ui_slider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/UISlider
@onready var ui_label = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/UILabel

# Buttons
@onready var apply_button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ApplyButton
@onready var cancel_button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/CancelButton
@onready var reset_button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ResetButton
@onready var close_button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/CloseButton

# Settings manager reference
var settings_manager: Node

# Track if we're updating from code (prevent signal loops)
var updating_ui: bool = false

func _ready():
	# Get settings manager
	var managers = get_tree().get_nodes_in_group("settings_manager")
	if managers.size() > 0:
		settings_manager = managers[0]
	else:
		push_error("SettingsManager not found!")
		return
	
	# Setup UI
	setup_resolution_options()
	setup_msaa_options()
	setup_shadow_quality_options()
	setup_quality_preset_options()
	setup_max_fps_options()
	
	# Load current settings into UI
	load_current_settings()
	
	# Connect signals
	connect_signals()
	
	# Initially hide menu
	hide()

func setup_resolution_options():
	"""Populate resolution dropdown"""
	resolution_option.clear()
	for resolution in settings_manager.resolution_presets:
		resolution_option.add_item(resolution)

func setup_msaa_options():
	"""Populate MSAA dropdown"""
	msaa_option.clear()
	msaa_option.add_item("Disabled")
	msaa_option.add_item("2x")
	msaa_option.add_item("4x")
	msaa_option.add_item("8x")

func setup_shadow_quality_options():
	"""Populate shadow quality dropdown"""
	shadow_quality_option.clear()
	shadow_quality_option.add_item("Low")
	shadow_quality_option.add_item("Medium")
	shadow_quality_option.add_item("High")

func setup_quality_preset_options():
	"""Populate quality preset dropdown"""
	quality_preset_option.clear()
	quality_preset_option.add_item("Low")
	quality_preset_option.add_item("Medium")
	quality_preset_option.add_item("High")
	quality_preset_option.add_item("Ultra")
	quality_preset_option.add_item("Custom")

func setup_max_fps_options():
	"""Populate max FPS dropdown"""
	max_fps_option.clear()
	max_fps_option.add_item("30 FPS")
	max_fps_option.add_item("60 FPS")
	max_fps_option.add_item("120 FPS")
	max_fps_option.add_item("144 FPS")
	max_fps_option.add_item("Unlimited")

func load_current_settings():
	"""Load current settings from SettingsManager into UI"""
	updating_ui = true
	
	# Display settings
	var resolution = settings_manager.get_setting("display", "resolution")
	var resolution_index = settings_manager.resolution_presets.find(resolution)
	if resolution_index >= 0:
		resolution_option.selected = resolution_index
	
	fullscreen_check.button_pressed = settings_manager.get_setting("display", "fullscreen")
	vsync_check.button_pressed = settings_manager.get_setting("display", "vsync")
	msaa_option.selected = settings_manager.get_setting("display", "msaa")
	
	# Graphics settings
	var quality_preset = settings_manager.detect_current_preset()
	var preset_names = ["low", "medium", "high", "ultra", "custom"]
	var preset_index = preset_names.find(quality_preset)
	if preset_index >= 0:
		quality_preset_option.selected = preset_index
	
	shadow_quality_option.selected = settings_manager.get_setting("graphics", "shadow_quality")
	fog_check.button_pressed = settings_manager.get_setting("graphics", "fog_enabled")
	
	var cloud_count = settings_manager.get_setting("graphics", "cloud_count")
	cloud_count_slider.value = cloud_count
	cloud_count_label.text = "Cloud Count: " + str(cloud_count)
	
	var view_distance = settings_manager.get_setting("graphics", "view_distance")
	view_distance_slider.value = view_distance
	view_distance_label.text = "View Distance: " + str(view_distance) + " chunks"
	
	# Performance settings
	var max_fps = settings_manager.get_setting("performance", "max_fps")
	match max_fps:
		30:
			max_fps_option.selected = 0
		60:
			max_fps_option.selected = 1
		120:
			max_fps_option.selected = 2
		144:
			max_fps_option.selected = 3
		_:
			max_fps_option.selected = 4  # Unlimited
	
	# Audio settings
	var master_vol = settings_manager.get_setting("audio", "master_volume")
	master_slider.value = master_vol * 100.0
	master_label.text = "Master Volume: %d%%" % (master_vol * 100)
	
	var sfx_vol = settings_manager.get_setting("audio", "sfx_volume")
	sfx_slider.value = sfx_vol * 100.0
	sfx_label.text = "SFX Volume: %d%%" % (sfx_vol * 100)
	
	var music_vol = settings_manager.get_setting("audio", "music_volume")
	music_slider.value = music_vol * 100.0
	music_label.text = "Music Volume: %d%%" % (music_vol * 100)
	
	var ambient_vol = settings_manager.get_setting("audio", "ambient_volume")
	ambient_slider.value = ambient_vol * 100.0
	ambient_label.text = "Ambient Volume: %d%%" % (ambient_vol * 100)
	
	var ui_vol = settings_manager.get_setting("audio", "ui_volume")
	ui_slider.value = ui_vol * 100.0
	ui_label.text = "UI Volume: %d%%" % (ui_vol * 100)
	
	updating_ui = false

func connect_signals():
	"""Connect UI element signals"""
	# Buttons
	apply_button.pressed.connect(_on_apply_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Display settings
	resolution_option.item_selected.connect(_on_resolution_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	msaa_option.item_selected.connect(_on_msaa_changed)
	
	# Graphics settings
	quality_preset_option.item_selected.connect(_on_quality_preset_changed)
	shadow_quality_option.item_selected.connect(_on_shadow_quality_changed)
	fog_check.toggled.connect(_on_fog_toggled)
	cloud_count_slider.value_changed.connect(_on_cloud_count_changed)
	view_distance_slider.value_changed.connect(_on_view_distance_changed)
	
	# Performance settings
	max_fps_option.item_selected.connect(_on_max_fps_changed)
	
	# Audio settings
	master_slider.value_changed.connect(_on_master_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	ambient_slider.value_changed.connect(_on_ambient_volume_changed)
	ui_slider.value_changed.connect(_on_ui_volume_changed)

func _on_resolution_changed(index: int):
	if updating_ui:
		return
	var resolution = settings_manager.resolution_presets[index]
	settings_manager.set_setting("display", "resolution", resolution, false)

func _on_fullscreen_toggled(pressed: bool):
	if updating_ui:
		return
	settings_manager.set_setting("display", "fullscreen", pressed, false)
	
	# Warn user if in editor
	if OS.has_feature("editor") and pressed:
		print("WARNING: Fullscreen only works in exported builds, not in editor")

func _on_vsync_toggled(pressed: bool):
	if updating_ui:
		return
	settings_manager.set_setting("display", "vsync", pressed, false)

func _on_msaa_changed(index: int):
	if updating_ui:
		return
	settings_manager.set_setting("display", "msaa", index, false)
	_check_if_custom_preset()

func _on_quality_preset_changed(index: int):
	if updating_ui:
		return
	
	var preset_names = ["low", "medium", "high", "ultra", "custom"]
	var preset = preset_names[index]
	
	if preset != "custom":
		# Apply preset
		settings_manager.apply_quality_preset(preset)
		# Reload UI to show preset values
		load_current_settings()

func _on_shadow_quality_changed(index: int):
	if updating_ui:
		return
	settings_manager.set_setting("graphics", "shadow_quality", index, false)
	_check_if_custom_preset()

func _on_fog_toggled(pressed: bool):
	if updating_ui:
		return
	settings_manager.set_setting("graphics", "fog_enabled", pressed, false)
	_check_if_custom_preset()

func _on_cloud_count_changed(value: float):
	if updating_ui:
		return
	cloud_count_label.text = "Cloud Count: " + str(int(value))
	settings_manager.set_setting("graphics", "cloud_count", int(value), false)
	_check_if_custom_preset()

func _on_view_distance_changed(value: float):
	if updating_ui:
		return
	view_distance_label.text = "View Distance: " + str(int(value)) + " chunks"
	settings_manager.set_setting("graphics", "view_distance", int(value), false)
	_check_if_custom_preset()

func _on_max_fps_changed(index: int):
	if updating_ui:
		return
	var fps_values = [30, 60, 120, 144, 0]  # 0 = unlimited
	settings_manager.set_setting("performance", "max_fps", fps_values[index], false)

func _on_master_volume_changed(value: float):
	if updating_ui:
		return
	master_label.text = "Master Volume: %d%%" % value
	settings_manager.set_setting("audio", "master_volume", value / 100.0, false)

func _on_sfx_volume_changed(value: float):
	if updating_ui:
		return
	sfx_label.text = "SFX Volume: %d%%" % value
	settings_manager.set_setting("audio", "sfx_volume", value / 100.0, false)

func _on_music_volume_changed(value: float):
	if updating_ui:
		return
	music_label.text = "Music Volume: %d%%" % value
	settings_manager.set_setting("audio", "music_volume", value / 100.0, false)

func _on_ambient_volume_changed(value: float):
	if updating_ui:
		return
	ambient_label.text = "Ambient Volume: %d%%" % value
	settings_manager.set_setting("audio", "ambient_volume", value / 100.0, false)

func _on_ui_volume_changed(value: float):
	if updating_ui:
		return
	ui_label.text = "UI Volume: %d%%" % value
	settings_manager.set_setting("audio", "ui_volume", value / 100.0, false)

func _check_if_custom_preset():
	"""Check if settings no longer match a preset, update to 'custom'"""
	var current_preset = settings_manager.detect_current_preset()
	if current_preset == "custom":
		updating_ui = true
		quality_preset_option.selected = 4  # Custom index
		updating_ui = false

func _on_apply_pressed():
	"""Apply all pending settings changes"""
	settings_manager.save_settings()
	settings_manager.apply_all_settings()
	
	# Apply runtime changes to world systems
	apply_runtime_changes()
	
	print("Settings applied")

func apply_runtime_changes():
	"""Apply settings that need runtime updates to world systems"""
	# Find world node
	var world = get_tree().root.get_node_or_null("World")
	if not world:
		return
	
	# Update view distance
	var view_distance = settings_manager.get_setting("graphics", "view_distance")
	if world.has_node("ChunkManager"):
		var chunk_manager = world.get_node("ChunkManager")
		if chunk_manager.has_method("update_view_distance"):
			chunk_manager.update_view_distance(view_distance)
	
	# Update cloud count
	var cloud_count = settings_manager.get_setting("graphics", "cloud_count")
	if world.has_node("DayNightCycle"):
		var day_night = world.get_node("DayNightCycle")
		if day_night.has_method("update_cloud_count"):
			day_night.update_cloud_count(cloud_count)
	
	# Update fog
	var fog_enabled = settings_manager.get_setting("graphics", "fog_enabled")
	if world.has_node("DayNightCycle"):
		var day_night = world.get_node("DayNightCycle")
		if day_night.world_environment and day_night.world_environment.environment:
			day_night.world_environment.environment.fog_enabled = fog_enabled
	
	# Update shadow quality
	var shadow_quality = settings_manager.get_setting("graphics", "shadow_quality")
	if world.has_node("DayNightCycle"):
		var day_night = world.get_node("DayNightCycle")
		if day_night.sun:
			match shadow_quality:
				0:  # Low
					day_night.sun.shadow_blur = 0.5
				1:  # Medium
					day_night.sun.shadow_blur = 1.0
				2:  # High
					day_night.sun.shadow_blur = 2.0

func _on_cancel_pressed():
	"""Cancel changes and reload from saved settings"""
	settings_manager.load_settings()
	load_current_settings()
	print("Settings cancelled, reloaded from file")

func _on_reset_pressed():
	"""Reset all settings to defaults"""
	settings_manager.reset_to_defaults()
	load_current_settings()
	print("Settings reset to defaults")

func _on_close_pressed():
	"""Close the settings menu"""
	hide()
