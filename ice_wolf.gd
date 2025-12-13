extends Enemy
class_name IceWolf

## Ice Wolf - Pack hunting enemy
## Behavior: Spawns in packs, coordinates with howl signal, surrounds player
## Stats: 55 HP, 14 DMG, 4.5 speed, 2.0m attack range

# Pack behavior
@export var pack_id: int = -1  # ID of this wolf's pack (-1 = no pack)

const SURROUND_DISTANCE: float = 4.0  # Distance to maintain when surrounding
const SURROUND_ANGLE_VARIANCE: float = 30.0  # Degrees of variation

var has_howled: bool = false
var pack_members: Array = []  # Array of IceWolf instances
var surround_angle: float = 0.0  # This wolf's angle in the surround formation

func _ready() -> void:
	# Set wolf stats from balance table
	max_health = 55
	damage = 14
	move_speed = 4.5
	attack_range = 2.0
	detection_range = 12.0
	attack_cooldown_duration = 1.8
	attack_telegraph_duration = 0.4
	
	# Configure drop table
	drop_table = [
		{"item": "wolf_pelt", "chance": 1.0},  # 100% chance
		{"item": "fang", "chance": 0.7},  # 70% chance
		{"item": "ice_shard", "chance": 0.15}  # 15% rare drop
	]
	
	# Setup collision shape before calling super
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 0.6
		shape.height = 1.2
		collision_shape.shape = shape
		collision_shape.position = Vector3(0, 0.5, 0)
		add_child(collision_shape)
	
	# Call parent _ready to initialize
	super._ready()
	
	# Setup pack after ready (deferred to ensure all wolves are ready)
	call_deferred("form_pack")

func form_pack() -> void:
	"""Find other wolves with same pack_id and form pack"""
	if pack_id < 0:
		return
	
	pack_members.clear()
	
	# Find all wolves in the same pack
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if enemy is IceWolf and enemy != self:
			var other_wolf = enemy as IceWolf
			if other_wolf.pack_id == pack_id:
				pack_members.append(other_wolf)
	
	# Assign surround angles based on pack size
	var pack_size = pack_members.size() + 1  # +1 for self
	var angle_step = 360.0 / pack_size
	
	# Find this wolf's index in pack
	var my_index = 0
	for i in range(pack_members.size()):
		if pack_members[i].get_instance_id() < get_instance_id():
			my_index += 1
	
	surround_angle = my_index * angle_step

func update_ai(_delta: float) -> void:
	"""Override AI to add pack coordination"""
	if not player or current_state == State.DEATH:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	match current_state:
		State.IDLE:
			# Detect player in range
			if distance < detection_range:
				current_state = State.CHASE
				# First wolf to detect triggers pack howl
				if not has_howled and pack_members.size() > 0:
					perform_howl()
		
		State.CHASE:
			# Use pack surround behavior if in pack
			if pack_members.size() > 0:
				surround_player()
			else:
				# Solo wolf - normal chase
				chase_player()
			
			# Check if in attack range
			if distance < attack_range:
				current_state = State.ATTACK
				velocity = Vector3.ZERO
		
		State.ATTACK:
			# Return to chase if player escapes
			if distance > attack_range * 1.5:
				current_state = State.CHASE
			else:
				# Attempt attack if not on cooldown
				if attack_cooldown <= 0 and not is_telegraphing:
					start_attack_telegraph()

func perform_howl() -> void:
	"""Howl to signal pack - plays before first attack"""
	if has_howled:
		return
	
	has_howled = true
	
	# Stop movement during howl
	velocity = Vector3.ZERO
	
	# TODO: Play howl animation/sound
	# AudioManager.play_sound("wolf_howl", "combat")
	
	# Alert pack members
	for wolf in pack_members:
		if wolf and is_instance_valid(wolf):
			wolf.on_pack_howl()
	
	# Howl duration
	await get_tree().create_timer(1.0).timeout

func on_pack_howl() -> void:
	"""Called when another pack member howls"""
	if current_state == State.IDLE:
		current_state = State.CHASE

func surround_player() -> void:
	"""Move to surround position around player"""
	if not player:
		return
	
	# Calculate target position around player
	var angle_rad = deg_to_rad(surround_angle + randf_range(-SURROUND_ANGLE_VARIANCE, SURROUND_ANGLE_VARIANCE))
	var offset = Vector3(
		cos(angle_rad) * SURROUND_DISTANCE,
		0,
		sin(angle_rad) * SURROUND_DISTANCE
	)
	
	var target_position = player.global_position + offset
	var direction = (target_position - global_position).normalized()
	direction.y = 0
	
	# Move toward surround position
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	# Face the player, not the movement direction
	var look_direction = (player.global_position - global_position).normalized()
	if look_direction.length() > 0.01:
		look_at(global_position + look_direction, Vector3.UP)
	
	# Slowly rotate surround angle for dynamic movement
	surround_angle += 15.0 * get_physics_process_delta_time()
	if surround_angle >= 360.0:
		surround_angle -= 360.0

func on_attack_telegraph() -> void:
	"""Telegraph attack with aggressive stance"""
	# TODO: Play growl sound
	# AudioManager.play_sound("wolf_growl", "combat")
	pass

func on_attack_execute() -> void:
	"""Play bite attack sound"""
	# TODO: AudioManager.play_sound("wolf_bite", "combat")
	pass

func on_death() -> void:
	"""Remove self from pack and play death sound"""
	# Remove from pack
	for wolf in pack_members:
		if wolf and is_instance_valid(wolf):
			wolf.pack_members.erase(self)
	
	# TODO: AudioManager.play_sound("wolf_death", "combat")
	pass

func take_damage(amount: int) -> void:
	"""Override to alert pack when damaged"""
	super.take_damage(amount)
	
	# Alert pack members when damaged
	if current_state != State.DEATH:
		for wolf in pack_members:
			if wolf and is_instance_valid(wolf) and wolf.current_state == State.IDLE:
				wolf.current_state = State.CHASE

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
	"""Create CSG wolf appearance"""
	# Create visual container
	var visual_root = Node3D.new()
	visual_root.name = "Visual"
	add_child(visual_root)
	
	var ice_white = Color(0.95, 0.95, 1.0)  # White with slight blue tint
	var icy_blue = Color(0.4, 0.7, 1.0, 0.8)  # Glowing icy blue for eyes
	
	# === BODY (horizontal cylinder) ===
	var body = CSGCylinder3D.new()
	body.radius = 0.5
	body.height = 1.2
	body.rotation_degrees = Vector3(0, 0, 90)  # Horizontal
	body.position = Vector3(0, 0.6, 0)
	body.name = "Body"
	visual_root.add_child(body)
	
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = ice_white
	body.material = body_mat
	
	# === HEAD (sphere at front) ===
	var head = CSGSphere3D.new()
	head.radius = 0.4
	head.position = Vector3(0, 0.6, 0.8)
	head.name = "Head"
	visual_root.add_child(head)
	
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = ice_white
	head.material = head_mat
	
	# === LEGS (4x cylinders) ===
	var leg_positions = [
		Vector3(-0.3, 0.2, 0.4),   # Front left
		Vector3(0.3, 0.2, 0.4),    # Front right
		Vector3(-0.3, 0.2, -0.4),  # Back left
		Vector3(0.3, 0.2, -0.4)    # Back right
	]
	
	for i in range(4):
		var leg = CSGCylinder3D.new()
		leg.radius = 0.1
		leg.height = 0.6
		leg.position = leg_positions[i]
		leg.name = "Leg" + str(i)
		visual_root.add_child(leg)
		
		var leg_mat = StandardMaterial3D.new()
		leg_mat.albedo_color = ice_white.darkened(0.1)
		leg.material = leg_mat
	
	# === TAIL (bushy sphere, curved) ===
	var tail = CSGSphere3D.new()
	tail.radius = 0.25
	tail.position = Vector3(0, 0.7, -0.8)
	tail.name = "Tail"
	visual_root.add_child(tail)
	
	var tail_mat = StandardMaterial3D.new()
	tail_mat.albedo_color = ice_white
	tail.material = tail_mat
	
	# === EYES (2x glowing icy blue spheres) ===
	for i in range(2):
		var eye = CSGSphere3D.new()
		eye.radius = 0.1
		var side = -1.0 if i == 0 else 1.0
		eye.position = Vector3(side * 0.15, 0.65, 1.0)
		eye.name = "Eye" + ("Left" if i == 0 else "Right")
		visual_root.add_child(eye)
		
		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = icy_blue
		eye_mat.emission_enabled = true
		eye_mat.emission = icy_blue
		eye_mat.emission_energy_multiplier = 2.0
		eye.material = eye_mat
