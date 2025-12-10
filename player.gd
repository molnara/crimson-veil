extends CharacterBody3D

# Movement settings
@export var move_speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var fly_speed: float = 15.0  # Speed when flying

var is_flying: bool = false  # Fly/noclip mode toggle

# Camera
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D = $SpringArm3D

# Systems
var harvesting_system: HarvestingSystem
var building_system: BuildingSystem
var inventory: Inventory
var harvest_ui: Control

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Set camera to proper human eye height
	# Human: 1.75m tall, eyes at ~1.65m (94% of height)
	if spring_arm:
		spring_arm.position.y = 1.65  # Realistic human eye height
		print("SpringArm position set to: ", spring_arm.position)
		print("SpringArm spring_length: ", spring_arm.spring_length)
	
	# Adjust camera near clip to prevent clipping into nearby objects
	if camera:
		camera.near = 0.05  # Reduced from default 0.1 to see objects closer
		print("Camera near clip set to: ", camera.near)
	
	# Capture the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("Player ready at position: ", global_position)
	print("Camera found: ", camera != null)
	if camera:
		print("Camera global position: ", camera.global_position)
	
	# Set collision layers - player only collides with terrain, not critters
	collision_layer = 1  # Player is on layer 1
	collision_mask = 1 + 2  # Detect layers 1 (terrain) and 2 (resources), but NOT layer 8 (critters)
	# Layer 8 (critters) is intentionally excluded so player passes through them
	
	# Enable floor snapping and sliding for smooth terrain following
	floor_constant_speed = true
	floor_block_on_wall = false
	floor_snap_length = 0.5  # Increased snap distance for varied terrain
	floor_max_angle = deg_to_rad(46)  # Allow steeper slopes (46 degrees)
	
	# Initialize inventory
	inventory = Inventory.new()
	add_child(inventory)
	
	# Initialize harvesting system
	harvesting_system = HarvestingSystem.new()
	add_child(harvesting_system)
	harvesting_system.initialize(self, camera, inventory)
	
	# Initialize building system
	building_system = BuildingSystem.new()
	add_child(building_system)
	building_system.initialize(self, camera, inventory)
	
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
	
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Toggle fly mode with F key
	if event.is_action_pressed("toggle_fly"):
		is_flying = !is_flying
		print("Fly mode: ", "ON" if is_flying else "OFF")
	
	# Toggle building mode with B key
	if event.is_action_pressed("toggle_building"):
		if building_system:
			if building_system.preview_mode:
				building_system.disable_building_mode()
			else:
				building_system.enable_building_mode("stone_block")
	
	# Cycle block type with Tab or C key when in building mode
	if building_system and building_system.preview_mode:
		if event.is_action_pressed("cycle_block_type"):
			# Cycle through block types
			var types = ["stone_block", "stone_wall", "stone_floor", "wood_plank"]
			var current_index = types.find(building_system.current_block_type)
			var next_index = (current_index + 1) % types.size()
			building_system.set_block_type(types[next_index])
	
	# Mouse button handling
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
	"""Setup the harvest UI"""
	print("Loading harvest UI...")
	var ui_scene = load("res://harvest_ui.tscn")
	if ui_scene:
		harvest_ui = ui_scene.instantiate()
		get_tree().root.add_child(harvest_ui)
		
		# Connect UI to systems
		if harvest_ui.has_method("set_inventory"):
			harvest_ui.set_inventory(inventory)
			print("Inventory connected to UI")
		
		if harvest_ui.has_method("get_progress_bar"):
			harvesting_system.progress_bar = harvest_ui.get_progress_bar()
			print("Progress bar connected")
		
		if harvest_ui.has_method("get_target_label"):
			harvesting_system.target_label = harvest_ui.get_target_label()
			print("Target label connected")
		
		print("Harvest UI loaded successfully")
	else:
		print("Warning: Could not load harvest_ui.tscn")

func _on_harvest_completed(_resource: HarvestableResource, drops: Dictionary):
	"""Called when a resource is successfully harvested"""
	if inventory and drops.has("item") and drops.has("amount"):
		inventory.add_item(drops["item"], drops["amount"])

func _physics_process(delta):
	# Fly mode - noclip movement
	if is_flying:
		# No gravity or collision in fly mode
		velocity = Vector3.ZERO
		
		# Get input direction (including up/down)
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		# Up/down movement
		if Input.is_action_pressed("ui_accept"):  # Space - fly up
			direction.y += 1.0
		if Input.is_action_pressed("ui_shift"):  # Shift - fly down
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
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	# Get input direction
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Debug: Print position when pressing P
	if Input.is_action_just_pressed("ui_text_completion_query"):
		print("Player Y: ", global_position.y)
		print("On floor: ", is_on_floor())
		print("Velocity: ", velocity)
	
	# Apply movement
	var current_speed = sprint_speed if Input.is_action_pressed("ui_shift") else move_speed
	
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
