extends Enemy
class_name StoneGolem

## Stone Golem - Tank enemy with ground slam AoE attack
## Behavior: Slow movement, high HP, patrols stone nodes, ground slam with telegraph
## Stats: 100 HP, 20 DMG, 1.5 speed, 2.5m attack range

# Ambient sound timer (performance optimization)
var ambient_sound_timer: float = 0.0
var next_ambient_delay: float = 0.0

# Ground slam attack
const SLAM_TELEGRAPH_DURATION: float = 1.0
const SLAM_AOE_RADIUS: float = 3.0
const SLAM_STAGGER_DURATION: float = 2.0
var is_slamming: bool = false
var slam_telegraph_timer: float = 0.0
var stagger_timer: float = 0.0

# Stone node patrol
const STONE_NODE_SEARCH_RADIUS: float = 10.0
var patrol_target: Vector3 = Vector3.ZERO
var has_patrol_target: bool = false
var patrol_timer: float = 0.0
const PATROL_CHANGE_INTERVAL: float = 5.0

func _ready() -> void:
	# Set golem stats from balance table
	max_health = 100
	damage = 20
	move_speed = 1.5
	attack_range = 2.5
	detection_range = 10.0
	attack_cooldown_duration = 2.0  # Slower attacks (tank)
	attack_telegraph_duration = SLAM_TELEGRAPH_DURATION
	
	# Configure drop table
	drop_table = [
		{"item": "stone", "chance": 1.0, "amount_min": 3, "amount_max": 5},  # 100% chance, 3-5 pieces
		{"item": "iron_ore", "chance": 0.6},  # 60% chance
		{"item": "stone_core", "chance": 0.2}  # 20% rare drop
	]
	
	# Setup collision shape before calling super
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 0.8  # Large tank hitbox
		shape.height = 1.8
		collision_shape.shape = shape
		collision_shape.position = Vector3(0, 0.9, 0)
		add_child(collision_shape)
	
	# Call parent _ready to initialize
	super._ready()
	
	# Find nearby stone nodes for patrol
	call_deferred("find_patrol_points")

func find_patrol_points() -> void:
	"""Find stone resource nodes to patrol around"""
	# Check for stone nodes in radius (would be in "resources" group in full implementation)
	var resources = get_tree().get_nodes_in_group("resources")
	var nearby_stones: Array = []
	
	for resource in resources:
		if resource.global_position.distance_to(global_position) < STONE_NODE_SEARCH_RADIUS:
			# Check if it's a stone-type resource (in full implementation)
			nearby_stones.append(resource.global_position)
	
	# If stone nodes found, patrol around them
	if nearby_stones.size() > 0:
		has_patrol_target = true
		patrol_target = nearby_stones[randi() % nearby_stones.size()]

func update_ai(delta: float) -> void:
	"""Override AI to add ground slam and patrol behavior"""
	if not player or current_state == State.DEATH:
		return
	
	# Ambient sounds (timer-based - every 8-15 seconds)
	ambient_sound_timer += delta
	if ambient_sound_timer >= next_ambient_delay:
		AudioManager.play_sound_3d("golem_ambient", global_position, "sfx", false, false)
		ambient_sound_timer = 0.0
		next_ambient_delay = randf_range(8.0, 15.0)
	
	# Handle stagger state after ground slam
	if stagger_timer > 0:
		stagger_timer -= delta
		velocity = Vector3.ZERO
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	match current_state:
		State.IDLE:
			# Patrol around stone nodes if available
			if has_patrol_target:
				patrol_stone_nodes(delta)
			
			# Detect player in range
			if distance < detection_range:
				current_state = State.CHASE
		
		State.CHASE:
			# Check if in attack range
			if distance < attack_range:
				current_state = State.ATTACK
				velocity = Vector3.ZERO
			else:
				# Slow, deliberate chase
				chase_player()
		
		State.ATTACK:
			# Return to chase if player escapes
			if distance > attack_range * 1.5:
				current_state = State.CHASE
			else:
				# Attempt ground slam if not on cooldown
				if attack_cooldown <= 0 and not is_telegraphing and not is_slamming:
					start_ground_slam()

func patrol_stone_nodes(delta: float) -> void:
	"""Patrol around stone resource nodes"""
	if not has_patrol_target:
		return
	
	patrol_timer += delta
	
	# Change patrol target periodically
	if patrol_timer >= PATROL_CHANGE_INTERVAL:
		patrol_timer = 0.0
		# Pick new random point around stone node
		var random_offset = Vector3(
			randf_range(-5.0, 5.0),
			0,
			randf_range(-5.0, 5.0)
		)
		patrol_target = patrol_target + random_offset
	
	# Move toward patrol target
	var direction = (patrol_target - global_position).normalized()
	direction.y = 0
	
	if direction.length() > 0.1:
		velocity.x = direction.x * move_speed * 0.5  # Slow patrol
		velocity.z = direction.z * move_speed * 0.5
		
		# Face movement direction
		if direction.length() > 0.01:
			look_at(global_position + direction, Vector3.UP)

func start_ground_slam() -> void:
	"""Begin ground slam attack with telegraph"""
	is_slamming = true
	slam_telegraph_timer = 0.0
	start_attack_telegraph()

func on_attack_telegraph() -> void:
	"""Visual telegraph for ground slam - raise arms"""
	# Rotate arms upward during telegraph
	var visual = get_node_or_null("Visual")
	if visual:
		var arm_left = visual.get_node_or_null("ArmLeft")
		var arm_right = visual.get_node_or_null("ArmRight")
		
		if arm_left:
			arm_left.rotation_degrees.x = -45  # Raise left arm
		if arm_right:
			arm_right.rotation_degrees.x = -45  # Raise right arm
	
	# Play attack telegraph sound
	AudioManager.play_sound_3d("golem_attack", global_position, "sfx", false, false)

func on_hit() -> void:
	"""Play hit sound effect"""
	AudioManager.play_sound_3d("golem_hit", global_position, "sfx", false, false)

func on_attack_execute() -> void:
	"""Execute ground slam - deal AoE damage"""
	is_slamming = false
	
	# Lower arms back to normal
	var visual = get_node_or_null("Visual")
	if visual:
		var arm_left = visual.get_node_or_null("ArmLeft")
		var arm_right = visual.get_node_or_null("ArmRight")
		
		if arm_left:
			arm_left.rotation_degrees.x = 0
		if arm_right:
			arm_right.rotation_degrees.x = 0
	
	# Deal AoE damage to player if in range
	if player and player.global_position.distance_to(global_position) < SLAM_AOE_RADIUS:
		if player.has_method("take_damage"):
			player.take_damage(damage)
	
	# Enter stagger state
	stagger_timer = SLAM_STAGGER_DURATION
	
	# TODO (Task 3.1): Play ground slam impact sound
	# AudioManager.play_sound("golem_slam_impact", "enemy", false, false)
	
	# TODO (Task 3.2): Create ground slam particle effect
	# var particles = preload("res://effects/ground_slam.tscn").instantiate()
	# get_parent().add_child(particles)
	# particles.global_position = global_position

func on_death() -> void:
	"""Play death sound effect"""
	AudioManager.play_sound_3d("golem_death", global_position, "sfx", false, false)
	pass

func flash_white() -> void:
	"""Override damage flash for Visual node structure"""
	var visual = get_node_or_null("Visual")
	if not visual:
		return
	
	var body = visual.get_node_or_null("Body")
	if not body:
		return
	
	# Flash body white
	var mat = body.material as StandardMaterial3D
	if mat:
		var original_color = mat.albedo_color
		mat.albedo_color = Color.WHITE
		
		# Restore after 0.1s
		await get_tree().create_timer(0.1).timeout
		if mat:
			mat.albedo_color = original_color

func create_enemy_visual() -> void:
	"""Create CSG stone golem appearance"""
	# Create visual container
	var visual_root = Node3D.new()
	visual_root.name = "Visual"
	visual_root.rotation_degrees.y = 180  # Fix backward movement
	add_child(visual_root)
	
	var stone_gray = Color(0.5, 0.5, 0.5)  # Gray stone
	var stone_dark = Color(0.3, 0.3, 0.3)  # Darker stone for details
	var orange_glow = Color(1.0, 0.5, 0.0)  # Orange glowing eyes
	
	# === BODY (large box, 1.5m tall) ===
	var body = CSGBox3D.new()
	body.size = Vector3(1.2, 1.5, 0.8)
	body.position = Vector3(0, 0.75, 0)
	body.name = "Body"
	visual_root.add_child(body)
	
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = stone_gray
	body_mat.roughness = 0.8  # Rough stone (was 1.0)
	
	# Apply stone golem surface texture
	var stone_texture = preload("res://textures/stone_golem_surface.jpg")
	body_mat.albedo_texture = stone_texture
	body_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	# Enhance glowing cracks with emission
	body_mat.emission_enabled = true
	body_mat.emission = Color(1.0, 0.4, 0.0)  # Orange glow for magma cracks
	body_mat.emission_energy_multiplier = 0.8
	
	body.material = body_mat
	
	# === HEAD (smaller box on top) ===
	var head = CSGBox3D.new()
	head.size = Vector3(0.8, 0.6, 0.6)
	head.position = Vector3(0, 1.8, 0)
	head.name = "Head"
	visual_root.add_child(head)
	
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = stone_gray
	head_mat.roughness = 0.8
	head_mat.albedo_texture = stone_texture
	head_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	head_mat.emission_enabled = true
	head_mat.emission = Color(1.0, 0.4, 0.0)
	head_mat.emission_energy_multiplier = 0.8
	head.material = head_mat
	
	# === ARMS (2x thick boxes) ===
	var arm_left = CSGBox3D.new()
	arm_left.size = Vector3(0.3, 1.0, 0.3)
	arm_left.position = Vector3(-0.75, 0.9, 0)
	arm_left.name = "ArmLeft"
	visual_root.add_child(arm_left)
	
	var arm_left_mat = StandardMaterial3D.new()
	arm_left_mat.albedo_color = stone_dark
	arm_left_mat.roughness = 1.0
	arm_left.material = arm_left_mat
	
	var arm_right = CSGBox3D.new()
	arm_right.size = Vector3(0.3, 1.0, 0.3)
	arm_right.position = Vector3(0.75, 0.9, 0)
	arm_right.name = "ArmRight"
	visual_root.add_child(arm_right)
	
	var arm_right_mat = StandardMaterial3D.new()
	arm_right_mat.albedo_color = stone_dark
	arm_right_mat.roughness = 1.0
	arm_right.material = arm_right_mat
	
	# === LEGS (2x sturdy columns) ===
	var leg_left = CSGBox3D.new()
	leg_left.size = Vector3(0.4, 0.8, 0.4)
	leg_left.position = Vector3(-0.4, 0.0, 0)
	leg_left.name = "LegLeft"
	visual_root.add_child(leg_left)
	
	var leg_left_mat = StandardMaterial3D.new()
	leg_left_mat.albedo_color = stone_dark
	leg_left_mat.roughness = 1.0
	leg_left.material = leg_left_mat
	
	var leg_right = CSGBox3D.new()
	leg_right.size = Vector3(0.4, 0.8, 0.4)
	leg_right.position = Vector3(0.4, 0.0, 0)
	leg_right.name = "LegRight"
	visual_root.add_child(leg_right)
	
	var leg_right_mat = StandardMaterial3D.new()
	leg_right_mat.albedo_color = stone_dark
	leg_right_mat.roughness = 1.0
	leg_right.material = leg_right_mat
	
	# === EYES (2x glowing orange spheres) ===
	for i in range(2):
		var eye = CSGSphere3D.new()
		eye.radius = 0.12
		var side = -1.0 if i == 0 else 1.0
		eye.position = Vector3(side * 0.25, 1.85, 0.35)
		eye.name = "Eye" + ("Left" if i == 0 else "Right")
		visual_root.add_child(eye)
		
		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = orange_glow
		eye_mat.emission_enabled = true
		eye_mat.emission = orange_glow
		eye_mat.emission_energy_multiplier = 2.0
		eye.material = eye_mat
	
	# Optional: Add crack detail lines (darker material on body)
	var crack1 = CSGBox3D.new()
	crack1.size = Vector3(0.05, 1.2, 0.05)
	crack1.position = Vector3(0.2, 0.75, 0.41)
	crack1.name = "Crack1"
	visual_root.add_child(crack1)
	
	var crack_mat = StandardMaterial3D.new()
	crack_mat.albedo_color = Color(0.1, 0.1, 0.1)  # Very dark cracks
	crack_mat.roughness = 1.0
	crack1.material = crack_mat
	
	var crack2 = CSGBox3D.new()
	crack2.size = Vector3(0.05, 0.8, 0.05)
	crack2.position = Vector3(-0.3, 0.75, 0.41)
	crack2.rotation_degrees = Vector3(0, 0, 20)
	crack2.name = "Crack2"
	visual_root.add_child(crack2)
	crack2.material = crack_mat
