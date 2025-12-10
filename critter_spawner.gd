extends Node3D
class_name CritterSpawner

"""
Spawns and manages ambient critters like rabbits.
Similar to VegetationSpawner but for animated creatures.
"""

# References
var chunk_manager: ChunkManager
var noise: FastNoiseLite
var critter_noise: FastNoiseLite
var player: Node3D

# Critter density settings
@export_group("Critter Density")
@export_range(0.0, 1.0) var rabbit_density: float = 0.12  ## Density of rabbits in grassland/forest (lowered for better spacing)
@export_range(5, 50) var critters_per_chunk: int = 2  ## Number of critter spawn attempts per chunk (keep low for performance)

@export_group("Critter Behavior")
@export_range(1.0, 10.0) var rabbit_move_speed: float = 3.0  ## How fast rabbits move
@export_range(0.5, 5.0) var idle_time_min: float = 1.0  ## Minimum idle time between moves
@export_range(0.5, 5.0) var idle_time_max: float = 3.0  ## Maximum idle time between moves
@export_range(2, 6) var spawn_radius_chunks: int = 3  ## How many chunks around player to spawn critters
@export_range(1.5, 3.0) var despawn_distance_multiplier: float = 2.0  ## Multiplier for despawn distance (spawn_radius * chunk_size * multiplier)

# Track spawned critters
var active_critters: Array = []
var populated_chunks: Dictionary = {}  # chunk_pos -> array of critters
var initialized: bool = false

# Critter types
enum CritterType {
	RABBIT
}

func _ready():
	# Initialize critter noise
	critter_noise = FastNoiseLite.new()
	critter_noise.seed = randi()
	critter_noise.frequency = 0.6
	critter_noise.noise_type = FastNoiseLite.TYPE_CELLULAR

func initialize(chunk_mgr: ChunkManager):
	chunk_manager = chunk_mgr
	noise = chunk_manager.noise
	player = chunk_manager.player
	initialized = true

func _process(delta):
	if not initialized or chunk_manager == null or player == null:
		return
	
	# Spawn critters in chunks around player
	var player_pos = player.global_position
	var player_chunk = chunk_manager.world_to_chunk(player_pos)
	
	for x in range(player_chunk.x - spawn_radius_chunks, player_chunk.x + spawn_radius_chunks + 1):
		for z in range(player_chunk.y - spawn_radius_chunks, player_chunk.y + spawn_radius_chunks + 1):
			var chunk_pos = Vector2i(x, z)
			# Check if chunk exists and hasn't been populated yet
			if chunk_manager.chunks.has(chunk_pos) and not populated_chunks.has(chunk_pos):
				# Delay spawn by one frame to ensure terrain is ready
				call_deferred("populate_chunk", chunk_pos)
	
	# Cleanup distant chunks (keep critters within reasonable range)
	cleanup_distant_chunks(player_chunk, spawn_radius_chunks * 2)
	
	# Despawn critters far from player
	cleanup_distant_critters(delta)

func cleanup_distant_chunks(player_chunk: Vector2i, max_distance: int):
	"""Remove critters from chunks that are too far from player"""
	var chunks_to_remove = []
	
	for chunk_pos in populated_chunks.keys():
		# Use Chebyshev distance (max of x and y) for chunk-based grid
		var dx = abs(chunk_pos.x - player_chunk.x)
		var dy = abs(chunk_pos.y - player_chunk.y)
		var distance = max(dx, dy)
		
		if distance > max_distance:
			chunks_to_remove.append(chunk_pos)
	
	for chunk_pos in chunks_to_remove:
		# Remove all critters in this chunk
		var critters_in_chunk = populated_chunks[chunk_pos]
		for critter in critters_in_chunk:
			if is_instance_valid(critter):
				active_critters.erase(critter)
				critter.queue_free()
		
		# Remove chunk from tracking
		populated_chunks.erase(chunk_pos)

func _physics_process(delta):
	if not initialized:
		return
	
	# Update all active critters
	for critter in active_critters:
		if not is_instance_valid(critter):
			continue
		
		update_critter_behavior(critter, delta)

func update_critter_behavior(critter: CharacterBody3D, delta: float):
	"""Manually update critter AI behavior"""
	# Get critter properties
	var critter_type = critter.get_meta("type")
	var move_speed = critter.get_meta("move_speed")
	var state = critter.get_meta("state")
	
	# No gravity needed - raycasts keep us on terrain
	var velocity = Vector3.ZERO
	
	if state == "idle":
		# Count down idle timer
		var idle_timer = critter.get_meta("idle_timer")
		idle_timer -= delta
		critter.set_meta("idle_timer", idle_timer)
		
		velocity.x = 0.0
		velocity.z = 0.0
		
		if idle_timer <= 0.0:
			# Start moving
			critter.set_meta("state", "moving")
			var move_dir = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
			critter.set_meta("move_direction", move_dir)
			critter.set_meta("move_timer", randf_range(1.0, 3.0))
			critter.set_meta("hop_timer", 0.0)
	
	elif state == "moving":
		var move_dir = critter.get_meta("move_direction")
		var move_timer = critter.get_meta("move_timer")
		
		move_timer -= delta
		critter.set_meta("move_timer", move_timer)
		
		if critter_type == "rabbit":
			# Hopping motion
			var hop_timer = critter.get_meta("hop_timer")
			hop_timer += delta
			critter.set_meta("hop_timer", hop_timer)
			
			if hop_timer > 0.5:  # Hop every 0.5 seconds
				critter.set_meta("hop_timer", 0.0)
				# Add hop effect by raising critter slightly
				velocity.y = 1.5  # Small upward movement for hop visual
			
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
			
			# Face movement direction (fixed - was backwards)
			if move_dir.length() > 0.1:
				var target_rotation = atan2(move_dir.x, move_dir.z)  # Removed negatives to flip direction
				critter.rotation.y = lerp_angle(critter.rotation.y, target_rotation, delta * 5.0)
		
		if move_timer <= 0.0:
			# Go back to idle
			critter.set_meta("state", "idle")
			critter.set_meta("idle_timer", randf_range(1.0, 3.0))
	
	# Apply movement manually (no move_and_slide to avoid collisions)
	var new_position = critter.global_position + velocity * delta
	
	# Raycast down to find terrain (only when moving to reduce raycast calls)
	if velocity.length_squared() > 0.01:  # Only raycast if actually moving
		var space_state = critter.get_world_3d().direct_space_state
		if space_state:
			var ray_start = Vector3(new_position.x, new_position.y + 2.0, new_position.z)
			var ray_end = Vector3(new_position.x, new_position.y - 5.0, new_position.z)
			
			var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
			query.collision_mask = 1  # Only detect terrain
			
			var result = space_state.intersect_ray(query)
			if result:
				# Snap to terrain
				new_position.y = result.position.y + 0.1  # Slight offset above ground
	
	critter.global_position = new_position

func populate_chunk(chunk_pos: Vector2i):
	"""Spawn critters in a chunk"""
	if populated_chunks.has(chunk_pos):
		return
	
	# Create array to track critters in this chunk
	populated_chunks[chunk_pos] = []
	
	var chunk_size = chunk_manager.chunk_size
	var world_offset = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)
	
	for i in range(critters_per_chunk):
		var local_x = randf() * chunk_size
		var local_z = randf() * chunk_size
		var world_x = world_offset.x + local_x
		var world_z = world_offset.y + local_z
		
		var base_noise = noise.get_noise_2d(world_x, world_z)
		var biome = get_biome_at_position(world_x, world_z, base_noise)
		
		# Skip ocean biomes
		if biome == Chunk.Biome.OCEAN:
			continue
		
		var height = get_terrain_height_with_raycast(world_x, world_z, base_noise, biome)
		
		# Don't spawn underwater or too close to water level
		if height < 2.0:
			continue
		
		var critter = spawn_critter_for_biome(biome, Vector3(world_x, height, world_z))
		if critter:
			populated_chunks[chunk_pos].append(critter)

func spawn_critter_for_biome(biome: Chunk.Biome, spawn_pos: Vector3):
	"""Spawn appropriate critter for biome. Returns critter instance or null."""
	var critter_type: CritterType
	var rand = randf()
	
	match biome:
		Chunk.Biome.GRASSLAND:
			if rand < rabbit_density:
				critter_type = CritterType.RABBIT
			else:
				return null
		
		Chunk.Biome.FOREST:
			if rand < rabbit_density * 0.8:  # Slightly less in forest
				critter_type = CritterType.RABBIT
			else:
				return null
		
		_:
			# No critters in other biomes (ocean, beach, desert, mountain, snow)
			return null
	
	return create_critter(critter_type, spawn_pos)

func create_critter(critter_type: CritterType, spawn_position: Vector3) -> CharacterBody3D:
	"""Create a critter instance and return it"""
	var critter = CharacterBody3D.new()
	add_child(critter)
	critter.global_position = spawn_position
	
	# Set collision - critter should be completely non-solid
	critter.collision_layer = 8  # Layer 8 for critters
	critter.collision_mask = 0   # Don't detect anything via move_and_slide
	
	# We'll manually position critters on terrain using raycasts instead of move_and_slide
	
	# Enable floor snapping for smooth terrain following
	critter.floor_stop_on_slope = true
	critter.floor_max_angle = deg_to_rad(46)
	critter.floor_snap_length = 0.5
	
	# Create visual mesh
	var mesh_instance = MeshInstance3D.new()
	critter.add_child(mesh_instance)
	
	# Create collision shape
	var collision = CollisionShape3D.new()
	critter.add_child(collision)
	
	# Set up critter metadata BEFORE creating mesh (so type is available)
	match critter_type:
		CritterType.RABBIT:
			critter.set_meta("type", "rabbit")
			critter.set_meta("move_speed", rabbit_move_speed)
			create_rabbit_visual(mesh_instance, collision)
	
	# Set up critter behavior metadata
	critter.set_meta("state", "idle")
	critter.set_meta("idle_timer", randf_range(idle_time_min, idle_time_max))
	critter.set_meta("move_direction", Vector3.ZERO)
	critter.set_meta("hop_timer", 0.0)
	critter.set_meta("move_timer", 0.0)
	critter.set_meta("spawn_time", Time.get_ticks_msec() * 0.001)
	
	# Add to tracking
	active_critters.append(critter)
	
	# Add behavior script
	add_critter_behavior(critter)
	
	return critter

func create_rabbit_visual(mesh_instance: MeshInstance3D, collision: CollisionShape3D):
	"""Create pixelated rabbit mesh"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Rabbit colors - darker brown (was too light/washed out)
	var body_color = Color(0.35, 0.25, 0.18)  # Darker brown body
	var ear_color = Color(0.4, 0.3, 0.22)      # Slightly lighter ears
	var tail_color = Color(0.5, 0.4, 0.32)     # Light brown/tan tail
	
	# Body (main sphere) - 1.5X size for better visibility
	add_box(surface_tool, Vector3(0, 0.3, 0), Vector3(0.45, 0.375, 0.6), body_color)
	
	# Head (smaller sphere) - 1.5X size
	add_box(surface_tool, Vector3(0, 0.525, 0.375), Vector3(0.3, 0.3, 0.375), body_color)
	
	# Ears (tall boxes) - 1.5X size
	add_box(surface_tool, Vector3(-0.12, 0.825, 0.45), Vector3(0.075, 0.225, 0.12), ear_color)
	add_box(surface_tool, Vector3(0.12, 0.825, 0.45), Vector3(0.075, 0.225, 0.12), ear_color)
	
	# Tail (small fluffy ball) - 1.5X size
	add_box(surface_tool, Vector3(0, 0.375, -0.3), Vector3(0.15, 0.15, 0.15), tail_color)
	
	# Legs (4 small boxes)
	add_box(surface_tool, Vector3(-0.12, 0.05, 0.1), Vector3(0.06, 0.08, 0.06), body_color)
	add_box(surface_tool, Vector3(0.12, 0.05, 0.1), Vector3(0.06, 0.08, 0.06), body_color)
	add_box(surface_tool, Vector3(-0.12, 0.05, -0.1), Vector3(0.06, 0.08, 0.06), body_color)
	add_box(surface_tool, Vector3(0.12, 0.05, -0.1), Vector3(0.06, 0.08, 0.06), body_color)
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	mesh_instance.mesh = mesh
	
	# Material - apply to mesh instance, not mesh
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.roughness = 0.8
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Boost ambient light to make colors more visible
	material.albedo_color = Color(1.5, 1.5, 1.5)  # Brighten the vertex colors
	
	mesh_instance.set_surface_override_material(0, material)
	
	# Collision shape - 1.5X original size
	var shape = CapsuleShape3D.new()
	shape.radius = 0.3  # 1.5X original (was 0.6)
	shape.height = 0.6  # 1.5X original (was 1.2)
	collision.shape = shape
	collision.position.y = 0.3  # 1.5X original (was 0.6)

func add_box(surface_tool: SurfaceTool, center: Vector3, size: Vector3, color: Color):
	"""Helper to add a box to the mesh"""
	var half = size / 2.0
	
	# Define 8 corners
	var corners = [
		center + Vector3(-half.x, -half.y, -half.z),
		center + Vector3(half.x, -half.y, -half.z),
		center + Vector3(half.x, -half.y, half.z),
		center + Vector3(-half.x, -half.y, half.z),
		center + Vector3(-half.x, half.y, -half.z),
		center + Vector3(half.x, half.y, -half.z),
		center + Vector3(half.x, half.y, half.z),
		center + Vector3(-half.x, half.y, half.z),
	]
	
	# 6 faces (each face = 2 triangles)
	var faces = [
		[0, 1, 2, 3],  # Bottom
		[4, 7, 6, 5],  # Top
		[0, 4, 5, 1],  # Front
		[2, 6, 7, 3],  # Back
		[0, 3, 7, 4],  # Left
		[1, 5, 6, 2],  # Right
	]
	
	for face in faces:
		surface_tool.set_color(color)
		surface_tool.add_vertex(corners[face[0]])
		surface_tool.add_vertex(corners[face[1]])
		surface_tool.add_vertex(corners[face[2]])
		
		surface_tool.add_vertex(corners[face[0]])
		surface_tool.add_vertex(corners[face[2]])
		surface_tool.add_vertex(corners[face[3]])

func add_critter_behavior(critter: CharacterBody3D):
	"""Add AI behavior to critter"""
	# Instead of dynamically creating script, we'll use a simpler approach
	# that's more reliable in Godot 4
	
	# Store initial values
	var critter_type = critter.get_meta("type")
	var move_speed = critter.get_meta("move_speed")
	
	# Connect to process for manual behavior
	critter.set_physics_process(true)
	
	# We'll manually handle the behavior in _process of the spawner
	# This is more reliable than dynamic script compilation

func cleanup_distant_critters(delta: float):
	"""Remove critters that are too far from player"""
	if not player or not chunk_manager:
		return
	
	var player_pos = player.global_position
	var critters_to_remove = []
	
	# Calculate despawn distance based on spawn settings
	var despawn_distance = spawn_radius_chunks * chunk_manager.chunk_size * despawn_distance_multiplier
	
	for critter in active_critters:
		if not is_instance_valid(critter):
			critters_to_remove.append(critter)
			continue
		
		var distance = critter.global_position.distance_to(player_pos)
		
		if distance > despawn_distance:
			critters_to_remove.append(critter)
	
	for critter in critters_to_remove:
		active_critters.erase(critter)
		if is_instance_valid(critter):
			critter.queue_free()

func get_biome_at_position(world_x: float, world_z: float, base_noise: float) -> Chunk.Biome:
	"""Get biome at world position - copied from VegetationSpawner"""
	var temperature = chunk_manager.temperature_noise.get_noise_2d(world_x, world_z)
	var moisture = chunk_manager.moisture_noise.get_noise_2d(world_x, world_z)
	
	if base_noise < -0.2:
		if base_noise < -0.35:
			return Chunk.Biome.OCEAN
		else:
			return Chunk.Biome.BEACH
	elif base_noise > 0.4:
		if temperature < -0.2:
			return Chunk.Biome.SNOW
		else:
			return Chunk.Biome.MOUNTAIN
	else:
		if temperature > 0.2 and moisture < 0.0:
			return Chunk.Biome.DESERT
		elif moisture > 0.15:
			return Chunk.Biome.FOREST
		else:
			return Chunk.Biome.GRASSLAND
	
	return Chunk.Biome.GRASSLAND

func get_terrain_height_with_raycast(world_x: float, world_z: float, base_noise: float, biome: Chunk.Biome) -> float:
	"""Get terrain height - use calculated height and validate with raycast if possible"""
	var calculated_height = get_terrain_height_at_position(world_x, world_z, base_noise, biome)
	
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return calculated_height  # Use calculated if raycast not available
	
	var ray_start = Vector3(world_x, calculated_height + 10.0, world_z)
	var ray_end = Vector3(world_x, calculated_height - 2.0, world_z)
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position.y
	
	# If raycast fails, use calculated height (terrain might not be loaded yet)
	return calculated_height

func get_terrain_height_at_position(_world_x: float, _world_z: float, base_noise: float, biome: Chunk.Biome) -> float:
	"""Calculate terrain height - copied from VegetationSpawner"""
	var height_multiplier = chunk_manager.height_multiplier
	
	var height_mod = 1.0
	var roughness_mod = 1.0
	
	match biome:
		Chunk.Biome.OCEAN:
			height_mod = 0.3
			roughness_mod = 0.7
		Chunk.Biome.BEACH:
			height_mod = 0.7
			roughness_mod = 0.7
		Chunk.Biome.MOUNTAIN:
			height_mod = 1.3
			roughness_mod = 1.1
		Chunk.Biome.SNOW:
			height_mod = 1.4
			roughness_mod = 1.05
		Chunk.Biome.DESERT:
			height_mod = 0.9
			roughness_mod = 0.8
		Chunk.Biome.FOREST:
			height_mod = 1.05
			roughness_mod = 0.95
		Chunk.Biome.GRASSLAND:
			height_mod = 1.0
			roughness_mod = 0.85
	
	var modified_height = base_noise * roughness_mod
	var height = modified_height * height_multiplier * height_mod
	
	if biome == Chunk.Biome.OCEAN:
		height = height - (height_multiplier * 0.3)
	elif biome == Chunk.Biome.BEACH:
		height = height + (height_multiplier * 0.2)
	else:
		height = height + (height_multiplier * 0.5)
	
	return height
