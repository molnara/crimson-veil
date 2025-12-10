extends Node3D

@onready var chunk_manager = $ChunkManager
@onready var player = $Player
@onready var vegetation_spawner = $VegetationSpawner
@onready var critter_spawner = $CritterSpawner
@onready var day_night_cycle = $DayNightCycle

var chunks_ready = false
var settings_manager: Node
var settings_menu: Control

func _ready():
	# Get settings manager singleton
	var managers = get_tree().get_nodes_in_group("settings_manager")
	if managers.size() > 0:
		settings_manager = managers[0]
		# Apply graphics settings from SettingsManager
		apply_graphics_settings()
	
	# Load and setup settings menu
	var settings_menu_scene = load("res://settings_menu.tscn")
	if settings_menu_scene:
		settings_menu = settings_menu_scene.instantiate()
		add_child(settings_menu)
		settings_menu.hide()
		print("Settings menu loaded successfully")
	else:
		print("ERROR: Failed to load settings_menu.tscn")
	
	# Connect the player to the chunk manager
	chunk_manager.set_player(player)
	
	# Initialize vegetation spawner
	if vegetation_spawner:
		vegetation_spawner.initialize(chunk_manager)
	
	# Initialize critter spawner
	if critter_spawner:
		critter_spawner.initialize(chunk_manager)
	
	# Generate initial chunks
	chunk_manager.generate_initial_chunks()
	
	# Calculate terrain height at spawn position and place player on ground
	var spawn_x = player.global_position.x
	var spawn_z = player.global_position.z
	var terrain_height = chunk_manager.calculate_terrain_height_at_position(spawn_x, spawn_z)
	
	# Place player slightly above terrain (account for capsule height)
	player.global_position.y = terrain_height + 2.0  # +2.0 for capsule radius
	
	# Wait a couple frames for physics to settle
	await get_tree().process_frame
	await get_tree().process_frame
	
	chunks_ready = true
	
	print("World initialized. Player connected to ChunkManager.")
	print("Controls:")
	print("  WASD - Move")
	print("  Space - Jump")  
	print("  Shift - Sprint")
	print("  Mouse - Look around")
	print("  Esc - Toggle mouse capture")
	print("  F1 - Settings Menu")

func apply_graphics_settings():
	"""Apply graphics settings from SettingsManager on startup"""
	if not settings_manager:
		return
	
	# Apply view distance to chunk manager
	var view_distance = settings_manager.get_setting("graphics", "view_distance")
	if chunk_manager:
		chunk_manager.view_distance = view_distance
		print("Applied view distance: ", view_distance)
	
	# Apply cloud count to day/night cycle
	var cloud_count = settings_manager.get_setting("graphics", "cloud_count")
	if day_night_cycle:
		day_night_cycle.cloud_count = cloud_count
		print("Applied cloud count: ", cloud_count)
	
	# Apply fog setting
	var fog_enabled = settings_manager.get_setting("graphics", "fog_enabled")
	if day_night_cycle and day_night_cycle.world_environment:
		var env = day_night_cycle.world_environment.environment
		if env:
			env.fog_enabled = fog_enabled
			print("Applied fog enabled: ", fog_enabled)
	
	# Apply shadow quality
	var shadow_quality = settings_manager.get_setting("graphics", "shadow_quality")
	if day_night_cycle and day_night_cycle.sun:
		match shadow_quality:
			0:  # Low
				day_night_cycle.sun.shadow_blur = 0.5
			1:  # Medium
				day_night_cycle.sun.shadow_blur = 1.0
			2:  # High
				day_night_cycle.sun.shadow_blur = 2.0
		print("Applied shadow quality: ", shadow_quality)

func _input(event):
	"""Handle settings menu toggle"""
	# Use F1 key directly instead of relying on input action
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			print("F1 pressed - toggling settings menu")
			if settings_menu:
				print("Settings menu exists: ", settings_menu.visible)
				if settings_menu.visible:
					settings_menu.hide()
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					print("Settings menu hidden")
				else:
					settings_menu.show()
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					print("Settings menu shown")
				get_viewport().set_input_as_handled()
			else:
				print("ERROR: Settings menu is null!")
		
		# Also support ESC to close settings when it's open
		if event.keycode == KEY_ESCAPE and settings_menu and settings_menu.visible:
			settings_menu.hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_viewport().set_input_as_handled()
