extends CharacterBody3D

# Movement settings
@export var move_speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# Camera
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D = $SpringArm3D

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Capture the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("Player ready at position: ", global_position)
	print("Camera found: ", camera != null)
	
	# Enable floor constant speed to help with slopes
	floor_constant_speed = true
	floor_block_on_wall = false
	floor_snap_length = 0.3

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

func _physics_process(delta):
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
