extends HarvestableResource
class_name HarvestableTree

# Tree-specific properties
enum TreeType {
	NORMAL,    # Regular deciduous tree
	PINE,      # Coniferous/evergreen
	PALM       # Tropical palm tree
}

@export var tree_type: TreeType = TreeType.NORMAL
@export var tree_height: float = 6.0  # Total height of tree
@export var leave_stump: bool = true

# Physics-based falling
var is_falling: bool = false
var fall_direction: Vector3 = Vector3.ZERO
var fall_timer: float = 0.0
var despawn_delay: float = 2.0  # Tree stays on ground for 2 seconds
var fade_duration: float = 2.0  # Dissolve effect over 2 seconds
var has_hit_ground: bool = false
var ground_hit_time: float = 0.0

# Physics components (created when falling)
var physics_body: RigidBody3D = null
var physics_collision: CollisionShape3D = null

# Stump reference
var stump_mesh: MeshInstance3D = null

# Original mesh reference for fading
var original_materials: Array = []
var tree_meshes: Array = []  # All MeshInstance3D children

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
	
	# Cache all mesh instances for later fading
	cache_mesh_instances(self)
	
	# NOW call parent _ready
	super._ready()

func cache_mesh_instances(node: Node):
	"""Recursively find and cache all MeshInstance3D children"""
	if node is MeshInstance3D:
		tree_meshes.append(node)
		# Store original materials for fading
		if node.mesh:
			for i in range(node.mesh.get_surface_count()):
				var mat = node.get_surface_override_material(i)
				if not mat:
					mat = node.mesh.surface_get_material(i)
				if mat:
					original_materials.append(mat.duplicate())
				else:
					original_materials.append(null)
	
	for child in node.get_children():
		cache_mesh_instances(child)

func start_harvest(player: Node3D) -> bool:
	"""Override to calculate fall direction when harvest starts"""
	if not is_being_harvested:
		# Calculate fall direction (away from player)
		var to_player = (player.global_position - global_position).normalized()
		to_player.y = 0  # Keep it horizontal
		fall_direction = -to_player  # Fall away from player
	
	return super.start_harvest(player)

func update_harvest(delta: float) -> float:
	"""Update harvest progress with shake effect"""
	if not is_being_harvested:
		return 0.0
	
	harvest_progress += delta / harvest_time
	harvest_progress = clamp(harvest_progress, 0.0, 1.0)
	
	# Shake effect on each hit (when progress increases)
	apply_hit_shake()
	
	# Don't auto-complete - let harvesting system handle it
	return harvest_progress

func apply_hit_shake():
	"""Make tree shake when hit"""
	if not is_being_harvested:
		return
	
	# Quick shake using rotation
	var shake_amount = 0.05  # Radians
	var shake_speed = 30.0   # Speed of shake
	var time = Time.get_ticks_msec() * 0.001
	
	rotation.z = original_rotation.z + sin(time * shake_speed) * shake_amount * (1.0 - harvest_progress)
	rotation.x = original_rotation.x + cos(time * shake_speed * 0.7) * shake_amount * 0.5 * (1.0 - harvest_progress)

func apply_harvest_visual_feedback():
	"""Override to do shake instead of pulse"""
	# Shake is handled in apply_hit_shake
	pass

func complete_harvest():
	"""Override to trigger falling animation instead of immediate destruction"""
	if not is_being_harvested:
		return
	
	# Calculate drops
	var drop_count = randi_range(drop_amount_min, drop_amount_max)
	var drops = {
		"item": drop_item,
		"amount": drop_count
	}
	
	emit_signal("harvested", drops)
	
	# Reset harvest state
	is_being_harvested = false
	harvester = null
	harvest_progress = 0.0
	
	# Start falling animation instead of immediate destruction
	start_falling()

func start_falling():
	"""Begin the physics-based tree falling"""
	is_falling = true
	has_hit_ground = false
	ground_hit_time = 0.0
	
	# Spawn wood particles at the base
	spawn_break_particles()
	
	# Create stump if enabled
	if leave_stump:
		create_stump()
	
	# Convert to physics body for realistic falling
	convert_to_physics_body()

func spawn_log_pieces():
	"""Break the tree into log pieces that scatter"""
	if not physics_body or not is_instance_valid(physics_body):
		return
	
	var tree_position = physics_body.global_position
	var num_logs = 3 + randi() % 3  # 3-5 log pieces
	
	# Get the tree parent to spawn logs in world
	var world = get_tree().root
	
	# Find ANY mesh in the tree to get trunk material - try all meshes
	var trunk_material = null
	for child in physics_body.get_children():
		if child is MeshInstance3D:
			var mesh_instance = child as MeshInstance3D
			if mesh_instance.mesh and mesh_instance.mesh.get_surface_count() > 0:
				var mat = mesh_instance.get_surface_override_material(0)
				if not mat:
					mat = mesh_instance.mesh.surface_get_material(0)
				if mat:
					# Found a material - use it!
					trunk_material = mat
					break
	
	for i in range(num_logs):
		var log = RigidBody3D.new()
		world.add_child(log)
		
		# Position ON THE GROUND near the tree
		var offset = Vector3(randf() - 0.5, 0.2, randf() - 0.5)  # Keep Y low
		log.global_position = tree_position + offset
		
		# Physics properties - heavier and more damped
		log.mass = 20.0  # Even heavier logs
		log.gravity_scale = 2.0  # Fall faster
		log.linear_damp = 4.0  # Very high damping
		log.angular_damp = 4.0
		
		# Create log mesh (cylinder)
		var mesh_instance = MeshInstance3D.new()
		log.add_child(mesh_instance)
		
		var cylinder = CylinderMesh.new()
		cylinder.height = 0.8 + randf() * 0.4  # 0.8-1.2m logs
		cylinder.top_radius = 0.15
		cylinder.bottom_radius = 0.15
		mesh_instance.mesh = cylinder
		
		# Copy the trunk material if found
		if trunk_material:
			mesh_instance.set_surface_override_material(0, trunk_material.duplicate())
		else:
			# Fallback to brown
			var log_material = StandardMaterial3D.new()
			log_material.albedo_color = Color(0.4, 0.25, 0.15)
			mesh_instance.material_override = log_material
		
		# Collision
		var collision = CollisionShape3D.new()
		log.add_child(collision)
		var shape = CylinderShape3D.new()
		shape.radius = 0.15
		shape.height = cylinder.height
		collision.shape = shape
		
		# Lay logs flat on ground (rotate 90 degrees)
		log.rotation = Vector3(PI/2, randf() * TAU, 0)
		
		# Apply VERY gentle scatter force - just a nudge
		var scatter_direction = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
		log.apply_central_impulse(scatter_direction * (2.0 + randf() * 3.0))  # 2-5 force only
		log.apply_torque_impulse(Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * 2.0)  # Very gentle spin
		
		# Store reference for cleanup
		var timer = Timer.new()
		log.add_child(timer)
		timer.wait_time = 1.5 + randf() * 1.0  # 1.5-2.5 seconds (was 3-5)
		timer.one_shot = true
		timer.timeout.connect(func(): 
			if is_instance_valid(log):
				# Spawn wood particles at log position
				var log_pos = log.global_position
				HarvestParticles.create_break_particles(log_pos, "wood", world)
				# Delete the log
				log.queue_free()
		)
		timer.start()

func convert_to_physics_body():
	"""Convert the tree from StaticBody3D to RigidBody3D for physics simulation"""
	
	# Store the tree's current position and rotation
	var current_position = global_position
	var current_rotation = global_rotation
	
	# Find and remove the existing collision shape from the tree
	var original_collision: CollisionShape3D = null
	var trunk_height = tree_height
	var trunk_radius = 0.3
	
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
	physics_body.mass = 100.0  # Even heavier to prevent flying
	physics_body.gravity_scale = 1.5  # Stronger gravity
	physics_body.linear_damp = 2.5  # Much more air resistance (was 1.0)
	physics_body.angular_damp = 3.5  # Much more rotation damping (was 2.5)
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
	# This prevents the foliage from causing collision issues
	physics_collision.position = Vector3(0, trunk_height * 0.45, 0)
	physics_collision.rotation = Vector3(0, 0, 0)
	
	# Add physics material for friction (prevents sliding)
	var physics_material = PhysicsMaterial.new()
	physics_material.friction = 1.0  # Maximum friction (was 0.9)
	physics_material.bounce = 0.0  # Zero bounce (was 0.1)
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
	
	# Calculate fall force direction - EXTREMELY MINIMAL
	# The tree should tip VERY SLOWLY like it's top-heavy
	var fall_force = fall_direction * 8.0  # Almost no horizontal push
	var fall_torque = Vector3(fall_direction.z, 0, -fall_direction.x).normalized() * 12.0  # Even gentler tip
	
	# Apply the forces to make it fall
	physics_body.apply_central_impulse(fall_force)
	physics_body.apply_torque_impulse(fall_torque)
	
	# The tree should fall slowly, like it's unbalanced and top-heavy
	
	# Initialize all materials for transparency NOW (before fading starts)
	prepare_materials_for_fade()
	
	# Connect to collision detection
	physics_body.body_entered.connect(_on_physics_collision)

func prepare_materials_for_fade():
	"""Prepare all materials to support transparency before fading starts"""
	if not physics_body or not is_instance_valid(physics_body):
		return
	
	for child in physics_body.get_children():
		setup_transparent_materials(child)

func setup_transparent_materials(node: Node):
	"""Recursively setup materials on all meshes"""
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		
		if mesh_instance.mesh:
			for surface_idx in range(mesh_instance.mesh.get_surface_count()):
				# Get or duplicate the material
				var original = mesh_instance.mesh.surface_get_material(surface_idx)
				if original and original is StandardMaterial3D:
					var material = original.duplicate()
					
					# Enable transparency
					material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					
					# Set alpha to 1.0 (fully visible) to start
					var color = material.albedo_color
					color.a = 1.0
					material.albedo_color = color
					
					mesh_instance.set_surface_override_material(surface_idx, material)
	
	# Recurse
	for child in node.get_children():
		setup_transparent_materials(child)

func _on_physics_collision(body: Node):
	"""Called when the falling tree collides with something"""
	pass  # Can detect collisions here if needed

func create_stump():
	"""Create a stump that remains after tree falls"""
	stump_mesh = MeshInstance3D.new()
	get_parent().add_child(stump_mesh)
	
	# Position stump at tree base
	stump_mesh.global_position = global_position
	stump_mesh.rotation = Vector3.ZERO  # Keep upright
	
	# Create simple cylinder stump
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.4
	cylinder.bottom_radius = 0.5  # Slightly wider at bottom
	cylinder.height = 0.5  # Short stump
	stump_mesh.mesh = cylinder
	
	# Find ANY mesh to get trunk material
	var trunk_material = null
	for child in get_children():
		if child is MeshInstance3D:
			var mesh_instance = child as MeshInstance3D
			if mesh_instance.mesh and mesh_instance.mesh.get_surface_count() > 0:
				var mat = mesh_instance.get_surface_override_material(0)
				if not mat:
					mat = mesh_instance.mesh.surface_get_material(0)
				if mat:
					trunk_material = mat
					break
	
	# Apply material
	if trunk_material:
		stump_mesh.set_surface_override_material(0, trunk_material.duplicate())
	else:
		var stump_material = StandardMaterial3D.new()
		stump_material.albedo_color = Color(0.3, 0.2, 0.1)
		stump_mesh.material_override = stump_material
	
	# Add collision to stump
	var static_body = StaticBody3D.new()
	stump_mesh.add_child(static_body)
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	
	var collision_shape = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.4
	shape.height = 0.5
	collision_shape.shape = shape
	static_body.add_child(collision_shape)

func _process(delta):
	if is_falling:
		fall_timer += delta
		
		# Track the physics body velocity to detect when it stops
		if physics_body and is_instance_valid(physics_body):
			# Check if the tree has come to rest (low velocity)
			var velocity = physics_body.linear_velocity
			
			if not has_hit_ground:
				# Consider ground hit when velocity is very low
				# AND we've been falling for at least 0.5 seconds (to avoid premature detection)
				if velocity.length() < 0.8 and fall_timer > 0.5:
					has_hit_ground = true
					ground_hit_time = fall_timer
			
			# If tree has settled, wait a moment then break into logs
			if has_hit_ground:
				var time_since_ground = fall_timer - ground_hit_time
				
				# Break into logs after longer delay
				if time_since_ground >= 2.0:  # Wait 2 seconds (was 0.5)
					# Spawn log pieces
					spawn_log_pieces()
					
					# Destroy the tree and physics body immediately
					if physics_body and is_instance_valid(physics_body):
						physics_body.queue_free()
					queue_free()
					return

func apply_fade_to_node(node: Node, alpha: float):
	"""Recursively apply fade to a node and its children"""
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		
		# Make it shrink down dramatically - like sinking into the ground
		mesh_instance.visible = true
		mesh_instance.scale = Vector3(alpha, alpha, alpha)  # Shrink to 0
		
		# Hide completely when very small
		if alpha < 0.05:
			mesh_instance.visible = false
	
	# Recurse to children
	for child in node.get_children():
		apply_fade_to_node(child, alpha)

func spawn_despawn_particles():
	"""Spawn a poof particle effect when tree despawns"""
	if physics_body and is_instance_valid(physics_body):
		var tree_position = physics_body.global_position
		# Get the world root to spawn particles in
		var world = get_tree().root
		if world:
			# Use the harvest particles system to create a poof effect
			HarvestParticles.create_break_particles(tree_position, "wood", world)


func cancel_harvest():
	"""Override to stop shake when cancelled"""
	super.cancel_harvest()
	# Rotation is already reset in parent class
