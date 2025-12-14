extends Enemy
class_name CorruptedRabbit

## Corrupted Rabbit - Fast, territorial forest enemy
## Behavior: Only attacks if player within 5m, zigzag chase pattern, quick strikes
## Stats: 30 HP, 8 DMG, 4.5 speed, 1.5m attack range

# Territorial behavior
const TERRITORIAL_RANGE: float = 5.0  # Only aggro within 5m
var is_territorial_aggro: bool = false

# Zigzag chase pattern
var zigzag_timer: float = 0.0
const ZIGZAG_INTERVAL: float = 0.4  # Change direction every 0.4s
var zigzag_direction: int = 1  # 1 = right, -1 = left

# Ambient sound timer (performance optimization)
var ambient_sound_timer: float = 0.0
var next_ambient_delay: float = 0.0

func _ready() -> void:
	# Set rabbit stats from balance table
	max_health = 30
	damage = 8
	move_speed = 4.5
	attack_range = 1.5
	detection_range = TERRITORIAL_RANGE  # Territorial detection
	attack_cooldown_duration = 1.0
	attack_telegraph_duration = 0.3  # Quick telegraph
	
	# Configure drop table
	drop_table = [
		{"item": "corrupted_leather", "chance": 1.0},  # 100% chance
		{"item": "dark_meat", "chance": 0.4}  # 40% chance
	]
	
	# Call parent _ready to initialize
	super._ready()

func create_enemy_visual() -> void:
	"""Create CSG primitive rabbit geometry"""
	# Create visual container
	var visual_root = Node3D.new()
	visual_root.name = "Visual"
	visual_root.rotation_degrees.y = 180  # Fix backward movement
	add_child(visual_root)
	
	# === BODY (Brown sphere) ===
	var body = CSGSphere3D.new()
	body.radius = 0.3
	body.position = Vector3(0, 0.4, 0)  # Raised to match collision shape center
	body.name = "Body"
	visual_root.add_child(body)
	
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(1.2, 1.0, 0.9)  # Bright base for texture visibility
	
	# Apply corrupted fur texture
	var fur_texture = preload("res://textures/corrupted_rabbit_fur.jpg")
	body_mat.albedo_texture = fur_texture
	body_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Pixel art style
	body_mat.roughness = 0.9  # Matted, no shine
	
	print("[CorruptedRabbit] ✅ Texture loaded: corrupted_rabbit_fur.jpg")
	
	body.material = body_mat
	
	# === HEAD (Smaller sphere, offset forward) ===
	var head = CSGSphere3D.new()
	head.radius = 0.2
	head.position = Vector3(0, 0.5, 0.25)  # Raised 0.4m (was 0.1, now 0.5)
	head.name = "Head"
	visual_root.add_child(head)
	
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(1.2, 1.0, 0.9)  # Bright base for texture visibility
	head_mat.albedo_texture = fur_texture  # Same fur texture
	head_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	head_mat.roughness = 0.9
	head.material = head_mat
	
	# === EARS (2x CSGBox, pointed up, pink inside) ===
	var ear_left = CSGBox3D.new()
	ear_left.size = Vector3(0.08, 0.25, 0.05)
	ear_left.position = Vector3(-0.12, 0.75, 0.25)  # Raised 0.4m (was 0.35, now 0.75)
	ear_left.rotation_degrees = Vector3(0, 0, -15)
	ear_left.name = "EarLeft"
	visual_root.add_child(ear_left)
	
	var ear_left_mat = StandardMaterial3D.new()
	ear_left_mat.albedo_color = Color(0.8, 0.4, 0.5)  # Pink inside
	ear_left.material = ear_left_mat
	
	var ear_right = CSGBox3D.new()
	ear_right.size = Vector3(0.08, 0.25, 0.05)
	ear_right.position = Vector3(0.12, 0.75, 0.25)  # Raised 0.4m (was 0.35, now 0.75)
	ear_right.rotation_degrees = Vector3(0, 0, 15)
	ear_right.name = "EarRight"
	visual_root.add_child(ear_right)
	
	var ear_right_mat = StandardMaterial3D.new()
	ear_right_mat.albedo_color = Color(0.8, 0.4, 0.5)  # Pink inside
	ear_right.material = ear_right_mat
	
	# === EYES (2x CSGSphere, glowing red, emissive) ===
	var eye_left = CSGSphere3D.new()
	eye_left.radius = 0.05
	eye_left.position = Vector3(-0.08, 0.55, 0.38)  # Raised 0.4m
	eye_left.name = "EyeLeft"
	visual_root.add_child(eye_left)
	
	var eye_left_mat = StandardMaterial3D.new()
	eye_left_mat.albedo_color = Color(1.0, 0.0, 0.0)  # Bright red
	eye_left_mat.emission_enabled = true
	eye_left_mat.emission = Color(1.0, 0.0, 0.0)
	eye_left_mat.emission_energy_multiplier = 2.0
	eye_left.material = eye_left_mat
	
	var eye_right = CSGSphere3D.new()
	eye_right.radius = 0.05
	eye_right.position = Vector3(0.08, 0.55, 0.38)  # Raised 0.4m
	eye_right.name = "EyeRight"
	visual_root.add_child(eye_right)
	
	var eye_right_mat = StandardMaterial3D.new()
	eye_right_mat.albedo_color = Color(1.0, 0.0, 0.0)  # Bright red
	eye_right_mat.emission_enabled = true
	eye_right_mat.emission = Color(1.0, 0.0, 0.0)
	eye_right_mat.emission_energy_multiplier = 2.0
	eye_right.material = eye_right_mat
	
	# === TAIL (Small fluffy sphere at back) ===
	var tail = CSGSphere3D.new()
	tail.radius = 0.12
	tail.position = Vector3(0, 0.45, -0.35)  # Raised 0.4m
	tail.name = "Tail"
	visual_root.add_child(tail)
	
	var tail_mat = StandardMaterial3D.new()
	tail_mat.albedo_color = Color(1.2, 1.0, 0.9)  # Bright base for texture visibility
	tail_mat.albedo_texture = fur_texture  # Same fur texture
	tail_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	tail_mat.roughness = 0.9
	tail.material = tail_mat
	
	# Store body as visual_mesh for damage flash system
	visual_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.6
	visual_mesh.mesh = mesh
	visual_mesh.set_surface_override_material(0, body_mat)
	visual_mesh.visible = false  # Hidden, CSG is visible
	add_child(visual_mesh)
	
	original_material = body_mat
	
	# Adjust collision shape for rabbit size
	if collision_shape:
		var shape = CapsuleShape3D.new()
		shape.radius = 0.35  # Slightly larger than body
		shape.height = 0.6
		collision_shape.shape = shape

func update_ai(delta: float) -> void:
	"""Override AI for territorial behavior and zigzag chase"""
	if not player or current_state == State.DEATH:
		return
	
	# Ambient sounds (timer-based - every 4-7 seconds, not every frame!)
	ambient_sound_timer += delta
	if ambient_sound_timer >= next_ambient_delay:
		AudioManager.play_sound_3d("rabbit_ambient", global_position, "sfx", false, false)
		ambient_sound_timer = 0.0
		next_ambient_delay = randf_range(4.0, 7.0)  # Random interval
	
	var distance = global_position.distance_to(player.global_position)
	
	match current_state:
		State.IDLE:
			# Territorial: Only aggro if player within 5m
			if distance < TERRITORIAL_RANGE:
				current_state = State.CHASE
				is_territorial_aggro = true
		
		State.CHASE:
			# Check if in attack range
			if distance < attack_range:
				current_state = State.ATTACK
				velocity = Vector3.ZERO
			# Lose aggro if player escapes territorial range
			elif distance > TERRITORIAL_RANGE * 1.5:
				current_state = State.IDLE
				is_territorial_aggro = false
				velocity = Vector3.ZERO  # STOP MOVING when losing aggro
			else:
				# Zigzag chase pattern
				chase_zigzag(delta)
		
		State.ATTACK:
			# Return to chase if player escapes
			if distance > attack_range * 1.5:
				current_state = State.CHASE
			else:
				# Attempt attack if not on cooldown
				if attack_cooldown <= 0 and not is_telegraphing:
					start_attack_telegraph()

func chase_zigzag(delta: float) -> void:
	"""Fast zigzag chase pattern toward player"""
	if not player:
		return
	
	# Update zigzag timer
	zigzag_timer += delta
	if zigzag_timer >= ZIGZAG_INTERVAL:
		zigzag_timer = 0.0
		zigzag_direction *= -1  # Flip direction
	
	# Get direction to player
	var to_player = (player.global_position - global_position).normalized()
	to_player.y = 0
	
	# Calculate perpendicular vector for zigzag
	var perpendicular = Vector3(-to_player.z, 0, to_player.x)
	
	# Combine forward movement with zigzag
	var chase_direction = (to_player + perpendicular * zigzag_direction * 0.3).normalized()
	
	velocity.x = chase_direction.x * move_speed
	velocity.z = chase_direction.z * move_speed
	
	# Face movement direction
	if chase_direction.length() > 0.01:
		look_at(global_position + chase_direction, Vector3.UP)

func on_attack_telegraph() -> void:
	"""Visual feedback during attack telegraph"""
	AudioManager.play_sound_3d("rabbit_attack", global_position, "sfx", false, false)
	pass

func on_death() -> void:
	"""Play death sound effect"""
	AudioManager.play_sound_3d("rabbit_death", global_position, "sfx", false, false)
	pass
