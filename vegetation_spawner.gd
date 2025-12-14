extends Node3D
class_name VegetationSpawner

"""
VegetationSpawner - Procedurally populates chunks with vegetation and resources

ARCHITECTURE:
- Spawns vegetation in 2-chunk radius around player as they explore
- Two-pass system: large vegetation (trees/rocks) then ground cover (grass/flowers)
- Creates HarvestableResource instances (trees, mushrooms, strawberries, rocks)
- Uses noise for natural placement and biome-specific distributions

INTEGRATION POINTS:
- Requires ChunkManager reference for terrain data and chunk positions
- Requires Player reference to know where to spawn around
- Uses PixelTextureGenerator (global class) for all textures
- Spawned resources must set collision_layer = 2 for player raycasts

PERFORMANCE:
- Tracks populated_chunks to avoid respawning same areas
- Uses MultiMesh for grass blades (100+ instances per tuft)
- Raycast validation uses calculated height for tighter window (+5/-5 meters)
- Spawns happen over multiple frames via call_deferred

BIOME SYSTEM:
- 7 biomes: Ocean, Beach, Grassland, Forest, Desert, Mountain, Snow
- Each biome has specific vegetation types and densities
- Uses temperature and moisture noise for biome determination
"""

# Preload resource node classes
const ResourceNodeClass = preload("res://resource_node.gd")
const HarvestableTreeClass = preload("res://harvestable_tree.gd")
const HarvestableMushroomClass = preload("res://harvestable_mushroom.gd")
const HarvestableStrawberryClass = preload("res://harvestable_strawberry.gd")
# Note: PixelTextureGenerator is a global class, no need to preload

# Preload visual generator classes
const TreeVisual = preload("res://vegetation/visuals/tree_visual.gd")
const PineTreeVisual = preload("res://vegetation/visuals/pine_tree_visual.gd")
const PalmTreeVisual = preload("res://vegetation/visuals/palm_tree_visual.gd")

# References
var chunk_manager: ChunkManager
var noise: FastNoiseLite
var vegetation_noise: FastNoiseLite
var cluster_noise: FastNoiseLite  # For grass clustering
var player: Node3D

# Vegetation density settings - individual control for each type
@export_group("Vegetation Density")
@export_range(0.0, 1.0) var tree_density: float = 0.40  ## Forests feel full, grasslands open
@export_range(0.0, 1.0) var rock_density: float = 0.30  ## Common but not overwhelming
@export_range(0.0, 1.0) var mushroom_density: float = 0.18  ## Rare forest finds
@export_range(0.0, 1.0) var strawberry_density: float = 0.25  ## Regular food source
@export_range(0.0, 1.0) var grass_density: float = 0.35  ## Reduced for performance (was 0.75)
@export_range(0.0, 1.0) var flower_density: float = 0.20  ## Colorful accents
@export_range(1, 5) var spawn_radius: int = 2  ## Reduced for performance (was 3)

@export_group("Tree Size Variation")
@export_range(2.0, 15.0) var tree_height_min: float = 4.0  ## Valheim scale
@export_range(2.0, 15.0) var tree_height_max: float = 10.0  ## Impressive but not ridiculous
@export_range(0.1, 1.0) var trunk_radius_base: float = 0.35  ## Sturdy trunks

@export_group("Tree Branch Settings")
@export_range(2, 8) var branch_count_min: int = 3  ## Minimum variety
@export_range(2, 8) var branch_count_max: int = 6  ## Fuller canopies
@export_range(0.5, 3.0) var branch_length_min: float = 1.5  
@export_range(0.5, 3.0) var branch_length_max: float = 2.2  ## Wider spread
@export_range(0.0, 1.0) var branch_height_start: float = 0.45  ## Lower branches
@export_range(0.0, 1.0) var branch_height_end: float = 0.85  
@export_range(0.0, 0.5) var branch_upward_angle: float = 0.20  ## Natural droop

@export_group("Tree Foliage Settings")
@export_range(2, 8) var branch_foliage_layers: int = 5  ## Fuller coverage
@export_range(2, 10) var top_foliage_layers: int = 6  ## Dense crown
@export_range(0.1, 1.0) var foliage_disc_thickness: float = 0.45  
@export_range(0.0, 1.0) var foliage_layer_gap: float = 0.15  ## Tighter layering
@export_range(0.5, 2.0) var foliage_disc_size: float = 0.80  ## Balanced canopy
@export_range(0.7, 1.0) var top_crown_height_ratio: float = 0.85  ## Lower crown start

@export_group("Tree Trunk Tilt Settings")
@export_range(0.0, 0.4) var trunk_tilt_max: float = 0.12  ## Subtle character
@export_range(0.0, 1.0) var trunk_tilt_influence: float = 0.65  

@export_group("Character Tree Settings")
@export_range(0.0, 0.15) var character_tree_chance: float = 0.08  ## Slightly more common
@export_range(0.0, 1.0) var branch_asymmetry_amount: float = 0.35  

@export_group("Ground Cover Settings")
@export_range(10, 150) var ground_cover_samples_per_chunk: int = 25  ## Reduced for performance (was 75)
@export_range(5, 50) var large_vegetation_samples_per_chunk: int = 10  ## Reduced for performance (was 18)

@export_group("Forest Biome Configuration")
@export_range(0.0, 1.0) var forest_tree_density: float = 0.50  ## Reduced for performance (was 0.75)
@export_range(0.0, 1.0) var forest_mushroom_density: float = 0.55  ## Abundant mushrooms
@export_range(0.0, 1.0) var forest_rock_density: float = 0.25  

@export_group("Grassland Biome Configuration")
@export_range(0.0, 1.0) var grassland_tree_density: float = 0.12  ## Reduced for performance (was 0.18)
@export_range(0.0, 1.0) var grassland_strawberry_density: float = 0.60  ## Berry fields
@export_range(0.0, 1.0) var grassland_rock_density: float = 0.50  ## Reduced (was 0.70)

@export_group("Mountain Biome Configuration")
@export_range(0.0, 1.0) var mountain_pine_density: float = 0.20  ## Sparse treeline
@export_range(0.0, 1.0) var mountain_rock_density: float = 0.80  ## Very rocky
@export_range(0.0, 1.0) var mountain_boulder_ratio: float = 0.60  ## Lots of boulders

@export_group("Snow Biome Configuration")
@export_range(0.0, 1.0) var snow_pine_density: float = 0.30  ## Sparse pines
@export_range(0.0, 1.0) var snow_rock_density: float = 0.50  

@export_group("Desert Biome Configuration")
@export_range(0.0, 1.0) var desert_cactus_density: float = 0.25  ## Sparse cacti
@export_range(0.0, 1.0) var desert_rock_density: float = 0.65  

@export_group("Beach Biome Configuration")
@export_range(0.0, 1.0) var beach_palm_density: float = 0.30  ## Tropical feel
@export_range(0.0, 1.0) var beach_rock_density: float = 0.45

# Track which chunks have vegetation - now stores arrays of node references for cleanup
var populated_chunks: Dictionary = {}  # chunk_pos -> Array of vegetation nodes
var initialized: bool = false
var _current_chunk: Vector2i = Vector2i.ZERO  # Currently populating chunk (for node tracking)
var _chunk_grass_positions: Array = []  # Temporary: grass positions for current chunk MultiMesh

# Tree shape types for visual variety
enum TreeShape {
	PYRAMIDAL,    # Young/skinny - branches angle up, tight crown
	ROUND,        # Mature - even spread, full crown
	WIDE_SPREAD   # Old - branches angle out wide, flat crown
}

# Vegetation types per biome
enum VegType {
	TREE,
	PINE_TREE,
	ROCK,
	SMALL_ROCK,       # Smaller rocks (1/3 size, 1 stone)
	BOULDER,
	CACTUS,
	GRASS_TUFT,
	GRASS_PATCH,      # Dense cluster of grass
	PALM_TREE,
	MUSHROOM_RED,
	MUSHROOM_BROWN,
	MUSHROOM_CLUSTER,
	WILDFLOWER_YELLOW,
	WILDFLOWER_PURPLE,
	WILDFLOWER_WHITE,
	STRAWBERRY_BUSH_SMALL,
	STRAWBERRY_BUSH_MEDIUM,
	STRAWBERRY_BUSH_LARGE
}

func _ready():
	# Initialize vegetation noise (different from terrain noise)
	vegetation_noise = FastNoiseLite.new()
	vegetation_noise.seed = randi()
	vegetation_noise.frequency = 0.5  # High frequency for scattered placement
	vegetation_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	
	# Initialize cluster noise for grass patches
	cluster_noise = FastNoiseLite.new()
	cluster_noise.seed = vegetation_noise.seed + 1000
	cluster_noise.frequency = 0.15  # Lower frequency = larger patches
	cluster_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	print("VegetationSpawner ready, waiting for initialization...")

func initialize(chunk_mgr: ChunkManager):
	chunk_manager = chunk_mgr
	noise = chunk_manager.noise
	player = chunk_manager.player
	
	# Connect to chunk unload signal for vegetation cleanup
	if not chunk_manager.chunk_unloaded.is_connected(_on_chunk_unloaded):
		chunk_manager.chunk_unloaded.connect(_on_chunk_unloaded)
	
	initialized = true
	print("VegetationSpawner initialized with player and chunk manager")

func _process(_delta):
	if not initialized or chunk_manager == null or player == null:
		return
	
	# Get player's chunk position
	var player_pos = player.global_position
	var player_chunk = chunk_manager.world_to_chunk(player_pos)
	
	# Populate chunks around player
	for x in range(player_chunk.x - spawn_radius, player_chunk.x + spawn_radius + 1):
		for z in range(player_chunk.y - spawn_radius, player_chunk.y + spawn_radius + 1):
			var chunk_pos = Vector2i(x, z)
			if not populated_chunks.has(chunk_pos) and chunk_manager.chunks.has(chunk_pos):
				populate_chunk(chunk_pos)

func _on_chunk_unloaded(chunk_pos: Vector2i):
	"""Clean up vegetation when a chunk is unloaded
	
	PERFORMANCE: Prevents populated_chunks from growing forever during exploration.
	Frees all vegetation nodes associated with the unloaded chunk.
	"""
	if not populated_chunks.has(chunk_pos):
		return
	
	var vegetation_nodes = populated_chunks[chunk_pos]
	var freed_count = 0
	
	for node in vegetation_nodes:
		if is_instance_valid(node):
			node.queue_free()
			freed_count += 1
	
	populated_chunks.erase(chunk_pos)
	# Debug output (can be removed in production)
	# print("Cleaned up ", freed_count, " vegetation nodes from chunk ", chunk_pos)

func populate_chunk(chunk_pos: Vector2i):
	"""Populate a chunk with vegetation using two-pass system
	
	ALGORITHM:
	Pass 1: Large vegetation (trees, rocks, mushrooms, strawberries)
	  - Sparse samples (15 per chunk default)
	  - Creates harvestable resources with collision
	  - More expensive but fewer instances
	
	Pass 2: Ground cover (grass, flowers)
	  - Dense samples (60 per chunk default)
	  - Grass positions collected for chunk-level MultiMesh (1 draw call)
	  - Clustered using cluster_noise for natural patches
	
	Pass 3: Create chunk grass MultiMesh
	  - All grass for entire chunk in ONE MultiMeshInstance3D
	  - Massive draw call reduction
	
	PERFORMANCE: This runs once per chunk, cached in populated_chunks dictionary
	Vegetation nodes are tracked for cleanup when chunk unloads.
	"""
	if populated_chunks.has(chunk_pos):
		return
	
	# Initialize array to track vegetation nodes for this chunk
	populated_chunks[chunk_pos] = []
	_current_chunk = chunk_pos  # Track for node registration
	_chunk_grass_positions = []  # Reset grass collection for this chunk
	
	var chunk_size = chunk_manager.chunk_size
	var world_offset = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)
	
	# PASS 1: Trees, rocks, and large vegetation
	var samples_per_chunk = large_vegetation_samples_per_chunk
	
	for i in range(samples_per_chunk):
		var local_x = randf() * chunk_size
		var local_z = randf() * chunk_size
		var world_x = world_offset.x + local_x
		var world_z = world_offset.y + local_z
		
		var veg_noise = vegetation_noise.get_noise_2d(world_x, world_z)
		if abs(veg_noise) < 0.3:
			continue
		
		var base_noise = noise.get_noise_2d(world_x, world_z)
		var biome = get_biome_at_position(world_x, world_z, base_noise)
		
		if biome == Chunk.Biome.OCEAN:
			continue
		
		var height = get_terrain_height_with_raycast(world_x, world_z, base_noise, biome)
		
		# Don't spawn vegetation underwater (water level is at y=0.0)
		if height < 0.5:  # Need more margin for larger vegetation
			continue
		
		spawn_large_vegetation_for_biome(biome, Vector3(world_x, height, world_z), world_x, world_z)
	
	# PASS 2: Dense ground cover (grass, flowers)
	# PERFORMANCE: Grass positions collected for chunk MultiMesh, flowers spawn individually
	var ground_cover_samples = ground_cover_samples_per_chunk
	
	for i in range(ground_cover_samples):
		var local_x = randf() * chunk_size
		var local_z = randf() * chunk_size
		var world_x = world_offset.x + local_x
		var world_z = world_offset.y + local_z
		
		var base_noise = noise.get_noise_2d(world_x, world_z)
		var biome = get_biome_at_position(world_x, world_z, base_noise)
		
		# Only spawn ground cover in certain biomes
		if biome == Chunk.Biome.OCEAN:
			continue
		
		# Use cluster noise to create patches
		var cluster_value = cluster_noise.get_noise_2d(world_x, world_z)
		
		# Only spawn in high cluster areas (creates natural patches)
		if cluster_value < 0.0:
			continue
		
		var height = get_terrain_height_with_raycast(world_x, world_z, base_noise, biome)
		
		# Don't spawn ground cover underwater (water level is at y=0.0)
		if height < 0.3:  # Give some margin above water
			continue
		
		spawn_ground_cover_for_biome(biome, Vector3(world_x, height, world_z), world_x, world_z, cluster_value)
	
	# PASS 3: Create chunk-level grass MultiMesh from collected positions
	if _chunk_grass_positions.size() > 0:
		_create_chunk_grass_multimesh(chunk_pos)

func get_terrain_height_with_raycast(world_x: float, world_z: float, base_noise: float, biome: Chunk.Biome) -> float:
	"""Get terrain height with raycast validation - uses calculated height efficiently
	
	OPTIMIZATION: Previous version used wide raycast window (10m up, 2m down)
	- Now uses calculated height to guide narrow window (5m up, 5m down)
	- Faster raycasts = better spawning performance
	- Fallback to calculated height if terrain not loaded yet (chunk streaming)
	
	WHY RAYCAST: Calculated height from noise is approximate
	- Raycasting ensures vegetation sits exactly on terrain mesh
	- Prevents floating or underground vegetation
	"""
	var calculated_height = get_terrain_height_at_position(world_x, world_z, base_noise, biome)
	
	# Use calculated height to guide raycast window (narrower = faster)
	var space_state = get_world_3d().direct_space_state
	var ray_start = Vector3(world_x, calculated_height + 5.0, world_z)  # Reduced from 10.0
	var ray_end = Vector3(world_x, calculated_height - 5.0, world_z)  # Tighter window
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 1  # Only terrain layer
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position.y
	
	# Fallback to calculated if raycast fails (terrain might not be loaded yet)
	return calculated_height

func spawn_large_vegetation_for_biome(biome: Chunk.Biome, spawn_pos: Vector3, _world_x: float, _world_z: float):
	"""Spawn trees, rocks, and other large vegetation"""
	var veg_type: VegType
	var rand = randf()
	
	match biome:
		Chunk.Biome.FOREST:
			# Trees - Oak only (dense, dark forest)
			if rand > (1.0 - tree_density * forest_tree_density):
				veg_type = VegType.TREE
			# Mushrooms - Signature forest resource (increased spawn)
			elif rand > (1.0 - mushroom_density * forest_mushroom_density):
				var mushroom_rand = randf()
				if mushroom_rand > 0.6:
					veg_type = VegType.MUSHROOM_RED
				elif mushroom_rand > 0.3:
					veg_type = VegType.MUSHROOM_BROWN
				else:
					veg_type = VegType.MUSHROOM_CLUSTER
			# Rocks (reduced spawn for forest floor)
			elif rand > (1.0 - rock_density * forest_rock_density):
				var rock_rand = randf()
				if rock_rand > 0.95:  # 5% boulders
					veg_type = VegType.BOULDER
				elif rock_rand > 0.85:  # 10% regular rocks
					veg_type = VegType.ROCK
				else:  # 85% small rocks
					veg_type = VegType.SMALL_ROCK
			else:
				return
		
		Chunk.Biome.GRASSLAND:
			# Trees - Sparse oak trees (open pastoral feel)
			if rand > (1.0 - tree_density * grassland_tree_density):
				veg_type = VegType.TREE
			# Strawberries - Signature grassland resource (increased spawn)
			elif rand > (1.0 - strawberry_density * grassland_strawberry_density):
				var size_rand = randf()
				if size_rand > 0.85:  # 15% large
					veg_type = VegType.STRAWBERRY_BUSH_LARGE
				elif size_rand > 0.30:  # 55% medium
					veg_type = VegType.STRAWBERRY_BUSH_MEDIUM
				else:  # 30% small
					veg_type = VegType.STRAWBERRY_BUSH_SMALL
			# Rocks (high spawn rate, mostly small)
			elif rand > (1.0 - rock_density * grassland_rock_density):
				var rock_rand = randf()
				if rock_rand > 0.92:  # 8% boulders
					veg_type = VegType.BOULDER
				elif rock_rand > 0.80:  # 12% regular rocks
					veg_type = VegType.ROCK
				else:  # 80% small rocks
					veg_type = VegType.SMALL_ROCK
			else:
				return
		
		Chunk.Biome.DESERT:
			# Cactus (uses tree density)
			if rand > (1.0 - tree_density * desert_cactus_density):
				veg_type = VegType.CACTUS
			# Rocks (high spawn rate, mostly small)
			elif rand > (1.0 - rock_density * desert_rock_density):
				var rock_rand = randf()
				if rock_rand > 0.90:  # 10% boulders
					veg_type = VegType.BOULDER
				elif rock_rand > 0.80:  # 10% regular rocks
					veg_type = VegType.ROCK
				else:  # 80% small rocks
					veg_type = VegType.SMALL_ROCK
			else:
				return
		
		Chunk.Biome.MOUNTAIN:
			# Pine trees - Sparse, windswept conifers
			if rand > (1.0 - tree_density * mountain_pine_density):
				veg_type = VegType.PINE_TREE
			# Boulders and rocks (abundant - mountain biome)
			elif rand > (1.0 - rock_density * mountain_rock_density):
				var rock_rand = randf()
				if rock_rand > (1.0 - mountain_boulder_ratio):  # Configurable boulder ratio
					veg_type = VegType.BOULDER
				elif rock_rand > 0.25:  # Regular rocks
					veg_type = VegType.ROCK
				else:  # Small rocks
					veg_type = VegType.SMALL_ROCK
			else:
				return
		
		Chunk.Biome.SNOW:
			# Pine trees
			if rand > (1.0 - tree_density * snow_pine_density):
				veg_type = VegType.PINE_TREE
			# Rocks (high spawn rate, mostly small)
			elif rand > (1.0 - rock_density * snow_rock_density):
				var rock_rand = randf()
				if rock_rand > 0.88:  # 12% boulders
					veg_type = VegType.BOULDER
				elif rock_rand > 0.80:  # 8% regular rocks
					veg_type = VegType.ROCK
				else:  # 80% small rocks
					veg_type = VegType.SMALL_ROCK
			else:
				return
		
		Chunk.Biome.BEACH:
			# Palm trees
			if rand > (1.0 - tree_density * beach_palm_density):
				veg_type = VegType.PALM_TREE
			# Rocks (high spawn rate, mostly small)
			elif rand > (1.0 - rock_density * beach_rock_density):
				var rock_rand = randf()
				if rock_rand > 0.75:  # Only 25% regular rocks
					veg_type = VegType.ROCK
				else:
					veg_type = VegType.SMALL_ROCK
			else:
				return
		
		_:
			return
	
	create_vegetation_mesh(veg_type, spawn_pos)
	
	# Rock clustering: spawn 1-3 additional rocks nearby if we spawned a rock
	if veg_type == VegType.ROCK or veg_type == VegType.SMALL_ROCK:
		var cluster_count = randi() % 3  # 0-2 additional rocks
		for i in range(cluster_count):
			# Spawn nearby (within 1-3 meters)
			var offset_angle = randf() * TAU
			var offset_dist = 1.0 + randf() * 2.0  # 1-3 meters away
			var cluster_pos = spawn_pos + Vector3(
				cos(offset_angle) * offset_dist,
				0,
				sin(offset_angle) * offset_dist
			)
			
			# Raycast to get actual terrain height at cluster position
			var space_state = get_world_3d().direct_space_state
			var ray_start = Vector3(cluster_pos.x, spawn_pos.y + 5.0, cluster_pos.z)
			var ray_end = Vector3(cluster_pos.x, spawn_pos.y - 5.0, cluster_pos.z)
			var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
			query.collision_mask = 1
			var result = space_state.intersect_ray(query)
			if result:
				cluster_pos.y = result.position.y
			
			# Randomly choose rock size for cluster (mostly small)
			var cluster_type = VegType.SMALL_ROCK if randf() > 0.20 else VegType.ROCK  # 80% small rocks
			create_vegetation_mesh(cluster_type, cluster_pos)

func spawn_ground_cover_for_biome(biome: Chunk.Biome, spawn_pos: Vector3, _world_x: float, _world_z: float, cluster_value: float):
	"""Spawn grass, flowers, and ground cover - dense and varied
	
	OPTIMIZATION: Grass types (GRASS_TUFT, GRASS_PATCH) are collected into 
	_chunk_grass_positions for chunk-level MultiMesh instead of spawning individually.
	Other ground cover (flowers, mushrooms) still spawn as individual meshes.
	"""
	var veg_type: VegType
	var rand = randf()
	
	match biome:
		Chunk.Biome.GRASSLAND:
			# Flowers
			if rand > (1.0 - flower_density):
				var flower_rand = randf()
				if flower_rand > 0.66:
					veg_type = VegType.WILDFLOWER_YELLOW
				elif flower_rand > 0.33:
					veg_type = VegType.WILDFLOWER_PURPLE
				else:
					veg_type = VegType.WILDFLOWER_WHITE
			# Grass (check density) - COLLECT FOR MULTIMESH
			elif rand < grass_density:
				var is_dense = cluster_value > 0.3
				_chunk_grass_positions.append({"pos": spawn_pos, "dense": is_dense})
				return  # Don't spawn individually
			else:
				return
		
		Chunk.Biome.FOREST:
			# Mushrooms on forest floor (use mushroom_density)
			if rand > (1.0 - mushroom_density * 0.3):
				var mushroom_rand = randf()
				if mushroom_rand > 0.5:
					veg_type = VegType.MUSHROOM_BROWN
				else:
					veg_type = VegType.MUSHROOM_CLUSTER
			# Grass (less dense in forest, check grass_density) - COLLECT FOR MULTIMESH
			elif rand < grass_density * 0.5:
				var is_dense = cluster_value > 0.2
				_chunk_grass_positions.append({"pos": spawn_pos, "dense": is_dense})
				return  # Don't spawn individually
			else:
				return
		
		Chunk.Biome.BEACH:
			# Sparse beach grass (check grass_density) - COLLECT FOR MULTIMESH
			if rand < grass_density * 0.4:
				_chunk_grass_positions.append({"pos": spawn_pos, "dense": false})
				return  # Don't spawn individually
			else:
				return
		
		_:
			return
	
	create_vegetation_mesh(veg_type, spawn_pos)

func _create_chunk_grass_multimesh(chunk_pos: Vector2i):
	"""Create a single MultiMeshInstance3D for ALL grass in this chunk
	
	PERFORMANCE: Instead of 100+ individual grass nodes, this creates ONE draw call
	for all grass in the chunk. Each grass position gets multiple blade instances.
	"""
	var grass_count = _chunk_grass_positions.size()
	if grass_count == 0:
		return
	
	# Calculate total blade instances (each position gets 3-7 blades)
	var blades_per_tuft_min = 3
	var blades_per_tuft_max = 7
	var total_blades = 0
	var blade_counts = []
	
	for grass_data in _chunk_grass_positions:
		var blade_count = blades_per_tuft_min + randi() % (blades_per_tuft_max - blades_per_tuft_min + 1)
		if grass_data["dense"]:
			blade_count += 2  # Dense patches get more blades
		blade_counts.append(blade_count)
		total_blades += blade_count
	
	# Create MultiMeshInstance3D first so we can position it
	var multi_mesh_instance = MultiMeshInstance3D.new()
	add_child(multi_mesh_instance)
	
	# Position the MultiMeshInstance3D at world origin - transforms will be in world space
	multi_mesh_instance.global_position = Vector3.ZERO
	
	# Create MultiMesh
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.use_colors = true
	multi_mesh.instance_count = total_blades
	multi_mesh.mesh = _get_cached_grass_blade_mesh()
	
	# Position each blade instance (using world coordinates since parent is at origin)
	var instance_idx = 0
	for i in range(grass_count):
		var grass_data = _chunk_grass_positions[i]
		var base_pos: Vector3 = grass_data["pos"]
		var blade_count = blade_counts[i]
		
		for j in range(blade_count):
			# Random offset within small cluster
			var offset_angle = randf() * TAU
			var offset_dist = randf() * 0.15
			var blade_x = base_pos.x + cos(offset_angle) * offset_dist
			var blade_z = base_pos.z + sin(offset_angle) * offset_dist
			
			# Build transform: start with identity, then apply transformations
			var transform = Transform3D.IDENTITY
			
			# Random rotation around Y axis
			var rot_y = randf() * TAU
			transform = transform.rotated(Vector3.UP, rot_y)
			
			# Slight random lean for natural look
			var lean_angle = (randf() - 0.5) * 0.25
			var lean_dir = randf() * TAU
			transform = transform.rotated(Vector3(cos(lean_dir), 0, sin(lean_dir)), lean_angle)
			
			# Random scale variation
			var scale = 0.8 + randf() * 0.5
			transform = transform.scaled(Vector3(scale, scale * (0.85 + randf() * 0.3), scale))
			
			# Set position AFTER rotation/scale (world position)
			transform.origin = Vector3(blade_x, base_pos.y, blade_z)
			
			multi_mesh.set_instance_transform(instance_idx, transform)
			
			# Color variation
			var color_rand = randf()
			var grass_tint: Color
			if color_rand > 0.7:
				grass_tint = Color(0.95, 1.05, 0.9)  # Yellow-green
			elif color_rand > 0.4:
				grass_tint = Color(1.0, 1.0, 1.0)    # Standard
			else:
				grass_tint = Color(0.85, 0.95, 0.8)  # Darker
			
			multi_mesh.set_instance_color(instance_idx, grass_tint)
			instance_idx += 1
	
	multi_mesh_instance.multimesh = multi_mesh
	
	# Material with vertex colors
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.8
	multi_mesh_instance.material_override = material
	
	# Track for cleanup
	if populated_chunks.has(chunk_pos):
		populated_chunks[chunk_pos].append(multi_mesh_instance)

# Cached grass blade mesh (created once, reused)
var _cached_grass_blade_mesh: ArrayMesh = null

func _get_cached_grass_blade_mesh() -> ArrayMesh:
	"""Get or create cached grass blade mesh"""
	if _cached_grass_blade_mesh == null:
		_cached_grass_blade_mesh = _create_grass_blade_mesh()
	return _cached_grass_blade_mesh

func _create_grass_blade_mesh() -> ArrayMesh:
	"""Create a single grass blade mesh for MultiMesh instances"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Blade dimensions
	var height = 0.5
	var width_base = 0.08
	var width_tip = 0.02
	var segments = 3
	
	# Color gradient
	var base_color = Color(0.25, 0.45, 0.15, 1.0)
	var tip_color = Color(0.45, 0.75, 0.35, 1.0)
	
	for seg in range(segments):
		var t1 = float(seg) / segments
		var t2 = float(seg + 1) / segments
		
		var y1 = t1 * height
		var y2 = t2 * height
		var w1 = lerp(width_base, width_tip, t1)
		var w2 = lerp(width_base, width_tip, t2)
		var curve1 = t1 * t1 * 0.1
		var curve2 = t2 * t2 * 0.1
		
		var color1 = base_color.lerp(tip_color, t1)
		var color2 = base_color.lerp(tip_color, t2)
		
		var p1_left = Vector3(-w1/2, y1, curve1)
		var p1_right = Vector3(w1/2, y1, curve1)
		var p2_left = Vector3(-w2/2, y2, curve2)
		var p2_right = Vector3(w2/2, y2, curve2)
		
		# Front face
		surface_tool.set_color(color1)
		surface_tool.add_vertex(p1_left)
		surface_tool.add_vertex(p1_right)
		surface_tool.set_color(color2)
		surface_tool.add_vertex(p2_left)
		
		surface_tool.set_color(color1)
		surface_tool.add_vertex(p1_right)
		surface_tool.set_color(color2)
		surface_tool.add_vertex(p2_right)
		surface_tool.add_vertex(p2_left)
		
		# Back face
		surface_tool.set_color(color1)
		surface_tool.add_vertex(p1_right)
		surface_tool.add_vertex(p1_left)
		surface_tool.set_color(color2)
		surface_tool.add_vertex(p2_left)
		
		surface_tool.set_color(color2)
		surface_tool.add_vertex(p2_right)
		surface_tool.set_color(color1)
		surface_tool.add_vertex(p1_right)
		surface_tool.set_color(color2)
		surface_tool.add_vertex(p2_left)
	
	surface_tool.generate_normals()
	return surface_tool.commit()

func get_biome_at_position(world_x: float, world_z: float, base_noise: float) -> Chunk.Biome:
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

func get_terrain_height_at_position(_world_x: float, _world_z: float, base_noise: float, biome: Chunk.Biome) -> float:
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

func create_vegetation_mesh(veg_type: VegType, spawn_position: Vector3):
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	mesh_instance.global_position = spawn_position
	
	# Track this node for cleanup when chunk unloads
	if populated_chunks.has(_current_chunk):
		populated_chunks[_current_chunk].append(mesh_instance)
	
	# Set visibility range for automatic distance culling (GPU optimization)
	# Small objects fade out sooner, large objects visible longer
	var visibility_end: float = 80.0  # Default
	var visibility_margin: float = 10.0
	
	match veg_type:
		VegType.TREE, VegType.PINE_TREE, VegType.PALM_TREE:
			visibility_end = 120.0  # Trees visible far
			visibility_margin = 20.0
		VegType.BOULDER:
			visibility_end = 100.0
			visibility_margin = 15.0
		VegType.ROCK:
			visibility_end = 60.0
			visibility_margin = 10.0
		VegType.SMALL_ROCK:
			visibility_end = 40.0  # Small rocks fade first
			visibility_margin = 8.0
		VegType.CACTUS:
			visibility_end = 80.0
			visibility_margin = 10.0
		VegType.MUSHROOM_RED, VegType.MUSHROOM_BROWN, VegType.MUSHROOM_CLUSTER:
			visibility_end = 50.0
			visibility_margin = 8.0
		VegType.WILDFLOWER_YELLOW, VegType.WILDFLOWER_PURPLE, VegType.WILDFLOWER_WHITE:
			visibility_end = 35.0  # Flowers fade early
			visibility_margin = 5.0
		VegType.STRAWBERRY_BUSH_SMALL:
			visibility_end = 45.0
			visibility_margin = 8.0
		VegType.STRAWBERRY_BUSH_MEDIUM, VegType.STRAWBERRY_BUSH_LARGE:
			visibility_end = 55.0
			visibility_margin = 10.0
		_:
			visibility_end = 60.0
			visibility_margin = 10.0
	
	# Apply visibility range (Godot auto-culls based on camera distance)
	mesh_instance.visibility_range_end = visibility_end
	mesh_instance.visibility_range_end_margin = visibility_margin
	mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	
	match veg_type:
		VegType.TREE:
			create_tree(mesh_instance)
		VegType.PINE_TREE:
			create_pine_tree(mesh_instance)
		VegType.PALM_TREE:
			create_palm_tree(mesh_instance)
		VegType.ROCK:
			create_rock(mesh_instance, false)
		VegType.SMALL_ROCK:
			create_small_rock(mesh_instance)
		VegType.BOULDER:
			create_rock(mesh_instance, true)
		VegType.CACTUS:
			create_cactus(mesh_instance)
		# GRASS_TUFT and GRASS_PATCH now handled by chunk-level MultiMesh
		# See _create_chunk_grass_multimesh() - these cases should not be reached
		VegType.GRASS_TUFT, VegType.GRASS_PATCH:
			push_warning("Grass should use chunk MultiMesh, not individual spawn")
			pass
		VegType.MUSHROOM_RED:
			create_harvestable_mushroom(mesh_instance, true, false)
		VegType.MUSHROOM_BROWN:
			create_harvestable_mushroom(mesh_instance, false, false)
		VegType.MUSHROOM_CLUSTER:
			create_harvestable_mushroom(mesh_instance, false, true)
		VegType.WILDFLOWER_YELLOW:
			create_wildflower(mesh_instance, Color(1.0, 0.9, 0.2))
		VegType.WILDFLOWER_PURPLE:
			create_wildflower(mesh_instance, Color(0.7, 0.3, 0.8))
		VegType.WILDFLOWER_WHITE:
			create_wildflower(mesh_instance, Color(0.95, 0.95, 1.0))
		VegType.STRAWBERRY_BUSH_SMALL:
			create_harvestable_strawberry(mesh_instance, HarvestableStrawberry.BushSize.SMALL)
		VegType.STRAWBERRY_BUSH_MEDIUM:
			create_harvestable_strawberry(mesh_instance, HarvestableStrawberry.BushSize.MEDIUM)
		VegType.STRAWBERRY_BUSH_LARGE:
			create_harvestable_strawberry(mesh_instance, HarvestableStrawberry.BushSize.LARGE)

func create_grass_tuft_improved(mesh_instance: MeshInstance3D):
	"""Improved 3D grass blades using MultiMesh for better performance"""
	# Create a MultiMeshInstance3D for multiple grass blades
	var multi_mesh_instance = MultiMeshInstance3D.new()
	mesh_instance.add_child(multi_mesh_instance)
	
	var blade_count = 5 + randi() % 5  # 5-9 blades per tuft (was 3-6)
	
	# Create the MultiMesh
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.use_colors = true  # Enable color support
	multi_mesh.instance_count = blade_count
	
	# Create a single 3D curved grass blade mesh
	var blade_mesh = create_3d_grass_blade()
	multi_mesh.mesh = blade_mesh
	
	# Position each blade instance
	for i in range(blade_count):
		var transform = Transform3D()
		
		# Random position in small cluster - wider spread
		var offset_angle = randf() * TAU
		var offset_dist = randf() * 0.12  # Wider cluster (was 0.08)
		transform.origin = Vector3(
			cos(offset_angle) * offset_dist,
			0,
			sin(offset_angle) * offset_dist
		)
		
		# Random rotation
		transform = transform.rotated(Vector3.UP, randf() * TAU)
		
		# Slight random lean
		var lean_angle = (randf() - 0.5) * 0.2
		var lean_dir = randf() * TAU
		transform = transform.rotated(Vector3(cos(lean_dir), 0, sin(lean_dir)), lean_angle)
		
		# Random scale variation - larger overall
		var scale = 1.0 + randf() * 0.5  # 1.0-1.5x scale (was 0.8-1.2x)
		transform = transform.scaled(Vector3(scale, scale * (0.9 + randf() * 0.2), scale))
		
		multi_mesh.set_instance_transform(i, transform)
		
		# Random color variation per blade - subtle green tint variations
		var green_variation = randf()
		var grass_tint: Color
		if green_variation > 0.7:
			grass_tint = Color(0.95, 1.05, 0.9)  # Slightly yellow-green tint
		elif green_variation > 0.4:
			grass_tint = Color(1.0, 1.0, 1.0)  # No tint (standard green)
		else:
			grass_tint = Color(0.9, 0.95, 0.85)  # Slightly darker tint
		
		multi_mesh.set_instance_color(i, grass_tint)
	
	multi_mesh_instance.multimesh = multi_mesh
	
	# Material
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.8
	multi_mesh_instance.material_override = material

func create_3d_grass_blade() -> ArrayMesh:
	"""Create a single 3D curved grass blade mesh"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Blade dimensions - made larger for better visibility
	var height = 0.65  # Taller blades (was 0.4)
	var width_base = 0.12  # Wider at base (was 0.08)
	var width_tip = 0.03  # Wider tip (was 0.02)
	var segments = 4  # More segments = smoother curve
	
	# Color gradient - proper grass green colors
	var base_color = Color(0.25, 0.45, 0.15, 1.0)  # Dark green at base
	var tip_color = Color(0.45, 0.75, 0.35, 1.0)   # Bright green at tip
	
	# Create curved blade with multiple segments
	for seg in range(segments):
		var t1 = float(seg) / segments
		var t2 = float(seg + 1) / segments
		
		# Height with curve
		var y1 = t1 * height
		var y2 = t2 * height
		
		# Width tapering
		var w1 = lerp(width_base, width_tip, t1)
		var w2 = lerp(width_base, width_tip, t2)
		
		# Forward curve (grass bends slightly)
		var curve1 = t1 * t1 * 0.15  # Quadratic curve
		var curve2 = t2 * t2 * 0.15
		
		# Color interpolation
		var color1 = base_color.lerp(tip_color, t1)
		var color2 = base_color.lerp(tip_color, t2)
		
		# Four corners of this segment
		var p1_left = Vector3(-w1/2, y1, curve1)
		var p1_right = Vector3(w1/2, y1, curve1)
		var p2_left = Vector3(-w2/2, y2, curve2)
		var p2_right = Vector3(w2/2, y2, curve2)
		
		# Front face quad (as two triangles)
		surface_tool.set_color(color1)
		surface_tool.add_vertex(p1_left)
		surface_tool.add_vertex(p1_right)
		surface_tool.set_color(color2)
		surface_tool.add_vertex(p2_left)
		
		surface_tool.set_color(color1)
		surface_tool.add_vertex(p1_right)
		surface_tool.set_color(color2)
		surface_tool.add_vertex(p2_right)
		surface_tool.add_vertex(p2_left)
		
		# Back face (for double-sided visibility)
		surface_tool.set_color(color1)
		surface_tool.add_vertex(p1_right)
		surface_tool.add_vertex(p1_left)
		surface_tool.set_color(color2)
		surface_tool.add_vertex(p2_left)
		
		surface_tool.set_color(color2)
		surface_tool.add_vertex(p2_right)
		surface_tool.set_color(color1)
		surface_tool.add_vertex(p1_right)
		surface_tool.set_color(color2)
		surface_tool.add_vertex(p2_left)
	
	surface_tool.generate_normals()
	return surface_tool.commit()

func create_grass_patch(mesh_instance: MeshInstance3D):
	"""Create a small cluster of grass blades"""
	# Create multiple grass blades in a small area
	var blade_count = 5 + randi() % 5  # 5-9 blades
	
	for i in range(blade_count):
		var blade = MeshInstance3D.new()
		mesh_instance.add_child(blade)
		
		# Random offset within patch (0.3m radius)
		var offset_angle = randf() * TAU
		var offset_dist = randf() * 0.3
		var offset_x = cos(offset_angle) * offset_dist
		var offset_z = sin(offset_angle) * offset_dist
		
		blade.position = Vector3(offset_x, 0, offset_z)
		blade.rotation.y = randf() * TAU
		
		# Create individual grass blade
		create_grass_blade_simple(blade)

func create_grass_blade_simple(mesh_instance: MeshInstance3D):
	"""Simple single grass blade for use in patches"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var height = 0.25 + randf() * 0.35
	var width = 0.1 + randf() * 0.08
	
	# Color variation
	var green_var = randf()
	var grass_color: Color
	if green_var > 0.6:
		grass_color = Color(0.5, 0.8, 0.3)
	else:
		grass_color = Color(0.3, 0.7, 0.25)
	
	var base_color = grass_color * 0.6
	var tip_color = grass_color * 1.3
	
	# Single plane
	var p1 = Vector3(-width/2, 0, 0)
	var p2 = Vector3(width/2, 0, 0)
	var p3 = Vector3(-width/3, height, 0)
	var p4 = Vector3(width/3, height, 0)
	
	# Front
	surface_tool.set_color(base_color)
	surface_tool.add_vertex(p1)
	surface_tool.add_vertex(p2)
	surface_tool.set_color(tip_color)
	surface_tool.add_vertex(p3)
	
	surface_tool.set_color(base_color)
	surface_tool.add_vertex(p2)
	surface_tool.set_color(tip_color)
	surface_tool.add_vertex(p4)
	surface_tool.add_vertex(p3)
	
	# Back
	surface_tool.set_color(base_color)
	surface_tool.add_vertex(p2)
	surface_tool.add_vertex(p1)
	surface_tool.set_color(tip_color)
	surface_tool.add_vertex(p3)
	
	surface_tool.set_color(tip_color)
	surface_tool.add_vertex(p4)
	surface_tool.set_color(base_color)
	surface_tool.add_vertex(p2)
	surface_tool.set_color(tip_color)
	surface_tool.add_vertex(p3)
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.7
	mesh.surface_set_material(0, material)
	
	mesh_instance.mesh = mesh

func create_wildflower(mesh_instance: MeshInstance3D, color: Color):
	"""Create a small wildflower"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Stem
	var stem_height = 0.15 + randf() * 0.15
	var stem_color = Color(0.3, 0.6, 0.2)
	
	var stem_width = 0.02
	surface_tool.set_color(stem_color)
	surface_tool.add_vertex(Vector3(-stem_width, 0, 0))
	surface_tool.add_vertex(Vector3(stem_width, 0, 0))
	surface_tool.add_vertex(Vector3(0, stem_height, 0))
	
	# Flower petals (simple star shape)
	var petal_count = 5
	var petal_size = 0.05 + randf() * 0.03
	var flower_y = stem_height
	
	for i in range(petal_count):
		var angle1 = (i / float(petal_count)) * TAU
		var angle2 = ((i + 1) / float(petal_count)) * TAU
		
		var x1 = cos(angle1) * petal_size
		var z1 = sin(angle1) * petal_size
		var x2 = cos(angle2) * petal_size
		var z2 = sin(angle2) * petal_size
		
		# Petal triangle
		surface_tool.set_color(color)
		surface_tool.add_vertex(Vector3(0, flower_y, 0))  # Center
		surface_tool.add_vertex(Vector3(x1, flower_y, z1))
		surface_tool.add_vertex(Vector3(x2, flower_y, z2))
	
	# Center of flower (darker)
	var center_color = color * 0.5
	var center_size = petal_size * 0.3
	for i in range(6):
		var angle1 = (i / 6.0) * TAU
		var angle2 = ((i + 1) / 6.0) * TAU
		
		var x1 = cos(angle1) * center_size
		var z1 = sin(angle1) * center_size
		var x2 = cos(angle2) * center_size
		var z2 = sin(angle2) * center_size
		
		surface_tool.set_color(center_color)
		surface_tool.add_vertex(Vector3(0, flower_y + 0.01, 0))
		surface_tool.add_vertex(Vector3(x1, flower_y + 0.01, z1))
		surface_tool.add_vertex(Vector3(x2, flower_y + 0.01, z2))
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.5
	mesh.surface_set_material(0, material)
	
	mesh_instance.mesh = mesh
	mesh_instance.rotation.y = randf() * TAU

# [Rest of the original functions remain the same]
# Keep all the tree, rock, cactus, mushroom functions from the original file

func create_tree(mesh_instance: MeshInstance3D):
	"""Create a harvestable tree - delegates to TreeVisual generator"""
	TreeVisual.create(mesh_instance, self)

func create_pine_tree(mesh_instance: MeshInstance3D):
	"""Create a harvestable pine tree - delegates to PineTreeVisual generator"""
	PineTreeVisual.create(mesh_instance, self)

func create_palm_tree(mesh_instance: MeshInstance3D):
	"""Create a harvestable palm tree - delegates to PalmTreeVisual generator"""
	PalmTreeVisual.create(mesh_instance, self)

func create_rock(mesh_instance: MeshInstance3D, is_boulder: bool):
	var size = 0.7 + randf() * 0.5 if not is_boulder else 1.4 + randf() * 1.0  # Regular: 0.7-1.2m (was 0.6-1.0m), Boulder: 1.4-2.4m (was 1.2-2.0m)
	
	var parent = mesh_instance.get_parent()
	var rock_position = mesh_instance.global_position
	
	var resource_node = ResourceNodeClass.new()
	# Set node_type BEFORE adding to tree so _ready() configures glow properly
	resource_node.node_type = ResourceNodeClass.NodeType.ROCK
	
	# Override properties for boulders vs regular rocks (do this before _ready())
	if is_boulder:
		resource_node.resource_name = "Boulder"
		resource_node.harvest_time = 3.0
		resource_node.drop_amount_min = 6
		resource_node.drop_amount_max = 10
		resource_node.max_health = 100.0
		resource_node.current_health = 100.0
	# Regular rocks already configured correctly by node_type
	
	resource_node.collision_layer = 2
	resource_node.collision_mask = 0
	
	# Create and add rock_mesh BEFORE adding to tree
	# This is critical - _ready() needs to find the mesh to setup glow
	var rock_mesh = MeshInstance3D.new()
	resource_node.add_child(rock_mesh)
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = size / 2
	sphere_mesh.height = size
	sphere_mesh.radial_segments = 8
	sphere_mesh.rings = 6
	
	# Pixelated stone texture with color variation
	var stone_texture = PixelTextureGenerator.create_stone_texture()
	var stone_tint = Color(0.9 + randf() * 0.2, 0.9 + randf() * 0.2, 0.9 + randf() * 0.2)
	var material = PixelTextureGenerator.create_pixel_material(stone_texture, stone_tint)
	
	# CRITICAL: Duplicate material so each rock has its own instance for glow modification
	material = material.duplicate()
	
	rock_mesh.mesh = sphere_mesh
	# CRITICAL FIX: Use set_surface_override_material instead of sphere_mesh.material
	# This allows the glow system to find and modify the material correctly
	rock_mesh.set_surface_override_material(0, material)
	
	rock_mesh.rotation.x = (randf() - 0.5) * 0.3
	rock_mesh.rotation.z = (randf() - 0.5) * 0.3
	rock_mesh.scale = Vector3(1.0, 0.6, 0.9)
	
	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = size / 2
	collision.shape = shape
	resource_node.add_child(collision)
	
	# NOW add to tree (triggers _ready() which will find rock_mesh and setup glow)
	parent.remove_child(mesh_instance)
	parent.add_child(resource_node)
	resource_node.global_position = rock_position
	
	# Register replacement node for chunk cleanup (mesh_instance will be freed)
	if populated_chunks.has(_current_chunk):
		populated_chunks[_current_chunk].append(resource_node)
	
	mesh_instance.queue_free()

func create_small_rock(mesh_instance: MeshInstance3D):
	"""Create a small harvestable rock (1/3 size of regular rock, gives 1 stone)"""
	var size = 0.4 + randf() * 0.2  # 0.4-0.6m (knee-height sized rocks)
	
	var parent = mesh_instance.get_parent()
	var rock_position = mesh_instance.global_position
	
	var resource_node = ResourceNodeClass.new()
	# Set node_type BEFORE adding to tree so _ready() configures glow properly
	resource_node.node_type = ResourceNodeClass.NodeType.ROCK
	
	# Override properties for small rocks (do this before _ready())
	resource_node.resource_name = "Small Rock"
	resource_node.harvest_time = 1.0
	resource_node.drop_amount_min = 1
	resource_node.drop_amount_max = 1
	resource_node.max_health = 30.0
	resource_node.current_health = 30.0
	
	resource_node.collision_layer = 2
	resource_node.collision_mask = 0
	
	# Create and add rock_mesh BEFORE adding to tree
	# This is critical - _ready() needs to find the mesh to setup glow
	var rock_mesh = MeshInstance3D.new()
	resource_node.add_child(rock_mesh)
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = size / 2
	sphere_mesh.height = size
	sphere_mesh.radial_segments = 8
	sphere_mesh.rings = 6
	
	# Pixelated stone texture with color variation
	var stone_texture = PixelTextureGenerator.create_stone_texture()
	var stone_tint = Color(0.9 + randf() * 0.2, 0.9 + randf() * 0.2, 0.9 + randf() * 0.2)
	var material = PixelTextureGenerator.create_pixel_material(stone_texture, stone_tint)
	
	# CRITICAL: Duplicate material so each rock has its own instance for glow modification
	material = material.duplicate()
	
	rock_mesh.mesh = sphere_mesh
	# CRITICAL FIX: Use set_surface_override_material instead of sphere_mesh.material
	# This allows the glow system to find and modify the material correctly
	rock_mesh.set_surface_override_material(0, material)
	
	rock_mesh.rotation.x = (randf() - 0.5) * 0.3
	rock_mesh.rotation.z = (randf() - 0.5) * 0.3
	rock_mesh.scale = Vector3(1.0, 0.6, 0.9)
	
	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = size / 2
	collision.shape = shape
	resource_node.add_child(collision)
	
	# NOW add to tree (triggers _ready() which will find rock_mesh and setup glow)
	parent.remove_child(mesh_instance)
	parent.add_child(resource_node)
	resource_node.global_position = rock_position
	
	# Register replacement node for chunk cleanup (mesh_instance will be freed)
	if populated_chunks.has(_current_chunk):
		populated_chunks[_current_chunk].append(resource_node)
	
	mesh_instance.queue_free()

func create_cactus(mesh_instance: MeshInstance3D):
	"""Create a more detailed cactus with arms"""
	var main_height = 1.5 + randf() * 1.0  # 1.5-2.5m tall
	var main_radius = 0.25
	
	# Main trunk
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.height = main_height
	trunk_mesh.top_radius = main_radius * 0.9  # Slightly narrower at top
	trunk_mesh.bottom_radius = main_radius
	trunk_mesh.radial_segments = 8  # Octagonal for that chunky look
	
	mesh_instance.mesh = trunk_mesh
	# Lift the mesh so the bottom sits on the ground (cylinder is centered at origin)
	mesh_instance.position.y += main_height / 2
	
	# Pixelated grass texture tinted yellow-green for desert cactus
	var grass_texture = PixelTextureGenerator.create_grass_texture()
	var material = PixelTextureGenerator.create_pixel_material(grass_texture, Color(0.8, 1.1, 0.5))
	mesh_instance.set_surface_override_material(0, material)
	
	# Add 1-3 cactus arms
	var arm_count = 1 + randi() % 3  # 1, 2, or 3 arms
	
	for i in range(arm_count):
		var arm = MeshInstance3D.new()
		mesh_instance.add_child(arm)
		
		# Arm dimensions (smaller than main trunk)
		var arm_height = main_height * (0.3 + randf() * 0.3)  # 30-60% of main height
		var arm_radius = main_radius * 0.7
		
		# Create vertical arm
		var arm_mesh = CylinderMesh.new()
		arm_mesh.height = arm_height
		arm_mesh.top_radius = arm_radius * 0.8
		arm_mesh.bottom_radius = arm_radius
		arm_mesh.radial_segments = 8
		arm.mesh = arm_mesh
		
		# Position arm partway up the main trunk (relative to mesh_instance which is at main_height/2)
		var arm_attach_height = main_height * (0.4 + randf() * 0.3)  # 40-70% up from base
		
		# Horizontal extension from trunk
		var side = 1 if i % 2 == 0 else -1  # Alternate sides
		var horizontal_offset = main_radius + arm_radius + 0.1
		arm.position.x = side * horizontal_offset
		arm.position.y = arm_attach_height - main_height / 2 + arm_height / 2  # Position vertically
		
		# Create the horizontal connecting piece
		var connector = MeshInstance3D.new()
		mesh_instance.add_child(connector)
		
		var connector_mesh = CylinderMesh.new()
		connector_mesh.height = horizontal_offset
		connector_mesh.top_radius = arm_radius * 0.9
		connector_mesh.bottom_radius = arm_radius * 0.9
		connector_mesh.radial_segments = 8
		connector.mesh = connector_mesh
		
		# Rotate to horizontal and position
		connector.rotation.z = PI / 2  # Horizontal
		connector.position.y = arm_attach_height - main_height / 2
		connector.position.x = side * horizontal_offset / 2
		
		# Apply same material to arms
		arm.set_surface_override_material(0, material)
		connector.set_surface_override_material(0, material)

func create_harvestable_mushroom(mesh_instance: MeshInstance3D, is_red: bool, is_cluster: bool):
	"""Create a harvestable mushroom that can be harvested for items"""
	var parent = mesh_instance.get_parent()
	var mushroom_position = mesh_instance.global_position
	
	# Create the harvestable mushroom node
	var mushroom = HarvestableMushroomClass.new()
	
	# Set mushroom type
	if is_cluster:
		mushroom.mushroom_type = HarvestableMushroomClass.MushroomType.CLUSTER
	elif is_red:
		mushroom.mushroom_type = HarvestableMushroomClass.MushroomType.RED
	else:
		mushroom.mushroom_type = HarvestableMushroomClass.MushroomType.BROWN
	
	# Set collision for harvesting
	mushroom.collision_layer = 2
	mushroom.collision_mask = 0
	
	# Create the visual mesh
	if is_cluster:
		# Create cluster of small mushrooms
		var cluster_count = 3 + randi() % 3
		for i in range(cluster_count):
			var small_mushroom = MeshInstance3D.new()
			mushroom.add_child(small_mushroom)
			
			var offset_x = (randf() - 0.5) * 0.3
			var offset_z = (randf() - 0.5) * 0.3
			small_mushroom.position = Vector3(offset_x, 0, offset_z)
			
			create_single_mushroom(small_mushroom, false, 0.15 + randf() * 0.1)
	else:
		# Create single mushroom
		var mushroom_mesh = MeshInstance3D.new()
		mushroom.add_child(mushroom_mesh)
		
		var size = 0.2 + randf() * 0.15
		create_single_mushroom(mushroom_mesh, is_red, size)
	
	# Add collision shape for the mushroom
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	
	# Size based on type
	if is_cluster:
		shape.radius = 0.3
		shape.height = 0.3
	else:
		var size = 0.2 + randf() * 0.15
		shape.radius = size * 0.8
		shape.height = size * 2.0
	
	collision.shape = shape
	collision.position.y = shape.height / 2
	mushroom.add_child(collision)
	
	# Replace mesh_instance with mushroom in scene
	parent.remove_child(mesh_instance)
	parent.add_child(mushroom)
	mushroom.global_position = mushroom_position
	
	# Register replacement node for chunk cleanup (mesh_instance will be freed)
	if populated_chunks.has(_current_chunk):
		populated_chunks[_current_chunk].append(mushroom)
	
	mesh_instance.queue_free()


func create_single_mushroom(mesh_instance: MeshInstance3D, is_red: bool, size: float):
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var stem_height = size * 1.5
	var stem_radius = size * 0.15
	var cap_radius = size * 0.8
	var cap_height = size * 0.5
	
	var stem_color = Color(0.9, 0.85, 0.75)
	var cap_color = Color(0.8, 0.15, 0.1) if is_red else Color(0.5, 0.35, 0.25)
	
	var sides = 8
	
	# Stem
	for i in range(sides):
		var angle1 = (i / float(sides)) * TAU
		var angle2 = ((i + 1) / float(sides)) * TAU
		
		var x1 = cos(angle1) * stem_radius
		var z1 = sin(angle1) * stem_radius
		var x2 = cos(angle2) * stem_radius
		var z2 = sin(angle2) * stem_radius
		
		surface_tool.set_color(stem_color)
		surface_tool.add_vertex(Vector3(x1, 0, z1))
		surface_tool.add_vertex(Vector3(x2, 0, z2))
		surface_tool.add_vertex(Vector3(x1, stem_height, z1))
		
		surface_tool.add_vertex(Vector3(x2, 0, z2))
		surface_tool.add_vertex(Vector3(x2, stem_height, z2))
		surface_tool.add_vertex(Vector3(x1, stem_height, z1))
	
	# Cap
	var cap_base_y = stem_height
	var cap_segments = 5
	
	for segment in range(cap_segments):
		var t1 = segment / float(cap_segments)
		var t2 = (segment + 1) / float(cap_segments)
		
		var radius1 = cap_radius * sin(t1 * PI * 0.5)
		var radius2 = cap_radius * sin(t2 * PI * 0.5)
		var height1 = cap_base_y + (1.0 - cos(t1 * PI * 0.5)) * cap_height
		var height2 = cap_base_y + (1.0 - cos(t2 * PI * 0.5)) * cap_height
		
		if segment == cap_segments - 1:
			radius2 = 0.0
			height2 = cap_base_y + cap_height
			
			for i in range(sides):
				var angle1 = (i / float(sides)) * TAU
				var angle2 = ((i + 1) / float(sides)) * TAU
				
				var x1 = cos(angle1) * radius1
				var z1 = sin(angle1) * radius1
				var x2 = cos(angle2) * radius1
				var z2 = sin(angle2) * radius1
				
				surface_tool.set_color(cap_color)
				surface_tool.add_vertex(Vector3(x1, height1, z1))
				surface_tool.add_vertex(Vector3(x2, height1, z2))
				surface_tool.add_vertex(Vector3(0, height2, 0))
		else:
			for i in range(sides):
				var angle1 = (i / float(sides)) * TAU
				var angle2 = ((i + 1) / float(sides)) * TAU
				
				var x1a = cos(angle1) * radius1
				var z1a = sin(angle1) * radius1
				var x2a = cos(angle2) * radius1
				var z2a = sin(angle2) * radius1
				
				var x1b = cos(angle1) * radius2
				var z1b = sin(angle1) * radius2
				var x2b = cos(angle2) * radius2
				var z2b = sin(angle2) * radius2
				
				surface_tool.set_color(cap_color)
				surface_tool.add_vertex(Vector3(x1a, height1, z1a))
				surface_tool.add_vertex(Vector3(x2a, height1, z2a))
				surface_tool.add_vertex(Vector3(x1b, height2, z1b))
				
				surface_tool.add_vertex(Vector3(x2a, height1, z2a))
				surface_tool.add_vertex(Vector3(x2b, height2, z2b))
				surface_tool.add_vertex(Vector3(x1b, height2, z1b))
	
	surface_tool.generate_normals()
	var mushroom_mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	material.roughness = 0.6
	mushroom_mesh.surface_set_material(0, material)
	
	mesh_instance.mesh = mushroom_mesh

func create_harvestable_strawberry(mesh_instance: MeshInstance3D, bush_size: HarvestableStrawberry.BushSize = HarvestableStrawberry.BushSize.MEDIUM):
	"""Create a harvestable strawberry bush with specified size"""
	var parent = mesh_instance.get_parent()
	var strawberry_position = mesh_instance.global_position
	
	# Create the harvestable strawberry node with size
	var strawberry = HarvestableStrawberryClass.new()
	strawberry.bush_size = bush_size
	
	# Set collision for harvesting
	strawberry.collision_layer = 2
	strawberry.collision_mask = 0
	
	# Create the visual mesh - small leafy bush with red berries
	var bush_mesh = MeshInstance3D.new()
	strawberry.add_child(bush_mesh)
	
	create_strawberry_bush_visual(bush_mesh, bush_size)
	
	# Add collision shape for the strawberry bush (size-dependent)
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	
	# Scale collision based on bush size
	match bush_size:
		HarvestableStrawberry.BushSize.SMALL:
			shape.radius = 0.35
			collision.position.y = 0.25
		HarvestableStrawberry.BushSize.MEDIUM:
			shape.radius = 0.5
			collision.position.y = 0.4
		HarvestableStrawberry.BushSize.LARGE:
			shape.radius = 0.65
			collision.position.y = 0.5
	
	collision.shape = shape
	strawberry.add_child(collision)
	
	# Replace mesh_instance with strawberry in scene
	parent.remove_child(mesh_instance)
	parent.add_child(strawberry)
	strawberry.global_position = strawberry_position
	
	# Register replacement node for chunk cleanup (mesh_instance will be freed)
	if populated_chunks.has(_current_chunk):
		populated_chunks[_current_chunk].append(strawberry)
	
	mesh_instance.queue_free()

func create_strawberry_bush_visual(mesh_instance: MeshInstance3D, bush_size: HarvestableStrawberry.BushSize = HarvestableStrawberry.BushSize.MEDIUM):
	"""Create the visual appearance of a strawberry bush with pixelated textures
	
	OPTIMIZATION: All berries combined into single mesh using SurfaceTool
	Instead of 12-26 separate MeshInstance3D, now uses 1 for all berries.
	"""
	# Size-dependent dimensions
	var bush_height: float
	var bush_radius: float
	var berry_count_base: int
	
	match bush_size:
		HarvestableStrawberry.BushSize.SMALL:
			bush_height = 0.4 + randf() * 0.15  # 0.4-0.55m
			bush_radius = 0.25 + randf() * 0.1  # 0.25-0.35m
			berry_count_base = 6  # 6-10 berries
		HarvestableStrawberry.BushSize.MEDIUM:
			bush_height = 0.6 + randf() * 0.3  # 0.6-0.9m
			bush_radius = 0.4 + randf() * 0.15  # 0.4-0.55m
			berry_count_base = 12  # 12-19 berries
		HarvestableStrawberry.BushSize.LARGE:
			bush_height = 0.9 + randf() * 0.4  # 0.9-1.3m
			bush_radius = 0.55 + randf() * 0.2  # 0.55-0.75m
			berry_count_base = 18  # 18-26 berries
	
	# Create bush body (leaves)
	var bush_body = MeshInstance3D.new()
	mesh_instance.add_child(bush_body)
	create_bush_body_mesh(bush_body, bush_height, bush_radius)
	
	# Apply pixelated dark green leaf texture
	var leaf_texture = PixelTextureGenerator.create_strawberry_leaf_texture()
	var leaf_material = PixelTextureGenerator.create_pixel_material(leaf_texture, Color(1.0, 1.0, 1.0))
	bush_body.set_surface_override_material(0, leaf_material)
	
	# Create ALL berries as single combined mesh
	var berry_count = berry_count_base + randi() % 8
	var berry_mesh_instance = MeshInstance3D.new()
	mesh_instance.add_child(berry_mesh_instance)
	
	# Build combined berry mesh using SurfaceTool
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var berry_color = Color(0.85, 0.15, 0.12)  # Bright red
	
	for i in range(berry_count):
		# Calculate berry position
		var berry_angle = randf() * TAU
		var berry_height_t = 0.15 + randf() * 0.7
		var berry_y = berry_height_t * bush_height
		
		var radius_mult = sin(berry_height_t * PI)
		var berry_dist = bush_radius * (0.3 + radius_mult * 0.7) * 1.05
		
		var berry_x = cos(berry_angle) * berry_dist
		var berry_z = sin(berry_angle) * berry_dist
		var berry_pos = Vector3(berry_x, berry_y, berry_z)
		
		# Berry size
		var berry_radius = 0.04 + randf() * 0.02
		
		# Add low-poly sphere geometry at this position
		_add_berry_sphere(surface_tool, berry_pos, berry_radius, berry_color)
	
	surface_tool.generate_normals()
	var combined_berry_mesh = surface_tool.commit()
	
	# Apply material
	var berry_material = StandardMaterial3D.new()
	berry_material.albedo_color = berry_color
	berry_material.roughness = 0.7
	berry_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	combined_berry_mesh.surface_set_material(0, berry_material)
	
	berry_mesh_instance.mesh = combined_berry_mesh
	
	mesh_instance.rotation.y = randf() * TAU

func _add_berry_sphere(surface_tool: SurfaceTool, center: Vector3, radius: float, color: Color):
	"""Add a low-poly sphere (octahedron) to the SurfaceTool at given position"""
	# Use simple octahedron for berries (8 triangles, very low poly)
	var top = center + Vector3(0, radius, 0)
	var bottom = center + Vector3(0, -radius, 0)
	var front = center + Vector3(0, 0, radius)
	var back = center + Vector3(0, 0, -radius)
	var left = center + Vector3(-radius, 0, 0)
	var right = center + Vector3(radius, 0, 0)
	
	surface_tool.set_color(color)
	
	# Top 4 triangles
	surface_tool.add_vertex(top)
	surface_tool.add_vertex(front)
	surface_tool.add_vertex(right)
	
	surface_tool.add_vertex(top)
	surface_tool.add_vertex(right)
	surface_tool.add_vertex(back)
	
	surface_tool.add_vertex(top)
	surface_tool.add_vertex(back)
	surface_tool.add_vertex(left)
	
	surface_tool.add_vertex(top)
	surface_tool.add_vertex(left)
	surface_tool.add_vertex(front)
	
	# Bottom 4 triangles
	surface_tool.add_vertex(bottom)
	surface_tool.add_vertex(right)
	surface_tool.add_vertex(front)
	
	surface_tool.add_vertex(bottom)
	surface_tool.add_vertex(back)
	surface_tool.add_vertex(right)
	
	surface_tool.add_vertex(bottom)
	surface_tool.add_vertex(left)
	surface_tool.add_vertex(back)
	
	surface_tool.add_vertex(bottom)
	surface_tool.add_vertex(front)
	surface_tool.add_vertex(left)

func create_bush_body_mesh(mesh_instance: MeshInstance3D, bush_height: float, bush_radius: float):
	"""Create the main body mesh of the strawberry bush"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create fuller, bushier shape with more layers
	var layers = 7  # More layers for bushier appearance
	for layer in range(layers):
		var layer_height = (layer / float(layers - 1)) * bush_height
		var layer_t = layer / float(layers - 1)
		
		# Create fuller rounded shape - wider overall
		var radius_mult = sin(layer_t * PI)
		var layer_radius = bush_radius * (0.5 + radius_mult * 0.5)  # Starts at 50% instead of 30%
		
		var segments = 10  # More segments for rounder shape
		for seg in range(segments):
			var angle1 = (seg / float(segments)) * TAU
			var angle2 = ((seg + 1) / float(segments)) * TAU
			
			var x1 = cos(angle1) * layer_radius
			var z1 = sin(angle1) * layer_radius
			var x2 = cos(angle2) * layer_radius
			var z2 = sin(angle2) * layer_radius
			
			# Add UV coordinates for texture mapping
			var uv1 = Vector2(seg / float(segments), layer_t)
			var uv2 = Vector2((seg + 1) / float(segments), layer_t)
			
			# Top cap
			if layer == layers - 1:
				surface_tool.set_uv(uv1)
				surface_tool.add_vertex(Vector3(x1, layer_height, z1))
				surface_tool.set_uv(uv2)
				surface_tool.add_vertex(Vector3(x2, layer_height, z2))
				surface_tool.set_uv(Vector2(0.5, 1.0))
				surface_tool.add_vertex(Vector3(0, layer_height, 0))
			# Side faces
			elif layer < layers - 1:
				var next_height = ((layer + 1) / float(layers - 1)) * bush_height
				var next_t = (layer + 1) / float(layers - 1)
				var next_radius_mult = sin(next_t * PI)
				var next_radius = bush_radius * (0.5 + next_radius_mult * 0.5)
				
				var x1_next = cos(angle1) * next_radius
				var z1_next = sin(angle1) * next_radius
				var x2_next = cos(angle2) * next_radius
				var z2_next = sin(angle2) * next_radius
				
				var uv1_next = Vector2(seg / float(segments), next_t)
				var uv2_next = Vector2((seg + 1) / float(segments), next_t)
				
				# Triangle 1
				surface_tool.set_uv(uv1)
				surface_tool.add_vertex(Vector3(x1, layer_height, z1))
				surface_tool.set_uv(uv2)
				surface_tool.add_vertex(Vector3(x2, layer_height, z2))
				surface_tool.set_uv(uv1_next)
				surface_tool.add_vertex(Vector3(x1_next, next_height, z1_next))
				
				# Triangle 2
				surface_tool.set_uv(uv2)
				surface_tool.add_vertex(Vector3(x2, layer_height, z2))
				surface_tool.set_uv(uv2_next)
				surface_tool.add_vertex(Vector3(x2_next, next_height, z2_next))
				surface_tool.set_uv(uv1_next)
				surface_tool.add_vertex(Vector3(x1_next, next_height, z1_next))
			
			# Bottom cap
			if layer == 0:
				surface_tool.set_uv(Vector2(0.5, 0.0))
				surface_tool.add_vertex(Vector3(0, 0, 0))
				surface_tool.set_uv(uv1)
				surface_tool.add_vertex(Vector3(x1, layer_height, z1))
				surface_tool.set_uv(uv2)
				surface_tool.add_vertex(Vector3(x2, layer_height, z2))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
