extends CharacterBody3D

# Movement settings
@export var move_speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# Camera
@onready var camera: Camera3D = $Camera3D

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Capture the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("Player ready at position: ", global_position)
	print("Camera found: ", camera != null)

func _input(event):
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
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
	
	# Debug: print if we're getting input
	if input_dir.length() > 0:
		print("Input detected: ", input_dir, " On floor: ", is_on_floor())
	
	# Apply movement (work even if not on floor for better air control)
	var current_speed = sprint_speed if Input.is_action_pressed("ui_shift") else move_speed
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Slow down faster when on ground
		var deceleration = current_speed if is_on_floor() else current_speed * 0.3
		velocity.x = move_toward(velocity.x, 0, deceleration)
		velocity.z = move_toward(velocity.z, 0, deceleration)
	
	move_and_slide()
	
	# Debug floor detection
	if Input.is_action_just_pressed("ui_text_completion_query"):  # F key
		print("Position: ", global_position)
		print("Velocity: ", velocity)
		print("Is on floor: ", is_on_floor())
		print("Floor normal: ", get_floor_normal())
		print("Collision count: ", get_slide_collision_count())
