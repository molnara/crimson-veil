extends CharacterBody3D

# Movement settings
@export var move_speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# Camera
@onready var camera: Camera3D = $Camera3D
var camera_raycast: RayCast3D

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
	
	# Create a raycast for camera collision
	camera_raycast = RayCast3D.new()
	add_child(camera_raycast)
	camera_raycast.target_position = Vector3(0, 1.6, 0)  # Ray from feet to camera height
	camera_raycast.collision_mask = 1  # Collide with layer 1 (terrain)
	camera_raycast.enabled = true

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
	
	# Store previous position to detect if we got stuck
	var previous_pos = global_position
	
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
	
	# Adjust camera position to prevent clipping through terrain
	adjust_camera_for_terrain()

func adjust_camera_for_terrain():
	if not camera or not camera_raycast:
		return
	
	# Check if there's terrain between player feet and camera
	camera_raycast.force_raycast_update()
	
	if camera_raycast.is_colliding():
		# Terrain is blocking the camera position
		var collision_point = camera_raycast.get_collision_point()
		var local_collision = to_local(collision_point)
		# Move camera down to just above the collision point
		camera.position.y = max(0.5, local_collision.y - 0.2)
	else:
		# No obstruction, move camera back to normal height
		camera.position.y = lerp(camera.position.y, 1.6, 0.1)
