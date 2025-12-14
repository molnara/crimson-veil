extends Enemy
class_name ForestGoblin

## Forest Goblin - Cowardly forest enemy with patrol and flee behavior
## Behavior: Patrols when idle, flees at <20% HP, keeps distance while poking with stick
## Stats: 50 HP, 12 DMG, 3.0 speed, 2.0m attack range

# Patrol behavior
var patrol_waypoints: Array[Vector3] = []
var current_waypoint_index: int = 0
var patrol_wait_timer: float = 0.0
const PATROL_WAIT_TIME: float = 2.0  # Wait 2s at each waypoint
const PATROL_RADIUS: float = 8.0  # Patrol within 8m of spawn
var spawn_position: Vector3

# Flee behavior
const FLEE_HEALTH_THRESHOLD: float = 0.2  # Flee at 20% HP (10 HP)
var is_fleeing: bool = false
const FLEE_SPEED_MULTIPLIER: float = 1.3  # 30% faster when fleeing

# Coward behavior (keep distance)
const PREFERRED_DISTANCE: float = 3.0  # Try to stay 3m away
const BACKPEDAL_SPEED_MULTIPLIER: float = 0.7  # Slower when backing up

# Ambient sound timer (performance optimization)
var ambient_sound_timer: float = 0.0
var next_ambient_delay: float = 0.0

func _ready() -> void:
	# Set goblin stats from balance table
	max_health = 50
	damage = 12
	move_speed = 3.0
	attack_range = 2.0
	detection_range = 10.0
	attack_cooldown_duration = 1.5
	attack_telegraph_duration = 0.4
	
	# Configure drop table
	drop_table = [
		{"item": "wood", "chance": 0.8},  # 80% chance
		{"item": "stone", "chance": 0.6},  # 60% chance
		{"item": "goblin_tooth", "chance": 0.3}  # 30% chance (rare)
	]
	
	# Call parent _ready to initialize
	super._ready()
	
	# Store spawn position for patrol
	spawn_position = global_position
	
	# Generate random patrol waypoints
	call_deferred("generate_patrol_waypoints")

func generate_patrol_waypoints() -> void:
	"""Generate 3-5 random patrol points around spawn"""
	var num_waypoints = randi_range(3, 5)
	
	for i in range(num_waypoints):
		var angle = (TAU / num_waypoints) * i + randf_range(-0.5, 0.5)
		var distance = randf_range(PATROL_RADIUS * 0.5, PATROL_RADIUS)
		var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		patrol_waypoints.append(spawn_position + offset)

func create_enemy_visual() -> void:
	"""Create CSG primitive goblin geometry"""
	# Create visual container
	var visual_root = Node3D.new()
	visual_root.name = "Visual"
	visual_root.rotation_degrees.y = 180  # Fix backward movement
	add_child(visual_root)
	
	# === BODY (Green capsule) ===
	var body = CSGCylinder3D.new()
	body.radius = 0.4
	body.height = 1.0
	body.sides = 8
	body.position = Vector3(0, 0.5, 0)
	body.name = "Body"
	visual_root.add_child(body)
	
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.8, 1.2, 0.8)  # Bright green base for texture visibility
	
	# Apply goblin skin texture
	var skin_texture = preload("res://textures/forest_goblin_skin.jpg")
	body_mat.albedo_texture = skin_texture
	body_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Pixel art style
	body_mat.roughness = 0.85  # Rough, leathery skin
	
	body.material = body_mat
	
	# === HEAD (Green sphere on top of body) ===
	var head = CSGSphere3D.new()
	head.radius = 0.35
	head.position = Vector3(0, 1.2, 0)
	head.name = "Head"
	visual_root.add_child(head)
	
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.8, 1.2, 0.8)  # Bright green base (match body)
	head_mat.albedo_texture = skin_texture  # Same skin texture
	head_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	head_mat.roughness = 0.85
	head_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED  # Force opaque
	head_mat.cull_mode = BaseMaterial3D.CULL_BACK  # Don't render inside of sphere
	head.material = head_mat
	
	# === EYES (2x CSGSphere, yellow, beady) ===
	var eye_left = CSGSphere3D.new()
	eye_left.radius = 0.08
	eye_left.position = Vector3(-0.15, 1.25, 0.3)
	eye_left.name = "EyeLeft"
	visual_root.add_child(eye_left)
	
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0, 1.0, 0.3)  # Yellow
	eye_mat.emission_enabled = true  # Make eyes glow slightly
	eye_mat.emission = Color(0.8, 0.8, 0.2)  # Dim yellow glow
	eye_mat.emission_energy_multiplier = 0.5  # Subtle glow
	eye_left.material = eye_mat
	
	var eye_right = CSGSphere3D.new()
	eye_right.radius = 0.08
	eye_right.position = Vector3(0.15, 1.25, 0.3)
	eye_right.name = "EyeRight"
	visual_root.add_child(eye_right)
	eye_right.material = eye_mat
	
	# === PUPILS (Tiny black spheres) ===
	var pupil_left = CSGSphere3D.new()
	pupil_left.radius = 0.02
	pupil_left.position = Vector3(-0.15, 1.25, 0.30)  # Same Z as eyes
	pupil_left.name = "PupilLeft"
	visual_root.add_child(pupil_left)
	
	var pupil_mat = StandardMaterial3D.new()
	pupil_mat.albedo_color = Color.BLACK
	pupil_left.material = pupil_mat
	
	var pupil_right = CSGSphere3D.new()
	pupil_right.radius = 0.02
	pupil_right.position = Vector3(0.15, 1.25, 0.30)  # Same Z as eyes
	pupil_right.name = "PupilRight"
	visual_root.add_child(pupil_right)
	pupil_right.material = pupil_mat
	
	# === ARMS (2x CSGBox, thin, brown) ===
	var arm_left = CSGBox3D.new()
	arm_left.size = Vector3(0.18, 0.7, 0.18)  # Thicker: was 0.12x0.6x0.12
	arm_left.position = Vector3(-0.5, 0.65, 0)  # Moved out slightly
	arm_left.rotation_degrees = Vector3(0, 0, 15)
	arm_left.name = "ArmLeft"
	visual_root.add_child(arm_left)
	
	var arm_mat = StandardMaterial3D.new()
	arm_mat.albedo_color = Color(0.4, 0.3, 0.2)  # Brown skin
	arm_left.material = arm_mat
	
	var arm_right = CSGBox3D.new()
	arm_right.size = Vector3(0.18, 0.7, 0.18)  # Thicker: was 0.12x0.6x0.12
	arm_right.position = Vector3(0.5, 0.65, 0)  # Moved out slightly
	arm_right.rotation_degrees = Vector3(0, 0, -15)
	arm_right.name = "ArmRight"
	visual_root.add_child(arm_right)
	arm_right.material = arm_mat
	
	# === STICK WEAPON (CSGBox held in right hand) ===
	var stick = CSGBox3D.new()
	stick.size = Vector3(0.08, 1.2, 0.08)
	stick.position = Vector3(0.45, 0.5, 0.3)
	stick.rotation_degrees = Vector3(45, 0, -15)
	stick.name = "Stick"
	visual_root.add_child(stick)
	
	var stick_mat = StandardMaterial3D.new()
	stick_mat.albedo_color = Color(0.3, 0.2, 0.1)  # Dark wood
	stick.material = stick_mat
	
	# === LEGS (2x CSGBox, short stubby legs) ===
	var leg_left = CSGBox3D.new()
	leg_left.size = Vector3(0.25, 0.6, 0.25)  # Wider and taller
	leg_left.position = Vector3(-0.25, 0.3, 0)  # Further out to the side, higher center
	leg_left.name = "LegLeft"
	visual_root.add_child(leg_left)
	leg_left.material = arm_mat
	
	var leg_right = CSGBox3D.new()
	leg_right.size = Vector3(0.25, 0.6, 0.25)  # Wider and taller
	leg_right.position = Vector3(0.25, 0.3, 0)  # Further out to the side, higher center
	leg_right.name = "LegRight"
	visual_root.add_child(leg_right)
	leg_right.material = arm_mat
	
	# Store original material for damage flash (use body CSG material)
	original_material = body_mat
	
	# Adjust collision shape for goblin size
	if collision_shape:
		var shape = CapsuleShape3D.new()
		shape.radius = 0.45
		shape.height = 1.5
		collision_shape.shape = shape
		collision_shape.position = Vector3(0, 0.75, 0)

func update_ai(delta: float) -> void:
	"""Override AI for patrol, flee, and coward behaviors"""
	if not player or current_state == State.DEATH:
		return
	
	# Ambient sounds (timer-based - every 6-10 seconds)
	ambient_sound_timer += delta
	if ambient_sound_timer >= next_ambient_delay:
		AudioManager.play_sound_3d("goblin_ambient", global_position, "sfx", false, false)
		ambient_sound_timer = 0.0
		next_ambient_delay = randf_range(6.0, 10.0)
	
	var distance = global_position.distance_to(player.global_position)
	
	# Check if should flee (health below 20%)
	var health_percent = float(current_health) / float(max_health)
	if health_percent <= FLEE_HEALTH_THRESHOLD and not is_fleeing:
		is_fleeing = true
		current_state = State.CHASE  # Use chase state but flee instead
	
	match current_state:
		State.IDLE:
			# Patrol behavior
			if patrol_waypoints.size() > 0:
				patrol(delta)
			
			# Detect player in range
			if distance < detection_range:
				current_state = State.CHASE
		
		State.CHASE:
			if is_fleeing:
				# Flee from player
				flee_from_player()
			else:
				# Check if in attack range
				if distance < attack_range:
					current_state = State.ATTACK
					velocity = Vector3.ZERO
				# Dead zone: stand still if at preferred distance (±0.5m)
				elif distance >= (PREFERRED_DISTANCE - 0.5) and distance <= (PREFERRED_DISTANCE + 0.5):
					velocity = Vector3.ZERO
					look_at_player()  # Still face player
				# Coward behavior: backpedal if too close
				elif distance < PREFERRED_DISTANCE:
					backpedal_from_player()
				else:
					# Normal chase but maintain preferred distance
					chase_player()
		
		State.ATTACK:
			if is_fleeing:
				# Stop attacking when fleeing
				current_state = State.CHASE
				return
			
			# Always face the player during attack
			look_at_player()
			
			# Return to chase if player escapes
			if distance > attack_range * 1.5:
				current_state = State.CHASE
			# Backpedal if player gets too close during attack
			elif distance < PREFERRED_DISTANCE * 0.5:
				current_state = State.CHASE
			else:
				# Attempt attack if not on cooldown
				if attack_cooldown <= 0 and not is_telegraphing:
					start_attack_telegraph()

func patrol(delta: float) -> void:
	"""Patrol between waypoints"""
	if patrol_waypoints.size() == 0:
		return
	
	var target_waypoint = patrol_waypoints[current_waypoint_index]
	var distance_to_waypoint = global_position.distance_to(target_waypoint)
	
	# Reached waypoint
	if distance_to_waypoint < 1.0:
		patrol_wait_timer += delta
		velocity = Vector3.ZERO
		
		# Wait at waypoint, then move to next
		if patrol_wait_timer >= PATROL_WAIT_TIME:
			patrol_wait_timer = 0.0
			current_waypoint_index = (current_waypoint_index + 1) % patrol_waypoints.size()
	else:
		# Move toward waypoint
		var direction = (target_waypoint - global_position).normalized()
		direction.y = 0
		
		velocity.x = direction.x * move_speed * 0.5  # Slower patrol speed
		velocity.z = direction.z * move_speed * 0.5
		
		# Face movement direction
		if direction.length() > 0.01:
			look_at(global_position + direction, Vector3.UP)

func flee_from_player() -> void:
	"""Run away from player at increased speed"""
	if not player:
		return
	
	# Run directly away from player
	var direction = (global_position - player.global_position).normalized()
	direction.y = 0
	
	var flee_speed = move_speed * FLEE_SPEED_MULTIPLIER
	velocity.x = direction.x * flee_speed
	velocity.z = direction.z * flee_speed
	
	# Face away from player
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func backpedal_from_player() -> void:
	"""Slowly back away while facing player (coward behavior)"""
	if not player:
		return
	
	# Move away from player
	var away_direction = (global_position - player.global_position).normalized()
	away_direction.y = 0
	
	var backpedal_speed = move_speed * BACKPEDAL_SPEED_MULTIPLIER
	velocity.x = away_direction.x * backpedal_speed
	velocity.z = away_direction.z * backpedal_speed
	
	# Face player while backing up
	var to_player = player.global_position - global_position
	to_player.y = 0
	if to_player.length() > 0.01:
		look_at(global_position + to_player, Vector3.UP)

func take_damage(amount: int) -> void:
	"""Override to trigger flee behavior at low health"""
	super.take_damage(amount)
	
	# Check if should start fleeing after taking damage
	var health_percent = float(current_health) / float(max_health)
	if health_percent <= FLEE_HEALTH_THRESHOLD and not is_fleeing:
		is_fleeing = true

func on_attack_telegraph() -> void:
	"""Visual feedback during attack telegraph"""
	AudioManager.play_sound_3d("goblin_attack", global_position, "sfx", false, false)
	pass

func on_hit() -> void:
	"""Play hit sound effect"""
	AudioManager.play_sound_3d("goblin_hit", global_position, "sfx", false, false)

func on_death() -> void:
	"""Play death sound effect"""
	AudioManager.play_sound_3d("goblin_death", global_position, "sfx", false, false)

func look_at_player() -> void:
	"""Face the player without moving"""
	if not player:
		return
	var to_player = player.global_position - global_position
	to_player.y = 0
	if to_player.length() > 0.01:
		var target_rotation = atan2(to_player.x, to_player.z)
		rotation.y = target_rotation + PI  # Add 180° to compensate for visual rotation

	pass
