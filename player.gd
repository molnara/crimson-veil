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

var is_flying: bool = false  # Fly/noclip mode toggle

# Camera
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D = $SpringArm3D

# Systems
var harvesting_system: HarvestingSystem
var building_system: BuildingSystem
var crafting_system: CraftingSystem
var tool_system: ToolSystem
var inventory: Inventory
var health_hunger_system: HealthHungerSystem
var harvest_ui: Control
var crafting_ui: Control
var inventory_ui: Control
var health_ui: Control

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
	
	# Get health/hunger system from scene (created in player.tscn)
	health_hunger_system = $HealthHungerSystem if has_node("HealthHungerSystem") else null
	if not health_hunger_system:
		# Fallback: create one if it doesn't exist
		print("Warning: HealthHungerSystem not found in scene, creating new one")
		health_hunger_system = HealthHungerSystem.new()
		add_child(health_hunger_system)
	else:
		print("HealthHungerSystem found in scene!")
	
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
	
	# Toggle mouse capture (ESC/Start button)
	if event.is_action_pressed("ui_cancel"):
		# Close inventory if open
		if inventory_ui and inventory_ui.visible:
			inventory_ui.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			return
		
		# Close crafting menu if open
		if crafting_ui and crafting_ui.visible:
			crafting_ui.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			return
		
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Toggle inventory with I key or Y button (Xbox)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			if inventory_ui:
				inventory_ui.toggle_visibility()
			print("I key pressed - Toggle inventory")
	
	if event.is_action_pressed("toggle_inventory"):  # Y button on Xbox
		if inventory_ui:
			inventory_ui.toggle_visibility()
		print("Toggle inventory")
	
	# Toggle crafting menu with C key or X button (Xbox)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			if crafting_ui:
				crafting_ui.toggle_visibility()
			print("C key pressed - Toggle crafting")
	
	if event.is_action_pressed("toggle_crafting"):  # X button on Xbox
		if crafting_ui:
			crafting_ui.toggle_visibility()
		print("Toggle crafting")
	
	# Toggle fly mode with F key
	if event.is_action_pressed("toggle_fly"):
		is_flying = !is_flying
		print("Fly mode: ", "ON" if is_flying else "OFF")
	
	# Cycle tools with T key or D-pad Left/Right
	if event.is_action_pressed("cycle_tool"):
		if tool_system:
			tool_system.cycle_tool()
	
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
			# Cycle through block types
			var types = ["stone_block", "stone_wall", "stone_floor", "wood_plank"]
			var current_index = types.find(building_system.current_block_type)
			var next_index = (current_index + 1) % types.size()
			building_system.set_block_type(types[next_index])
	
	# Controller: RT (interact/harvest) and LT (cancel/remove)
	if event.is_action_pressed("controller_interact"):  # RT
		# Building mode takes priority
		if building_system and building_system.preview_mode:
			building_system.place_block()
		# Otherwise try harvesting
		elif harvesting_system and harvesting_system.is_looking_at_resource():
			harvesting_system.start_harvest()
	
	if event.is_action_pressed("controller_cancel"):  # LT
		if building_system and building_system.preview_mode:
			# Try to remove block at cursor
			var block_data = building_system.get_block_at_raycast()
			if block_data:
				building_system.remove_block_at_position(block_data["position"])
		elif harvesting_system and harvesting_system.is_harvesting:
			harvesting_system.cancel_harvest()
			print("Harvest manually cancelled")
	
	# Mouse button handling (keep existing)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Building mode takes priority
			if building_system and building_system.preview_mode:
				building_system.place_block()
			# Otherwise try harvesting
			elif harvesting_system and harvesting_system.is_looking_at_resource():
				harvesting_system.start_harvest()
		
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

func _on_harvest_completed(_resource: HarvestableResource, drops: Dictionary):
	"""Called when a resource is successfully harvested"""
	if inventory and drops.has("item") and drops.has("amount"):
		inventory.add_item(drops["item"], drops["amount"])

func apply_deadzone(value: float, deadzone: float) -> float:
	"""Apply deadzone to analog stick input"""
	if abs(value) < deadzone:
		return 0.0
	# Scale the remaining range to 0-1
	return (abs(value) - deadzone) / (1.0 - deadzone) * sign(value)

func _physics_process(delta):
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
	
	# Handle jump (Space or A button)
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("controller_jump")) and is_on_floor():
		velocity.y = jump_velocity
	
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
	
	# Debug: Print position when pressing P
	if Input.is_action_just_pressed("ui_text_completion_query"):
		print("Player Y: ", global_position.y)
		print("On floor: ", is_on_floor())
		print("Velocity: ", velocity)
	
	# Apply movement (Shift or B button for sprint)
	var is_sprinting = Input.is_action_pressed("ui_shift") or Input.is_action_pressed("controller_sprint")
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
