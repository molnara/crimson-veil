extends HarvestableResource
class_name HarvestableTree

"""
HarvestableTree - Harvestable trees with realistic falling physics and log spawning

TREE LIFECYCLE (State Machine):
1. STANDING (StaticBody3D)
   - Spawned by VegetationSpawner
   - Player raycasts detect on layer 2
   - Shakes when harvested (apply_hit_shake)

2. FALLING (RigidBody3D)
   - Triggered by complete_harvest() override
   - Converts from StaticBody3D to RigidBody3D for physics
   - Falls away from player (calculated in start_harvest)
   - Spawns wood particles at base
   - Creates stump (StaticBody3D remains at base)

3. IMPACT (Ground collision detected)
   - Detects ground via collision signal
   - Spawns impact particles and crack sound effect
   - Breaks trunk into 3-5 log segments at impact point

4. LOG PIECES (Multiple RigidBody3D)
   - Logs scatter with realistic physics based on impact angle
   - Each log is harvestable (instant pickup when approached)
   - Logs despawn after 45-60 seconds with particles

PERFORMANCE NOTES:
- Physics body created only when falling (not pre-allocated)
- Collision shape is capsule covering trunk only (not foliage)
- Logs use simple cylinder collision for performance

INTEGRATION:
- Spawned by VegetationSpawner.create_tree()
- Uses PixelTextureGenerator for bark textures (oak, pine, palm variants)
"""

# Tree-specific properties
enum TreeType {
	NORMAL,    # Regular deciduous tree - oak bark, layered disc foliage
	PINE,      # Coniferous/evergreen - pine bark, cone-shaped foliage
	PALM       # Tropical palm tree - palm bark with rings, frond leaves
}

@export var tree_type: TreeType = TreeType.NORMAL
@export var tree_height: float = 6.0  # Total height of tree

# Physics-based falling state
var is_falling: bool = false
var fall_direction: Vector3 = Vector3.ZERO  # Calculated from player position in start_harvest
var fall_timer: float = 0.0  # Total time since falling started
var has_hit_ground: bool = false  # Detected via collision signal
var ground_impact_position: Vector3 = Vector3.ZERO  # Where the tree hit the ground
var ground_impact_normal: Vector3 = Vector3.UP  # Surface normal at impact

# Physics components (created dynamically when falling starts, not pre-allocated)
var physics_body: RigidBody3D = null
var physics_collision: CollisionShape3D = null

# Visual components
var tree_meshes: Array = []  # All MeshInstance3D children (cached for effects)

# Trunk dimensions (extracted from collision shape)
var trunk_height: float = 5.0
var trunk_radius: float = 0.3

func _ready():
	# Set properties based on tree type FIRST
	match tree_type:
		TreeType.NORMAL:
			resource_name = "Tree"
			resource_type = "wood"
			max_health = 100.0
			harvest_time = 0.5  # Time per swing
			drop_item = "wood"
			drop_amount_min = 8
			drop_amount_max = 15
			mining_tool_required = "axe"
			
		TreeType.PINE:
			resource_name = "Pine Tree"
			resource_type = "wood"
			max_health = 120.0
			harvest_time = 0.5
			drop_item = "wood"
			drop_amount_min = 10
			drop_amount_max = 18
			mining_tool_required = "axe"
			
		TreeType.PALM:
			resource_name = "Palm Tree"
			resource_type = "wood"
			max_health = 80.0
			harvest_time = 0.5
			drop_item = "wood"
			drop_amount_min = 5
			drop_amount_max = 10
			mining_tool_required = "axe"
	
	# NOW call parent _ready which will use these properties
	super._ready()
	
	# Trees don't glow at night
	enable_nighttime_glow = false
	
	# Cache tree meshes for visual effects
	cache_tree_meshes()
	
	# Extract trunk dimensions from collision shape (if exists)
	extract_trunk_dimensions()

func cache_tree_meshes():
	"""Cache all mesh instances for efficient access during effects"""
	for child in get_children():
		if child is MeshInstance3D:
			tree_meshes.append(child)

func extract_trunk_dimensions():
	"""Extract trunk height and radius from collision shape for physics calculations"""
	# Look for the trunk collision shape (should be first child CollisionShape3D)
	for child in get_children():
		if child is CollisionShape3D:
			var shape = child.shape
			if shape is CapsuleShape3D:
				trunk_height = shape.height
				trunk_radius = shape.radius
				return
			elif shape is CylinderShape3D:
				trunk_height = shape.height
				trunk_radius = shape.radius
				return

func start_harvest(player: Node3D) -> bool:
	"""Override to calculate fall direction away from player"""
	# Store the direction away from player (for later falling)
	if player:
		var to_player = (player.global_position - global_position).normalized()
		fall_direction = -to_player  # Opposite of player direction
		fall_direction.y = 0  # Keep horizontal
		fall_direction = fall_direction.normalized()
	
	return super.start_harvest(player)

func apply_hit_shake():
	"""Apply a shake effect when the tree is hit (called during harvesting)"""
	if not is_being_harvested:
		return
	
	# Calculate shake based on harvest progress (more violent as tree gets weaker)
	var shake_amount = 0.05 + (harvest_progress * 0.15)  # 0.05 to 0.2 radians
	var shake_speed = 15.0 + (harvest_progress * 10.0)  # Speed up as progress increases
	
	var time = Time.get_ticks_msec() / 1000.0
	rotation.z = original_rotation.z + sin(time * shake_speed) * shake_amount * (1.0 - harvest_progress)
	rotation.x = original_rotation.x + cos(time * shake_speed * 0.7) * shake_amount * 0.5 * (1.0 - harvest_progress)

func apply_harvest_visual_feedback():
	"""Override to do shake instead of pulse"""
	# Shake is handled in apply_hit_shake
	pass

func complete_harvest():
	"""Override to trigger falling animation instead of immediate destruction
	
	STATE TRANSITION: Standing (StaticBody3D) -> Falling (RigidBody3D)
	
	Unlike base HarvestableResource which queue_free() immediately:
	1. Emit drops signal (inventory system adds items)
	2. Start falling animation via start_falling()
	3. Tree converts to physics body and falls realistically
	4. On ground impact -> breaks into log pieces
	5. Logs are harvestable and despawn after delay
	"""
	if not is_being_harvested:
		return
	
	print("[HarvestableTree] complete_harvest() called for: ", resource_name)
	
	# Calculate drops (same as parent, but don't queue_free yet)
	var drop_count = randi_range(drop_amount_min, drop_amount_max)
	var drops = {
		"item": drop_item,
		"amount": drop_count
	}
	
	print("[HarvestableTree] Harvested ", resource_name, " - Got ", drop_count, "x ", drop_item)
	
	# Add directly to player's inventory
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var inv = player.get("inventory")
		if inv != null and inv.has_method("add_item"):
			inv.add_item(drop_item, drop_count)
			print("[HarvestableTree] ✓ Added to inventory: ", drop_count, "x ", drop_item)
			
			# Play pickup sound and rumble
			AudioManager.play_sound("item_pickup", "ui", true, false)
			RumbleManager.play_item_pickup()
		else:
			print("[HarvestableTree] ✗ ERROR: Could not access player.inventory")
	else:
		print("[HarvestableTree] ✗ ERROR: Could not find player!")
	
	emit_signal("harvested", drops)
	
	# AUDIO: Play resource break sound (tree is fully chopped)
	AudioManager.play_sound("resource_break", "sfx")
	
	# Reset harvest state
	is_being_harvested = false
	harvester = null
	harvest_progress = 0.0
	
	# Start falling animation instead of immediate destruction
	start_falling()

func start_falling():
	"""Begin the physics-based tree falling
	
	CONVERSION PROCESS:
	1. Spawn wood particles at base
	2. Convert tree to RigidBody3D via convert_to_physics_body()
	3. Apply gentle torque in fall_direction (away from player)
	"""
	is_falling = true
	has_hit_ground = false
	
	# Spawn wood particles at the base
	spawn_break_particles()
	
	# Convert to physics body for realistic falling
	convert_to_physics_body()

func spawn_log_pieces():
	"""Break the tree into log pieces that scatter
	
	IMPACT-BASED SHATTERING:
	
	PROCESS:
	1. Calculate number of logs based on tree size (3-5 for normal trees)
	2. Spawn log cylinders along the trunk at impact position
	3. Each log gets realistic physics based on impact angle
	4. Logs scatter in cone pattern away from impact
	5. Each log is harvestable (gives 2-3 wood on pickup)
	6. Logs despawn after 45-60 seconds if not harvested
	
	PHYSICS DETAILS:
	- Logs inherit velocity from falling tree at impact
	- Scatter direction based on impact normal
	- Small bounce and roll for realism
	- Higher damping than tree for quicker settling
	"""
	if not physics_body or not is_instance_valid(physics_body):
		return
	
	# Determine log count based on tree type
	var num_logs = 3
	match tree_type:
		TreeType.NORMAL:
			num_logs = 3 + randi() % 3  # 3-5 logs
		TreeType.PINE:
			num_logs = 4 + randi() % 3  # 4-6 logs (taller)
		TreeType.PALM:
			num_logs = 2 + randi() % 2  # 2-3 logs (shorter)
	
	# Get trunk material for visual consistency
	var trunk_material = get_trunk_material()
	
	# Calculate log dimensions
	var log_length = trunk_height / float(num_logs + 1)  # +1 to make logs slightly smaller
	var log_radius = trunk_radius * 0.9  # Slightly smaller than trunk
	
	# Get impact velocity for scatter physics
	var impact_velocity = physics_body.linear_velocity if physics_body else Vector3.ZERO
	
	# Spawn logs scattered from impact point
	for i in range(num_logs):
		spawn_single_log(
			ground_impact_position,
			log_length,
			log_radius,
			trunk_material,
			impact_velocity,
			i,
			num_logs
		)

func spawn_single_log(
	spawn_pos: Vector3,
	length: float,
	radius: float,
	material: Material,
	impact_velocity: Vector3,
	index: int,
	total_logs: int
):
	"""Spawn a single log segment with physics"""
	
	# Load LogPiece script
	var LogPieceScript = load("res://log_piece.gd")
	if not LogPieceScript:
		print("ERROR: Could not load log_piece.gd!")
		return
	
	# Create log using the LogPiece class with randomized lifetime
	var log = LogPieceScript.new()
	log.lifetime = randf_range(1.0, 4.0)  # Random 1-4 seconds
	get_tree().root.add_child(log)
	
	# Position along the fallen tree's length
	var along_trunk = (float(index) / float(total_logs)) - 0.5
	var trunk_direction = fall_direction if fall_direction != Vector3.ZERO else Vector3.FORWARD
	var trunk_offset = trunk_direction * along_trunk * trunk_height * 0.8
	
	# Small random scatter
	var scatter_offset = Vector3(
		randf_range(-0.3, 0.3),
		0.5 + randf_range(0, 0.3),
		randf_range(-0.3, 0.3)
	)
	
	log.global_position = spawn_pos + trunk_offset + scatter_offset
	
	# Random rotation for variety
	log.rotation = Vector3(
		randf_range(0, PI),
		randf_range(0, TAU),
		randf_range(0, PI)
	)
	
	# Physics properties - balanced for rolling without excessive sliding
	log.mass = 8.0 + randf_range(-2, 2)
	log.gravity_scale = 1.0
	log.linear_damp = 0.8
	log.angular_damp = 0.6
	log.can_sleep = true
	
	# Collision
	log.collision_layer = 2
	log.collision_mask = 1 + 2
	
	# Physics material for bounce and friction - adjusted for rolling
	var phys_mat = PhysicsMaterial.new()
	phys_mat.friction = 0.6
	phys_mat.bounce = 0.25
	log.physics_material_override = phys_mat
	
	# Create visual mesh
	var mesh_instance = MeshInstance3D.new()
	log.add_child(mesh_instance)
	
	var cylinder = CylinderMesh.new()
	cylinder.height = length
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.radial_segments = 8
	cylinder.rings = 1
	mesh_instance.mesh = cylinder
	
	# Apply material
	if material:
		mesh_instance.set_surface_override_material(0, material.duplicate())
	else:
		var log_mat = StandardMaterial3D.new()
		log_mat.albedo_color = Color(0.4, 0.3, 0.2)
		mesh_instance.material_override = log_mat
	
	# Collision shape - cylinder for proper rolling physics
	var collision_shape = CollisionShape3D.new()
	log.add_child(collision_shape)
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.height = length * 0.9
	cyl_shape.radius = radius * 0.95
	collision_shape.shape = cyl_shape
	
	# Apply scatter physics - moderate scatter for rolling without flying
	var scatter_direction = ground_impact_normal + Vector3(
		randf_range(-0.6, 0.6),
		randf_range(0.1, 0.3),
		randf_range(-0.6, 0.6)
	).normalized()
	
	var scatter_force = scatter_direction * randf_range(2.5, 4.5)
	log.apply_central_impulse(scatter_force)
	
	# Add moderate spin for rolling/tumbling
	var spin_torque = Vector3(
		randf_range(-6, 6),
		randf_range(-3, 3),
		randf_range(-6, 6)
	)
	log.apply_torque_impulse(spin_torque)

func get_trunk_material() -> Material:
	"""Get the trunk material for log consistency"""
	# Find trunk mesh (usually first mesh instance)
	for mesh_instance in tree_meshes:
		if mesh_instance and mesh_instance.mesh:
			# Get first surface material
			if mesh_instance.mesh.get_surface_count() > 0:
				var mat = mesh_instance.get_surface_override_material(0)
				if not mat:
					mat = mesh_instance.mesh.surface_get_material(0)
				if mat:
					return mat
	
	# Fallback: create basic brown material
	var fallback = StandardMaterial3D.new()
	fallback.albedo_color = Color(0.4, 0.25, 0.15)  # Brown
	return fallback

func convert_to_physics_body():
	"""Convert the static tree to a physics-enabled falling tree
	
	CRITICAL CONVERSION PROCESS:
	1. Find original collision shape (CylinderShape3D)
	2. Extract trunk dimensions (height, radius)
	3. Create new RigidBody3D as physics container
	4. Reparent all visual meshes to physics body
	5. Apply initial fall impulse (gentle tip away from player)
	
	PHYSICS TUNING:
	- High mass (100kg) prevents unrealistic flying
	- High damping (linear: 2.5, angular: 3.5) for slow, realistic fall
	- Capsule collision on trunk only (not foliage)
	- Physics material: max friction, zero bounce
	"""
	var current_position = global_position
	var current_rotation = global_rotation
	
	# Find the original collision shape to get accurate trunk dimensions
	var original_collision = null
	for child in get_children():
		if child is CollisionShape3D:
			original_collision = child
			# Get accurate trunk dimensions from original collision
			if original_collision.shape is CylinderShape3D:
				trunk_height = original_collision.shape.height
				trunk_radius = original_collision.shape.radius
			break
	
	if original_collision:
		# Remove old collision from tree
		original_collision.queue_free()
	
	# Get the parent before we change structure
	var tree_parent = get_parent()
	
	# Create a NEW RigidBody3D as the physics container
	physics_body = RigidBody3D.new()
	
	# Configure physics properties
	physics_body.mass = 100.0  # Heavy to prevent flying
	physics_body.gravity_scale = 2.0  # Stronger gravity for faster fall
	physics_body.linear_damp = 0.8  # Less air resistance = faster fall
	physics_body.angular_damp = 1.2  # Less rotation damping = tips faster
	physics_body.contact_monitor = true
	physics_body.max_contacts_reported = 10
	physics_body.can_sleep = false  # Keep active while falling
	
	# Set collision layers
	physics_body.collision_layer = 2  # Layer 2 for falling objects
	physics_body.collision_mask = 1 + 2  # Collide with terrain (1) and other trees (2)
	
	# Create collision shape for the physics body - ONLY THE TRUNK
	physics_collision = CollisionShape3D.new()
	physics_body.add_child(physics_collision)
	
	# Use a capsule that represents ONLY the trunk (not the foliage!)
	var capsule = CapsuleShape3D.new()
	capsule.radius = trunk_radius * 0.8  # Slightly smaller than visual trunk
	capsule.height = trunk_height * 0.9  # Just the trunk, not foliage
	physics_collision.shape = capsule
	
	# Position the collision at the TRUNK's center (not tree center)
	physics_collision.position = Vector3(0, trunk_height * 0.45, 0)
	physics_collision.rotation = Vector3(0, 0, 0)
	
	# Add physics material for friction (prevents sliding)
	var physics_material = PhysicsMaterial.new()
	physics_material.friction = 1.0  # Maximum friction
	physics_material.bounce = 0.0  # Zero bounce
	physics_body.physics_material_override = physics_material
	
	# Add the physics body to the scene
	tree_parent.add_child(physics_body)
	physics_body.global_position = current_position
	physics_body.global_rotation = current_rotation
	
	# Reparent the tree's visual nodes to the physics body
	var children_to_move = []
	for child in get_children():
		if child is MeshInstance3D or child is Node3D:
			children_to_move.append(child)
	
	for child in children_to_move:
		remove_child(child)
		physics_body.add_child(child)
	
	# Disable the original tree's collision
	collision_layer = 0
	collision_mask = 0
	
	# Calculate fall force direction
	var fall_force = fall_direction * 15.0  # Stronger horizontal push
	var fall_torque = Vector3(fall_direction.z, 0, -fall_direction.x).normalized() * 20.0  # Stronger tip
	
	# Apply the forces to make it fall
	physics_body.apply_central_impulse(fall_force)
	physics_body.apply_torque_impulse(fall_torque)
	
	# Connect to collision detection for impact
	physics_body.body_entered.connect(_on_ground_impact)

func _on_ground_impact(body: Node):
	"""Called when the falling tree hits the ground
	
	IMPACT DETECTION:
	- Only triggers once (has_hit_ground flag)
	- Detects collision with anything solid after tree is falling
	- Spawns logs immediately on impact
	- Destroys the falling tree
	"""
	if has_hit_ground:
		return  # Already processed impact
	
	# Ignore impacts in first 0.5 seconds (tree needs some time to tip)
	if fall_timer < 0.5:
		return
	
	# Only detect impact if tree has slowed down (but not too much - be more lenient)
	if physics_body and is_instance_valid(physics_body):
		var velocity = physics_body.linear_velocity.length()
		if velocity > 2.0:  # Still falling fast, wait a bit
			return
	
	# React to ANY collision (not just specific layers)
	# This catches terrain, trees, rocks, buildings, etc.
	has_hit_ground = true
	
	# Store impact position (use the tip of the tree, not the base)
	if physics_body and is_instance_valid(physics_body):
		# Get the tree tip position (where the tree actually hit)
		var tree_tip_offset = fall_direction * trunk_height * 0.7
		ground_impact_position = physics_body.global_position + tree_tip_offset
		
		# Calculate impact normal (up from terrain)
		ground_impact_normal = Vector3.UP
		
		# Spawn logs immediately on impact!
		spawn_log_pieces()
		
		# Destroy the falling tree
		if physics_body and is_instance_valid(physics_body):
			physics_body.queue_free()
		queue_free()

func _process(delta):
	if is_falling and physics_body and is_instance_valid(physics_body):
		fall_timer += delta
		
		# Manual collision detection - check earlier and more frequently
		if fall_timer > 0.5 and not has_hit_ground:
			var velocity = physics_body.linear_velocity.length()
			
			# Break if tree is colliding AND moving slowly (or stopped)
			var colliding_bodies = physics_body.get_colliding_bodies()
			if colliding_bodies.size() > 0 and velocity < 1.5:  # More lenient threshold
				has_hit_ground = true
				
				# Calculate impact position
				var tree_tip_offset = fall_direction * trunk_height * 0.7
				ground_impact_position = physics_body.global_position + tree_tip_offset
				ground_impact_normal = Vector3.UP
				
				# Spawn logs
				spawn_log_pieces()
				
				# Destroy tree
				physics_body.queue_free()
				queue_free()
				return
		
		# Backup timer: If tree has been falling for >2 seconds, force break (reduced from 2.5)
		if fall_timer > 2.0 and not has_hit_ground:
			has_hit_ground = true
			
			# Calculate impact position
			var tree_tip_offset = fall_direction * trunk_height * 0.7
			ground_impact_position = physics_body.global_position + tree_tip_offset
			ground_impact_normal = Vector3.UP
			
			# Spawn logs
			spawn_log_pieces()
			
			# Destroy tree
			physics_body.queue_free()
			queue_free()

func cancel_harvest():
	"""Override to stop shake when cancelled"""
	super.cancel_harvest()
	# Rotation is already reset in parent class
