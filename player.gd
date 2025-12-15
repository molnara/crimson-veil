extends CharacterBody3D

# Movement settings
@export var move_speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var fly_speed: float = 15.0  # Speed when flying

# Controller settings
@export var controller_look_sensitivity: float = 3.0  # Right stick sensitivity
@export var controller_deadzone: float = 0.15  # Analog stick deadzone

# Container interaction settings
const CONTAINER_INTERACTION_RANGE: float = 3.0  # Shorter range for containers vs harvesting (5.0)

var is_flying: bool = false  # Fly/noclip mode toggle
var current_container: Node = null  # Container player is looking at

# Footstep system
var footstep_timer: float = 0.0
const WALK_FOOTSTEP_INTERVAL: float = 0.45  # Seconds between steps when walking
const SPRINT_FOOTSTEP_INTERVAL: float = 0.28  # Seconds between steps when sprinting

# Block placement cooldown (prevent rapid-fire with controller)
var placement_cooldown_timer: float = 0.0
const PLACEMENT_COOLDOWN: float = 0.2  # 200ms cooldown between placements

# UI state tracking (for container suppression)
var ui_state_before_container = {
	"inventory_was_visible": false,
	"crafting_was_visible": false
}

# Death/Respawn system
var death_screen: Control  # Death screen UI
var is_dead: bool = false
var death_count: int = 0  # Track deaths this session
var spawn_position: Vector3  # Respawn location

# Camera
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D = $SpringArm3D

# Systems
var harvesting_system: HarvestingSystem
var building_system: BuildingSystem
var crafting_system: CraftingSystem
var tool_system: ToolSystem
var combat_system: CombatSystem  # Combat system
var inventory: Inventory
var health_hunger_system: HealthHungerSystem
var harvest_ui: Control
var crafting_ui: Control
var inventory_ui: Control
var health_ui: Control
var container_ui: Control  # Container UI
var settings_menu: Control  # Settings menu

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Set camera to proper human eye height
	# Human: 1.75m tall, eyes at ~1.65m (94% of height)
	if spring_arm:
		spring_arm.position.y = 1.65  # Realistic human eye height
	
	# Adjust camera near clip to prevent clipping into nearby objects
	if camera:
		camera.near = 0.05  # Reduced from default 0.1 to see objects closer
	
	# Capture the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set collision layers - player only collides with terrain, not critters
	collision_layer = 1  # Player is on layer 1
	collision_mask = 1  # Only detect layer 1 (terrain) - resources use raycasts, not physics
	# Layer 8 (critters) is intentionally excluded so player passes through them
	
	# Enable floor snapping and sliding for smooth terrain following
	floor_constant_speed = true
	floor_block_on_wall = false
	floor_snap_length = 0.5  # Increased snap distance for varied terrain
	floor_max_angle = deg_to_rad(46)  # Allow steeper slopes (46 degrees)
	
	# Initialize inventory
	inventory = Inventory.new()
	add_child(inventory)
	
	# Create weather particles immediately (must be in player, not autoload)
	_create_weather_particles()
	
	# Get health/hunger system from scene (created in player.tscn)
	health_hunger_system = $HealthHungerSystem if has_node("HealthHungerSystem") else null
	if not health_hunger_system:
		# Fallback: create one if it doesn't exist
		print("Warning: HealthHungerSystem not found in scene, creating new one")
		health_hunger_system = HealthHungerSystem.new()
		add_child(health_hunger_system)
	else:
		print("HealthHungerSystem found in scene!")
	
	# Connect to death signal
	if health_hunger_system:
		health_hunger_system.player_died.connect(_on_player_died)
		print("[Player] Connected to death signal")
	
	# Store initial spawn position (deferred until world loads)
	# Raycast needs terrain to exist first!
	call_deferred("setup_spawn_position")
	
	# Initialize tool system
	tool_system = ToolSystem.new()
	add_child(tool_system)
	
	# Initialize harvesting system
	harvesting_system = HarvestingSystem.new()
	add_child(harvesting_system)
	harvesting_system.initialize(self, camera, inventory, tool_system)
	
	# Initialize building system
	building_system = BuildingSystem.new()
	add_child(building_system)
	building_system.initialize(self, camera, inventory)
	
	# Initialize crafting system
	crafting_system = CraftingSystem.new()
	add_child(crafting_system)
	crafting_system.initialize(inventory)
	
	# Combat system should be added as a child node in player.tscn
	# with combat_system.gd script attached
	combat_system = get_node_or_null("CombatSystem")
	if combat_system:
		combat_system.initialize(self, camera, health_hunger_system)
		print("[Player] Combat system found and initialized")
	else:
		print("[Player] WARNING: CombatSystem node not found! Add it to player.tscn")
	
	# Connect harvesting signals
	harvesting_system.harvest_completed.connect(_on_harvest_completed)
	
	# Load and setup UI
	call_deferred("setup_ui")

func _input(event):
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/2)
	
	# Toggle mouse capture (ESC/Start button OR B button to close menus)
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("combat_dodge"):
		# Close container if open (PRIORITY #1)
		if container_ui and container_ui.visible:
			close_container_ui()
			return
		
		# Close settings menu if open (PRIORITY #2)
		if settings_menu and settings_menu.visible:
			settings_menu.hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			# Play close sound (hide() in settings_menu doesn't have sound, so add here)
			AudioManager.play_sound("inventory_toggle", "ui", false, false)
			return
		
		# Close inventory if open (PRIORITY #3)
		if inventory_ui and inventory_ui.visible:
			inventory_ui.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			# Play close sound
			AudioManager.play_sound("inventory_toggle", "ui", false, false)
			return
		
		# Close crafting menu if open (PRIORITY #4)
		if crafting_ui and crafting_ui.visible:
			crafting_ui.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			# Play close sound
			AudioManager.play_sound("inventory_toggle", "ui", false, false)
			return
		
		# If nothing to close and B button pressed, ignore (don't dodge)
		if event.is_action_pressed("combat_dodge"):
			return  # B button consumed by menu close, don't process as dodge
		
		# ESC with nothing open - just release mouse (don't open settings)
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# B button (controller_sprint) also closes container
	if event.is_action_pressed("controller_sprint"):
		if container_ui and container_ui.visible:
			close_container_ui()
			return
	
	# Block inventory/crafting/building keys when ANY UI is open
	var any_ui_open = (container_ui and container_ui.visible) or \
	                  (inventory_ui and inventory_ui.visible) or \
	                  (crafting_ui and crafting_ui.visible) or \
	                  (settings_menu and settings_menu.visible)
	
	if any_ui_open:
		# Only allow ESC/B to close, block all other UI inputs
		return
	
	# Toggle inventory with I key or Y button (Xbox) - ONLY if no UI open
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			if inventory_ui:
				inventory_ui.toggle_visibility()
			print("I key pressed - Toggle inventory")
	
	if event.is_action_pressed("toggle_inventory"):  # Y button on Xbox
		if inventory_ui:
			inventory_ui.toggle_visibility()
		print("Toggle inventory")
	
	# Toggle crafting menu with C key or X button (Xbox) - ONLY if no UI open
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			if crafting_ui:
				crafting_ui.toggle_visibility()
			print("C key pressed - Toggle crafting")
	
	if event.is_action_pressed("toggle_crafting"):  # X button on Xbox
		if crafting_ui:
			crafting_ui.toggle_visibility()
		print("Toggle crafting")
	
	# Container interaction with E key
	if event.is_action_pressed("interact"):  # E key
		var container = get_container_at_cursor()
		if container and not is_flying:
			open_container(container)
	
	# Toggle fly mode with F key
	if event.is_action_pressed("toggle_fly"):
		is_flying = !is_flying
		print("Fly mode: ", "ON" if is_flying else "OFF")
	
	# LB - cycle backwards (MUST be checked BEFORE cycle_tool action which may have LB mapped)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_LEFT_SHOULDER:
		if tool_system:
			tool_system.cycle_tool_reverse()
			AudioManager.play_sound("tool_switch", "ui", false, false)
			RumbleManager.play_ui_click()
		return  # Don't process further - prevents cycle_tool from also triggering
	
	# Cycle tools with T key or D-pad Left/Right (RB may also be mapped here)
	if event.is_action_pressed("cycle_tool"):
		if tool_system:
			tool_system.cycle_tool()
			# Play tool switch sound
			AudioManager.play_sound("tool_switch", "ui", false, false)
			# RUMBLE: Tool switch feedback
			RumbleManager.play_ui_click()
	
	# === COMBAT INPUT ===
	# Simple Minecraft-style attack - press RT/LMB to swing
	var ui_is_open = (container_ui and container_ui.visible) or \
	                 (inventory_ui and inventory_ui.visible) or \
	                 (crafting_ui and crafting_ui.visible)
	var in_build_mode = building_system and building_system.preview_mode
	
	# Attack on button press
	if event.is_action_pressed("combat_attack") and not ui_is_open and not in_build_mode:
		if combat_system:
			combat_system.perform_attack()
	
	# Weapon/Tool switching with RB (forward)
	if event.is_action_pressed("cycle_weapon"):  # RB
		if tool_system:
			tool_system.cycle_tool()
			AudioManager.play_sound("tool_switch", "ui", false, false)
			RumbleManager.play_ui_click()
	
	# Toggle building mode with B key or D-pad Up
	if event.is_action_pressed("toggle_building"):
		if building_system:
			if building_system.preview_mode:
				building_system.disable_building_mode()
			else:
				building_system.enable_building_mode("stone_block")
	
	# Cycle block type with Tab or C key or D-pad Down when in building mode
	if building_system and building_system.preview_mode:
		if event.is_action_pressed("cycle_block_type"):
			# Cycle through block types (including chest!)
			var types = ["stone_block", "stone_wall", "stone_floor", "wood_plank", "chest"]
			var current_index = types.find(building_system.current_block_type)
			var next_index = (current_index + 1) % types.size()
			building_system.set_block_type(types[next_index])
	
	# Controller: RT (interact/harvest/combat) and LT (cancel/remove)
	if event.is_action_pressed("controller_interact"):  # RT
		# Check placement cooldown first
		if placement_cooldown_timer > 0:
			return  # Still in cooldown, ignore input
		
		# Building mode takes priority - place blocks
		if building_system and building_system.preview_mode:
			if building_system.place_block():
				# Block placed successfully - start cooldown
				placement_cooldown_timer = PLACEMENT_COOLDOWN
		# Otherwise: combat_attack handles both enemies AND resources now
		# (handled above in combat input section)
	
	if event.is_action_pressed("controller_cancel"):  # LT
		# Check placement cooldown first (also applies to removal)
		if placement_cooldown_timer > 0:
			return  # Still in cooldown, ignore input
		
		if building_system and building_system.preview_mode:
			# Try to remove block at cursor
			var block_data = building_system.get_block_at_raycast()
			if block_data:
				if building_system.remove_block_at_position(block_data["position"]):
					# Block removed successfully - start cooldown
					placement_cooldown_timer = PLACEMENT_COOLDOWN
		elif harvesting_system and harvesting_system.is_harvesting:
			harvesting_system.cancel_harvest()
			print("Harvest manually cancelled")
	
	# Mouse button handling
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Building mode takes priority
			if building_system and building_system.preview_mode:
				building_system.place_block()
			# Otherwise: combat_attack handles both enemies AND resources
			# (handled above in combat input section)
		
		# Right-click: Remove block in building mode, or cancel harvest
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if building_system and building_system.preview_mode:
				# Try to remove block at cursor
				var block_data = building_system.get_block_at_raycast()
				if block_data:
					building_system.remove_block_at_position(block_data["position"])
			elif harvesting_system and harvesting_system.is_harvesting:
				harvesting_system.cancel_harvest()
				print("Harvest manually cancelled")
	
	# Also cancel harvest when opening menu (ESC) but only if not already opening menu
	if event.is_action_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if harvesting_system and harvesting_system.is_harvesting:
			harvesting_system.cancel_harvest()
			print("Harvest cancelled by menu")
	
	# Print inventory with I key (debug)
	if event.is_action_pressed("print_inventory"):
		if inventory:
			inventory.print_inventory()

func setup_ui():
	"""Setup the harvest UI and crafting UI"""
	print("Loading harvest UI...")
	var ui_scene = load("res://harvest_ui.tscn")
	if ui_scene:
		harvest_ui = ui_scene.instantiate()
		get_tree().root.add_child(harvest_ui)
		
		# Connect UI to systems
		if harvest_ui.has_method("set_inventory"):
			harvest_ui.set_inventory(inventory)
			print("Inventory connected to UI")
		
		if harvest_ui.has_method("set_tool_system"):
			harvest_ui.set_tool_system(tool_system)
			print("Tool system connected to UI")
		
		if harvest_ui.has_method("get_progress_bar"):
			harvesting_system.progress_bar = harvest_ui.get_progress_bar()
			print("Progress bar connected")
		
		if harvest_ui.has_method("get_target_label"):
			harvesting_system.target_label = harvest_ui.get_target_label()
			print("Target label connected")
		
		print("Harvest UI loaded successfully")
	else:
		print("Warning: Could not load harvest_ui.tscn")
	
	# Load crafting UI
	print("Creating crafting UI...")
	crafting_ui = preload("res://crafting_ui.gd").new()
	get_tree().root.add_child(crafting_ui)
	crafting_ui.set_crafting_system(crafting_system)
	crafting_ui.set_inventory(inventory)
	print("Crafting UI loaded successfully")
	
	# Load inventory UI
	print("Loading inventory UI...")
	var inventory_ui_scene = load("res://inventory_ui.tscn")
	if inventory_ui_scene:
		inventory_ui = inventory_ui_scene.instantiate()
		get_tree().root.add_child(inventory_ui)
		inventory_ui.set_inventory(inventory)
		inventory_ui.set_health_system(health_hunger_system)
		print("Inventory UI loaded successfully")
	else:
		print("ERROR: Could not load inventory_ui.tscn")
	
	# Load health UI
	print("Creating health UI...")
	var health_ui_scene = load("res://health_ui.tscn")
	if health_ui_scene:
		health_ui = health_ui_scene.instantiate()
		get_tree().root.add_child(health_ui)
		print("Health UI loaded successfully")
	else:
		print("Warning: Could not load health_ui.tscn")
	
	# Load container UI (NEW: Load .tscn instead of .gd)
	print("Loading container UI...")
	var container_ui_scene = load("res://container_ui.tscn")
	if container_ui_scene:
		container_ui = container_ui_scene.instantiate()
		get_tree().root.add_child(container_ui)
		print("Container UI loaded successfully (scene-based)")
	else:
		print("ERROR: Could not load container_ui.tscn")
	
	# Load settings menu
	print("Loading settings menu...")
	var settings_menu_scene = load("res://settings_menu.tscn")
	if settings_menu_scene:
		settings_menu = settings_menu_scene.instantiate()
		get_tree().root.add_child(settings_menu)
		settings_menu.hide()  # Start hidden
		print("Settings menu loaded successfully")
	else:
		print("Warning: Could not load settings_menu.tscn")
	
	# Load combat UI (NEW: Task 1.2)
	print("Loading combat UI...")
	var combat_ui_scene = load("res://combat_ui.tscn")
	if combat_ui_scene:
		var combat_ui = combat_ui_scene.instantiate()
		get_tree().root.add_child(combat_ui)
		print("Combat UI loaded successfully (crosshair + charge vignette)")
	else:
		print("Warning: Could not load combat_ui.tscn")
	
	# Load death screen UI (NEW: Task 4.1)
	print("Loading death screen UI...")
	var death_screen_scene = load("res://death_screen.tscn")
	if death_screen_scene:
		death_screen = death_screen_scene.instantiate()
		get_tree().root.add_child(death_screen)
		death_screen.respawn_requested.connect(_on_respawn_requested)
		print("Death screen loaded successfully")
	else:
		print("Warning: Could not load death_screen.tscn")

func _get_terrain_surface() -> String:
	"""Detect surface type under player for footstep sounds"""
	# Get chunk manager (should be autoload, fallback to finding in tree)
	var chunk_manager = get_node_or_null("/root/ChunkManager")
	if not chunk_manager:
		# Fallback: try to find it in the scene tree
		chunk_manager = get_tree().root.get_node_or_null("World/ChunkManager")
	
	if not chunk_manager:
		return "grass"  # Safe fallback
	
	# Get player's world position
	var world_x = global_position.x
	var world_z = global_position.z
	
	# Calculate biome (mirrors chunk.gd logic exactly)
	var base_noise = chunk_manager.noise.get_noise_2d(world_x, world_z)
	var temperature = chunk_manager.temperature_noise.get_noise_2d(world_x, world_z)
	var moisture = chunk_manager.moisture_noise.get_noise_2d(world_x, world_z)
	
	# Determine biome using ChunkManager thresholds
	# NOTE: We don't check spawn zone override here - footsteps should match VISUAL biome
	# (Spawn zone only affects terrain generation in chunk.gd, not audio feedback)
	
	# TRANSITION SMOOTHING: Add small buffer zones to prevent harsh audio transitions
	# Smaller buffer (0.03) for natural feel in both directions
	const TRANSITION_BUFFER: float = 0.03  # 3% buffer zone (~2-4 meters)
	
	# Ocean/Beach (with extended transition zone)
	if base_noise < (chunk_manager.beach_threshold + TRANSITION_BUFFER):
		if base_noise < chunk_manager.ocean_threshold:
			return "sand"  # Ocean (wading sounds)
		else:
			return "sand"  # Beach (extended slightly into grassland for smooth transition)
	
	# Mountain/Snow
	elif base_noise > (chunk_manager.mountain_threshold - TRANSITION_BUFFER):
		if temperature < chunk_manager.snow_temperature:
			return "snow"  # Snow biome
		else:
			return "stone"  # Mountain
	
	# Mid-level biomes
	else:
		# Hot and dry = desert
		if temperature > chunk_manager.desert_temperature and moisture < chunk_manager.desert_moisture:
			return "stone"  # Desert (rocky/hard ground)
		# Wet = forest
		elif moisture > chunk_manager.forest_moisture:
			return "grass"  # Forest
		# Default = grassland
		else:
			return "grass"  # Grassland

func get_container_at_cursor() -> Node:
	"""Raycast for containers on Layer 3 within 3m range"""
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from - camera.global_transform.basis.z * CONTAINER_INTERACTION_RANGE
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4  # Layer 3 (2^2 = 4) - interactive objects
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		# The collider is the StaticBody3D child of the container
		# Parent is the StorageContainer
		var parent = result.collider.get_parent()
		if parent and parent.has_method("open"):
			# Debug: Container found
			if parent != current_container:
				print("🔍 Looking at container: ", parent.container_name)
			return parent
	
	return null

func open_container(container: Node):
	"""Open a container (called when player interacts)"""
	if not container or not container.has_method("open"):
		print("ERROR: Invalid container")
		return
	
	# Don't open if container UI is already visible
	if container_ui and container_ui.visible:
		print("Container UI already open, ignoring interaction")
		return
	
	# Save current UI state BEFORE opening container
	save_ui_state()
	
	# Hide other UIs
	suppress_other_uis()
	
	# Open the container (sets is_open flag, emits signal)
	container.open()
	current_container = container
	
	# Show container UI
	if container_ui:
		container_ui.show_container(container, inventory, self)
		print("✅ Container UI opened!")
	else:
		print("ERROR: Container UI not available")
		print("   Container has ", container.get_item_count(), " item types inside")

func close_container_ui():
	"""Close the container UI and restore other UIs"""
	if container_ui:
		container_ui.close_container()
	
	# Restore other UIs
	restore_ui_state()
	
	current_container = null
	print("Container closed, UI state restored")

func save_ui_state():
	"""Save visibility state of other UIs before opening container"""
	ui_state_before_container.inventory_was_visible = inventory_ui.visible if inventory_ui else false
	ui_state_before_container.crafting_was_visible = crafting_ui.visible if crafting_ui else false

func suppress_other_uis():
	"""Hide other UIs when container opens"""
	if inventory_ui:
		inventory_ui.visible = false
	if crafting_ui:
		crafting_ui.visible = false
	if harvest_ui:
		# Hide harvest UI (includes inventory debug text)
		harvest_ui.visible = false
	# Note: health_ui stays visible (always-on)

func restore_ui_state():
	"""Restore previous UI visibility after container closes"""
	if inventory_ui and ui_state_before_container.inventory_was_visible:
		inventory_ui.visible = true
	if crafting_ui and ui_state_before_container.crafting_was_visible:
		crafting_ui.visible = true
	if harvest_ui:
		# Always restore harvest UI (needed for harvesting to work)
		harvest_ui.visible = true

func _on_harvest_completed(_resource: HarvestableResource, drops: Dictionary):
	"""Called when a resource is successfully harvested"""
	if inventory and drops.has("item") and drops.has("amount"):
		inventory.add_item(drops["item"], drops["amount"])
		# Play item pickup sound
		AudioManager.play_sound("item_pickup", "ui", true, false)
		# RUMBLE: Item pickup feedback
		RumbleManager.play_item_pickup()

func apply_deadzone(value: float, deadzone: float) -> float:
	"""Apply deadzone to analog stick input"""
	if abs(value) < deadzone:
		return 0.0
	# Scale the remaining range to 0-1
	return (abs(value) - deadzone) / (1.0 - deadzone) * sign(value)

func _physics_process(delta):
	# Don't process movement if dead
	if is_dead:
		velocity = Vector3.ZERO
		return
	
	# Update placement cooldown timer
	if placement_cooldown_timer > 0:
		placement_cooldown_timer -= delta
	
	# Controller camera look (right stick)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var look_x = apply_deadzone(Input.get_axis("controller_look_left", "controller_look_right"), controller_deadzone)
		var look_y = apply_deadzone(Input.get_axis("controller_look_up", "controller_look_down"), controller_deadzone)
		
		if abs(look_x) > 0 or abs(look_y) > 0:
			rotate_y(-look_x * controller_look_sensitivity * delta)
			spring_arm.rotate_x(-look_y * controller_look_sensitivity * delta)
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/2)
	
	# Fly mode - noclip movement
	if is_flying:
		# No gravity or collision in fly mode
		velocity = Vector3.ZERO
		
		# Get input direction (keyboard + left stick)
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		# Controller left stick (with deadzone)
		var stick_x = apply_deadzone(Input.get_axis("controller_move_left", "controller_move_right"), controller_deadzone)
		var stick_y = apply_deadzone(Input.get_axis("controller_move_forward", "controller_move_backward"), controller_deadzone)
		if abs(stick_x) > abs(input_dir.x):
			input_dir.x = stick_x
		if abs(stick_y) > abs(input_dir.y):
			input_dir.y = stick_y
		
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		# Up/down movement (Space/Shift or A/B buttons)
		if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("controller_jump"):
			direction.y += 1.0
		if Input.is_action_pressed("ui_shift") or Input.is_action_pressed("controller_sprint"):
			direction.y -= 1.0
		
		direction = direction.normalized()
		
		if direction:
			velocity = direction * fly_speed
		
		# Move without collision in fly mode
		position += velocity * delta
		return
	
	# Normal ground-based movement
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Get input direction (keyboard + left stick) - MOVED UP for dodge detection
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Controller left stick (with deadzone)
	var stick_x = apply_deadzone(Input.get_axis("controller_move_left", "controller_move_right"), controller_deadzone)
	var stick_y = apply_deadzone(Input.get_axis("controller_move_forward", "controller_move_backward"), controller_deadzone)
	if abs(stick_x) > abs(input_dir.x):
		input_dir.x = stick_x
	if abs(stick_y) > abs(input_dir.y):
		input_dir.y = stick_y
	
	# Handle jump/interact with A button (controller) or Space/E (keyboard)
	# A button = Harvest/Interact when looking at resource, Jump otherwise
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("controller_interact")):
		var container = get_container_at_cursor()
		if container and not is_flying:
			# Container interaction
			open_container(container)
			print("📦 Container interaction (A button)")
		elif is_on_floor() and not harvesting_system.is_harvesting and not harvesting_system.is_looking_at_resource() and not (building_system and building_system.preview_mode):
			# Jump (only if NOT harvesting AND NOT looking at resource AND NOT in build mode)
			velocity.y = jump_velocity
			print("⬆️ JUMP! (A button)")
	
	# Calculate movement direction
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Debug: Print position when pressing P
	if Input.is_action_just_pressed("ui_text_completion_query"):
		print("Player Y: ", global_position.y)
		print("On floor: ", is_on_floor())
		print("Velocity: ", velocity)
	
	# Apply movement (Shift OR B button for sprint)
	var is_sprinting = Input.is_action_pressed("ui_shift") or Input.is_action_pressed("combat_dodge")
	var current_speed = sprint_speed if is_sprinting else move_speed
	
	# Apply hunger speed penalty
	if health_hunger_system:
		current_speed *= health_hunger_system.get_movement_speed_multiplier()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Slow down
		var deceleration = current_speed * 2.0 if is_on_floor() else current_speed * 0.3
		velocity.x = move_toward(velocity.x, 0, deceleration * delta * 60.0)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta * 60.0)
	
	# Move with slide
	move_and_slide()
	
	# === FOOTSTEP SYSTEM ===
	# Play footsteps when: (on floor OR on steep slope) + moving + not flying
	# Steep slope detection: if Y velocity is small, we're probably on ground even if angle > floor_max_angle
	# Relaxed thresholds to catch sliding on steep banks and slopes
	var is_grounded = is_on_floor() or (abs(velocity.y) < 3.5 and velocity.length() > 0.3)
	
	if is_grounded and not is_flying and direction.length() > 0.1:
		# Determine footstep interval based on movement speed
		var is_sprinting_now = Input.is_action_pressed("ui_shift") or Input.is_action_pressed("controller_sprint")
		var footstep_interval = SPRINT_FOOTSTEP_INTERVAL if is_sprinting_now else WALK_FOOTSTEP_INTERVAL
		
		# Update footstep timer
		footstep_timer += delta
		
		# Play footstep when timer exceeds interval
		if footstep_timer >= footstep_interval:
			# Detect surface type
			var surface = _get_terrain_surface()
			
			# Play footstep sound variant
			AudioManager.play_sound_variant("footstep_%s" % surface, 3, "sfx", true, false)
			
			# RUMBLE: Footstep feedback (if enabled)
			RumbleManager.play_footstep()
			
			# Reset timer
			footstep_timer = 0.0
	else:
		# Reset timer when not moving (prevents immediate sound when starting to walk)
		footstep_timer = 0.0
	
	# If we're stuck on a small obstacle and moving, try to step up
	if is_on_wall() and direction.length() > 0:
		var wall_normal = get_wall_normal()
		# Check if it's a small step (not a steep wall)
		if wall_normal.y > -0.5:  # Not a cliff
			# Try a small upward boost to step over small obstacles
			velocity.y = 3.0
	
	# Prevent getting stuck by adding tiny random movement when velocity is near zero but input exists
	if direction.length() > 0 and velocity.length() < 0.5 and is_on_floor():
		# We're trying to move but barely moving - might be stuck
		velocity += direction * current_speed * 0.5

# === DEATH & RESPAWN SYSTEM (Task 4.1) ===

func _on_player_died() -> void:
	"""Called when health reaches 0"""
	if is_dead:
		return  # Already dead, ignore
	
	is_dead = true
	death_count += 1
	print("[Player] Death #%d detected!" % death_count)
	
	# Stop all movement
	velocity = Vector3.ZERO
	
	# Release mouse for UI interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Hide all gameplay UIs
	if inventory_ui:
		inventory_ui.visible = false
	if crafting_ui:
		crafting_ui.visible = false
	if harvest_ui:
		harvest_ui.visible = false
	if container_ui:
		container_ui.visible = false
	
	# Show death screen with death counter
	if death_screen:
		death_screen.show_death_screen(death_count)
	else:
		print("[Player] ERROR: Death screen not found!")
	
	print("[Player] Death screen shown, waiting for respawn...")

func _on_respawn_requested() -> void:
	"""Called when player clicks respawn button"""
	print("[Player] Respawn requested!")
	
	# Reset health and hunger to full
	if health_hunger_system:
		health_hunger_system.current_health = health_hunger_system.max_health
		health_hunger_system.current_hunger = health_hunger_system.max_hunger
		health_hunger_system.has_died = false  # Reset death flag for next death
		
		# Emit signals to update UI
		health_hunger_system.health_changed.emit(
			health_hunger_system.current_health,
			health_hunger_system.max_health
		)
		health_hunger_system.hunger_changed.emit(
			health_hunger_system.current_hunger,
			health_hunger_system.max_hunger
		)
		
		print("[Player] Health and hunger restored to full")
	
	# Teleport to spawn point
	global_position = spawn_position
	velocity = Vector3.ZERO
	
	# Reset death state
	is_dead = false
	
	# Re-capture mouse for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Restore essential UI visibility
	if health_ui:
		health_ui.visible = true
	if harvest_ui:
		harvest_ui.visible = true
	
	print("[Player] Respawned at spawn point: %s" % spawn_position)

func take_damage(amount: int) -> void:
	"""Called by enemies to damage player"""
	if is_dead:
		return  # Don't take damage while dead
	
	if health_hunger_system:
		health_hunger_system.take_damage(float(amount))
		print("[Player] Took %d damage (Health: %.1f)" % [
			amount,
			health_hunger_system.current_health
		])
		
		# Rumble feedback for taking damage
		if RumbleManager:
			RumbleManager.play("player_hit")
		
		# Camera shake on damage
		if combat_system:
			combat_system.shake_camera(0.6, 0.15)

func find_ground_position(start_pos: Vector3) -> Vector3:
	"""Find ground level below a given position using raycast"""
	var space_state = get_world_3d().direct_space_state
	
	# Raycast straight down from start position
	var query = PhysicsRayQueryParameters3D.create(
		start_pos,
		start_pos + Vector3(0, -100, 0)  # Cast 100m down
	)
	query.collision_mask = 1  # Only hit terrain (Layer 1)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Found ground - spawn slightly above it (player height)
		var ground_y = result.position.y
		return Vector3(start_pos.x, ground_y + 1.0, start_pos.z)
	else:
		# No ground found - use original position (fallback)
		print("[Player] WARNING: No ground found below spawn position!")
		return start_pos

func setup_spawn_position() -> void:
	"""Setup spawn position after player has landed on ground"""
	# Wait for player to fall and land on ground naturally
	# This is more reliable than raycasting before terrain loads
	while not is_on_floor():
		await get_tree().process_frame
	
	# Wait one more frame to ensure position is stable
	await get_tree().process_frame
	
	# Now store the ground position
	spawn_position = global_position
	print("[Player] Spawn position set to: %s (after landing on ground)" % spawn_position)

# =============================================================================
# WEATHER PARTICLE SYSTEM (Task 2.2-2.3)
# Particles are now created by weather_particles.tscn added to World scene
# =============================================================================

# These are kept for reference but particles are created elsewhere
var rain_particles: GPUParticles3D = null
var snow_particles: GPUParticles3D = null

func _create_weather_particles():
	# Particles are now created by weather_particles.tscn in the World scene
	# This function is kept for backwards compatibility but does nothing
	print("[Player] Weather particles handled by WeatherParticles scene")

