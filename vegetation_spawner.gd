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

# References
var chunk_manager: ChunkManager
var noise: FastNoiseLite
var vegetation_noise: FastNoiseLite
var cluster_noise: FastNoiseLite  # For grass clustering
var player: Node3D

# Vegetation density settings - individual control for each type
@export_group("Vegetation Density")
@export_range(0.0, 1.0) var tree_density: float = 0.35  ## Density of trees (0.0 = none, 1.0 = maximum)
@export_range(0.0, 1.0) var rock_density: float = 0.25  ## Density of rocks and boulders (0.0 = none, 1.0 = maximum)
@export_range(0.0, 1.0) var mushroom_density: float = 0.15  ## Density of mushrooms (0.0 = none, 1.0 = maximum)
@export_range(0.0, 1.0) var strawberry_density: float = 0.20  ## Density of strawberry bushes (0.0 = none, 1.0 = maximum)
@export_range(0.0, 1.0) var grass_density: float = 0.8  ## Density of grass and ground cover (higher for fuller look)
@export_range(0.0, 1.0) var flower_density: float = 0.15  ## Density of wildflowers (0.0 = none, 1.0 = maximum)
@export_range(1, 5) var spawn_radius: int = 2  ## How many chunks around player to populate with vegetation

@export_group("Tree Size Variation")
@export_range(2.0, 15.0) var tree_height_min: float = 3.5  ## Minimum tree height in meters (smallest trees)
@export_range(2.0, 15.0) var tree_height_max: float = 9.5  ## Maximum tree height in meters (tallest trees)
@export_range(0.1, 1.0) var trunk_radius_base: float = 0.3  ## Base trunk radius in meters (scales with tree size)

@export_group("Tree Branch Settings")
@export_range(2, 8) var branch_count_min: int = 3  ## Minimum number of branches per tree
@export_range(2, 8) var branch_count_max: int = 5  ## Maximum number of branches per tree
@export_range(0.5, 3.0) var branch_length_min: float = 1.6  ## Minimum branch length in meters
@export_range(0.5, 3.0) var branch_length_max: float = 2.0  ## Maximum branch length in meters
@export_range(0.0, 1.0) var branch_height_start: float = 0.5  ## Where branches start as fraction of trunk height (0.5 = halfway up)
@export_range(0.0, 1.0) var branch_height_end: float = 0.85  ## Where branches end as fraction of trunk height (0.85 = near top)
@export_range(0.0, 0.5) var branch_upward_angle: float = 0.25  ## How much branches angle upward (0 = horizontal, 0.5 = steep)

@export_group("Tree Foliage Settings")
@export_range(2, 8) var branch_foliage_layers: int = 4  ## Number of foliage disc layers per branch (more = fuller coverage)
@export_range(2, 10) var top_foliage_layers: int = 5  ## Number of foliage disc layers at tree top (more = denser crown)
@export_range(0.1, 1.0) var foliage_disc_thickness: float = 0.4  ## Base thickness of foliage discs in meters
@export_range(0.0, 1.0) var foliage_layer_gap: float = 0.2  ## Vertical spacing between foliage layers (lower = tighter, less trunk visible)
@export_range(0.5, 2.0) var foliage_disc_size: float = 0.75  ## Size multiplier for foliage disc radius (larger = wider canopy)
@export_range(0.7, 1.0) var top_crown_height_ratio: float = 0.88  ## Where top crown starts as fraction of trunk height (higher = near top)

@export_group("Ground Cover Settings")
@export_range(10, 150) var ground_cover_samples_per_chunk: int = 60  ## Number of grass/flower samples per chunk (higher = denser)
@export_range(5, 50) var large_vegetation_samples_per_chunk: int = 15  ## Number of tree/rock samples per chunk (lower = more sparse)

# Track which chunks have vegetation
var populated_chunks: Dictionary = {}
var initialized: bool = false

# Vegetation types per biome
enum VegType {
	TREE,
	PINE_TREE,
	ROCK,
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
	STRAWBERRY_BUSH
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

func populate_chunk(chunk_pos: Vector2i):
	"""Populate a chunk with vegetation using two-pass system
	
	ALGORITHM:
	Pass 1: Large vegetation (trees, rocks, mushrooms, strawberries)
	  - Sparse samples (15 per chunk default)
	  - Creates harvestable resources with collision
	  - More expensive but fewer instances
	
	Pass 2: Ground cover (grass, flowers)
	  - Dense samples (60 per chunk default)
	  - Uses MultiMesh for performance (100+ grass blades per tuft)
	  - Clustered using cluster_noise for natural patches
	
	PERFORMANCE: This runs once per chunk, cached in populated_chunks dictionary
	"""
	if populated_chunks.has(chunk_pos):
		return
	
	populated_chunks[chunk_pos] = true
	
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
	# PERFORMANCE: Higher sample count but lightweight meshes (no collision, MultiMesh)
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
			# Trees
			if rand > (1.0 - tree_density * 0.65):
				if randf() > 0.5:
					veg_type = VegType.TREE
				else:
					veg_type = VegType.PINE_TREE
			# Mushrooms
			elif rand > (1.0 - mushroom_density * 0.35):
				var mushroom_rand = randf()
				if mushroom_rand > 0.6:
					veg_type = VegType.MUSHROOM_RED
				elif mushroom_rand > 0.3:
					veg_type = VegType.MUSHROOM_BROWN
				else:
					veg_type = VegType.MUSHROOM_CLUSTER
			# Strawberries
			elif rand > (1.0 - strawberry_density * 0.25):
				veg_type = VegType.STRAWBERRY_BUSH
			# Rocks
			elif rand > (1.0 - rock_density * 0.15):
				veg_type = VegType.ROCK
			else:
				return
		
		Chunk.Biome.GRASSLAND:
			# Trees
			if rand > (1.0 - tree_density * 0.20):
				veg_type = VegType.TREE
			# Strawberries
			elif rand > (1.0 - strawberry_density * 0.40):
				veg_type = VegType.STRAWBERRY_BUSH
			# Rocks
			elif rand > (1.0 - rock_density * 0.25):
				veg_type = VegType.ROCK
			else:
				return
		
		Chunk.Biome.DESERT:
			# Cactus (uses tree density)
			if rand > (1.0 - tree_density * 0.30):
				veg_type = VegType.CACTUS
			# Rocks
			elif rand > (1.0 - rock_density * 0.35):
				veg_type = VegType.ROCK
			else:
				return
		
		Chunk.Biome.MOUNTAIN:
			# Boulders and rocks
			if rand > (1.0 - rock_density * 0.60):
				if randf() > 0.5:
					veg_type = VegType.BOULDER
				else:
					veg_type = VegType.ROCK
			else:
				return
		
		Chunk.Biome.SNOW:
			# Pine trees
			if rand > (1.0 - tree_density * 0.35):
				veg_type = VegType.PINE_TREE
			# Rocks
			elif rand > (1.0 - rock_density * 0.25):
				veg_type = VegType.ROCK
			else:
				return
		
		Chunk.Biome.BEACH:
			# Palm trees
			if rand > (1.0 - tree_density * 0.25):
				veg_type = VegType.PALM_TREE
			# Rocks
			elif rand > (1.0 - rock_density * 0.20):
				veg_type = VegType.ROCK
			else:
				return
		
		_:
			return
	
	create_vegetation_mesh(veg_type, spawn_pos)

func spawn_ground_cover_for_biome(biome: Chunk.Biome, spawn_pos: Vector3, _world_x: float, _world_z: float, cluster_value: float):
	"""Spawn grass, flowers, and ground cover - dense and varied"""
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
			# Grass (check density)
			elif rand < grass_density:
				if cluster_value > 0.3:
					# Dense grass in good cluster areas
					veg_type = VegType.GRASS_PATCH
				else:
					# Regular grass
					veg_type = VegType.GRASS_TUFT
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
			# Grass (less dense in forest, check grass_density)
			elif rand < grass_density * 0.5:
				if cluster_value > 0.2:
					# Some grass patches in clearings
					veg_type = VegType.GRASS_PATCH
				else:
					veg_type = VegType.GRASS_TUFT
			else:
				return
		
		Chunk.Biome.BEACH:
			# Sparse beach grass (check grass_density)
			if rand < grass_density * 0.4:
				veg_type = VegType.GRASS_TUFT
			else:
				return
		
		_:
			return
	
	create_vegetation_mesh(veg_type, spawn_pos)

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
	
	match veg_type:
		VegType.TREE:
			create_tree(mesh_instance)
		VegType.PINE_TREE:
			create_pine_tree(mesh_instance)
		VegType.PALM_TREE:
			create_palm_tree(mesh_instance)
		VegType.ROCK:
			create_rock(mesh_instance, false)
		VegType.BOULDER:
			create_rock(mesh_instance, true)
		VegType.CACTUS:
			create_cactus(mesh_instance)
		VegType.GRASS_TUFT:
			create_grass_tuft_improved(mesh_instance)
		VegType.GRASS_PATCH:
			create_grass_patch(mesh_instance)
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
		VegType.STRAWBERRY_BUSH:
			create_harvestable_strawberry(mesh_instance)

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
	"""Create a harvestable tree"""
	var parent = mesh_instance.get_parent()
	var tree_position = mesh_instance.global_position
	
	# Create the harvestable tree node
	var tree = HarvestableTreeClass.new()
	tree.tree_type = HarvestableTreeClass.TreeType.NORMAL
	
	# Set collision for harvesting
	tree.collision_layer = 2
	tree.collision_mask = 0
	
	# Much more varied tree sizes - configurable
	var size_variation = randf()
	var trunk_height: float
	var trunk_radius: float
	var foliage_size_multiplier: float
	
	# Map size_variation to height range
	trunk_height = tree_height_min + randf() * (tree_height_max - tree_height_min)
	
	# Scale trunk radius and foliage based on height
	var height_ratio = (trunk_height - tree_height_min) / (tree_height_max - tree_height_min)
	trunk_radius = trunk_radius_base * (0.8 + height_ratio * 0.6)  # 80-140% of base
	foliage_size_multiplier = 0.9 + height_ratio * 0.8  # 0.9-1.7 multiplier
	
	# Create trunk
	var trunk_mesh = MeshInstance3D.new()
	tree.add_child(trunk_mesh)
	
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = trunk_height
	cylinder_mesh.top_radius = trunk_radius * 0.7  # Tapers toward top
	cylinder_mesh.bottom_radius = trunk_radius
	trunk_mesh.mesh = cylinder_mesh
	trunk_mesh.position.y = trunk_height / 2
	
	# Pixelated bark texture - OAK style with medium-dark brown
	var bark_texture = PixelTextureGenerator.create_bark_texture()
	var bark_variation = randf() * 0.1
	var bark_tint = Color(0.55 + bark_variation, 0.42 + bark_variation * 0.5, 0.28 + bark_variation * 0.3)  # Medium brown
	var trunk_material = PixelTextureGenerator.create_pixel_material(bark_texture, bark_tint)
	trunk_mesh.set_surface_override_material(0, trunk_material)
	
	# Pixelated leaves texture with color variation (defined once for all foliage)
	var leaves_texture = PixelTextureGenerator.create_leaves_texture()
	var green_variation = randf()
	var foliage_tint: Color
	if green_variation > 0.7:
		foliage_tint = Color(0.9, 1.0, 0.9)  # Lighter green
	elif green_variation > 0.3:
		foliage_tint = Color(0.85, 0.95, 0.85)  # Standard green
	else:
		foliage_tint = Color(0.75, 0.85, 0.75)  # Darker green
	var foliage_material = PixelTextureGenerator.create_pixel_material(leaves_texture, foliage_tint)
	
	# Create natural branching structure with multiple foliage clusters
	var branch_count = branch_count_min + randi() % (branch_count_max - branch_count_min + 1)
	var top_foliage_height_ratio = top_crown_height_ratio + randf() * 0.08
	var top_foliage_height = trunk_height * top_foliage_height_ratio
	
	for i in range(branch_count):
		var branch_angle = (i / float(branch_count)) * TAU + randf() * 0.5  # Distribute around trunk
		var branch_height_ratio = branch_height_start + (i / float(branch_count)) * (branch_height_end - branch_height_start)
		var branch_height_local = trunk_height * branch_height_ratio  # Height in WORLD space
		
		# Branch extends outward and slightly up - configurable length
		var branch_length = (branch_length_min + randf() * (branch_length_max - branch_length_min)) * foliage_size_multiplier
		
		# Calculate branch start point (on trunk at height) - in TRUNK_MESH local space
		# Trunk mesh is centered at trunk_height/2, so we need to offset
		var branch_start_local = Vector3(0, branch_height_local - trunk_height / 2, 0)
		
		# Calculate branch end point (extends outward and up) - in TRUNK_MESH local space
		var horizontal_extent = branch_length * 0.95  # Most of length is horizontal
		var vertical_rise = branch_length * branch_upward_angle  # Configurable upward angle
		var branch_end_local = Vector3(
			cos(branch_angle) * horizontal_extent,
			(branch_height_local - trunk_height / 2) + vertical_rise,
			sin(branch_angle) * horizontal_extent
		)
		
		# Create branch cylinder - THINNER branches
		var branch = MeshInstance3D.new()
		trunk_mesh.add_child(branch)
		
		var branch_mesh = CylinderMesh.new()
		branch_mesh.height = branch_length
		branch_mesh.top_radius = trunk_radius * 0.15
		branch_mesh.bottom_radius = trunk_radius * 0.22
		branch.mesh = branch_mesh
		
		# Position branch at midpoint between start and end
		branch.position = (branch_start_local + branch_end_local) / 2.0
		
		# Rotate branch to point from start to end
		var branch_direction = (branch_end_local - branch_start_local).normalized()
		var default_up = Vector3.UP
		
		# Only rotate if not already aligned
		if not branch_direction.is_equal_approx(default_up):
			var rotation_axis = default_up.cross(branch_direction)
			if rotation_axis.length() > 0.001:
				rotation_axis = rotation_axis.normalized()
				var rotation_angle = acos(clamp(default_up.dot(branch_direction), -1.0, 1.0))
				branch.rotate(rotation_axis, rotation_angle)
		
		branch.set_surface_override_material(0, trunk_material)
		
		# Foliage cluster at branch end - LAYERED FLAT DISCS instead of spheres
		# Create stacked disc layers for natural leaf cluster
		var layer_count = branch_foliage_layers + (randi() % 2)  # Configurable + random 0-1
		
		for layer in range(layer_count):
			var foliage = MeshInstance3D.new()
			trunk_mesh.add_child(foliage)
			
			# Flattened cylinder mesh (disc shape)
			var disc_mesh = CylinderMesh.new()
			var disc_size = foliage_disc_size * (0.6 + randf() * 0.3) * foliage_size_multiplier  # Configurable size
			disc_size *= (1.0 - layer * 0.18)  # Each layer progressively smaller
			disc_mesh.top_radius = disc_size
			disc_mesh.bottom_radius = disc_size * 0.9
			
			# Progressive thickness - bottom thick, top thin
			var base_thickness = foliage_disc_thickness + randf() * 0.15  # Configurable base thickness
			var thickness_factor = 1.0 - (layer / float(layer_count)) * 0.6  # Bottom 100%, top 40%
			disc_mesh.height = base_thickness * thickness_factor
			
			disc_mesh.radial_segments = 8
			disc_mesh.rings = 1
			foliage.mesh = disc_mesh
			
			# Stack layers vertically - configurable gap
			var layer_offset = layer * foliage_layer_gap
			foliage.position = branch_end_local + Vector3(0, layer_offset, 0)
			
			# Random rotation for natural look
			foliage.rotation.y = randf() * TAU
			
			foliage.set_surface_override_material(0, foliage_material)
	
	# Add top crown foliage - LAYERED DISCS
	var top_layer_count = top_foliage_layers + (randi() % 2)  # Configurable + random 0-1
	
	for layer in range(top_layer_count):
		var top_foliage = MeshInstance3D.new()
		trunk_mesh.add_child(top_foliage)
		
		var top_disc = CylinderMesh.new()
		var top_size = foliage_disc_size * (0.8 + randf() * 0.4) * foliage_size_multiplier  # Configurable size
		top_size *= (1.0 - layer * 0.15)  # Each layer progressively smaller
		top_disc.top_radius = top_size
		top_disc.bottom_radius = top_size * 0.85
		
		# Progressive thickness - bottom thick, top thin
		var base_thickness = foliage_disc_thickness * 1.1 + randf() * 0.2  # Slightly thicker than branch foliage
		var thickness_factor = 1.0 - (layer / float(top_layer_count)) * 0.65  # Bottom 100%, top 35%
		top_disc.height = base_thickness * thickness_factor
		
		top_disc.radial_segments = 8
		top_disc.rings = 1
		top_foliage.mesh = top_disc
		
		# Stack layers - configurable gap
		var layer_height_local = (top_foliage_height - trunk_height / 2) + layer * (foliage_layer_gap * 1.25)
		top_foliage.position = Vector3(0, layer_height_local, 0)
		top_foliage.rotation.y = randf() * TAU
		
		top_foliage.set_surface_override_material(0, foliage_material)
	
	# Add collision shape for the tree (scaled to trunk size)
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = trunk_radius
	shape.height = trunk_height
	collision.shape = shape
	collision.position.y = trunk_height / 2
	tree.add_child(collision)
	
	# Replace mesh_instance with tree in scene
	parent.remove_child(mesh_instance)
	parent.add_child(tree)
	tree.global_position = tree_position
	mesh_instance.queue_free()

func create_pine_tree(mesh_instance: MeshInstance3D):
	"""Create a harvestable pine tree"""
	var parent = mesh_instance.get_parent()
	var tree_position = mesh_instance.global_position
	
	# Create the harvestable tree node
	var tree = HarvestableTreeClass.new()
	tree.tree_type = HarvestableTreeClass.TreeType.PINE
	
	# Set collision for harvesting
	tree.collision_layer = 2
	tree.collision_mask = 0
	
	# Create tree visual
	var trunk_height = 3.0 + randf() * 2.0
	var trunk_radius = 0.25
	
	var trunk_mesh = MeshInstance3D.new()
	tree.add_child(trunk_mesh)
	
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = trunk_height
	cylinder_mesh.top_radius = trunk_radius * 0.6
	cylinder_mesh.bottom_radius = trunk_radius
	trunk_mesh.mesh = cylinder_mesh
	trunk_mesh.position.y = trunk_height / 2
	
	# Pixelated bark texture - PINE style with reddish-brown
	var bark_texture = PixelTextureGenerator.create_pine_bark_texture()
	var trunk_material = PixelTextureGenerator.create_pixel_material(bark_texture, Color(1.0, 0.85, 0.75))  # Reddish tint
	trunk_mesh.set_surface_override_material(0, trunk_material)
	
	# Pine foliage (cone levels) with pixelated texture
	var leaves_texture = PixelTextureGenerator.create_leaves_texture()
	var cone_levels = 3
	for i in range(cone_levels):
		var cone = MeshInstance3D.new()
		trunk_mesh.add_child(cone)
		
		var cone_mesh = CylinderMesh.new()
		# i=0 should be BOTTOM (large), i=2 should be TOP (small)
		var level_height = trunk_height * (0.4 + i * 0.2)  # 0.4, 0.6, 0.8 (bottom to top)
		var cone_size = 1.5 - i * 0.3  # 1.5, 1.2, 0.9 (large to small)
		
		cone_mesh.height = cone_size
		cone_mesh.top_radius = 0.0  # Point at top
		cone_mesh.bottom_radius = cone_size * 0.7  # Wide at bottom
		cone.mesh = cone_mesh
		cone.position = Vector3(0, level_height, 0)
		
		# Dark green pixelated texture for pine needles
		var cone_material = PixelTextureGenerator.create_pixel_material(leaves_texture, Color(0.5, 0.8, 0.5))
		cone.set_surface_override_material(0, cone_material)
	
	# Add collision shape for the tree
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = trunk_radius
	shape.height = trunk_height
	collision.shape = shape
	collision.position.y = trunk_height / 2
	tree.add_child(collision)
	
	# Replace mesh_instance with tree in scene
	parent.remove_child(mesh_instance)
	parent.add_child(tree)
	tree.global_position = tree_position
	mesh_instance.queue_free()

func create_palm_tree(mesh_instance: MeshInstance3D):
	"""Create a harvestable palm tree"""
	var parent = mesh_instance.get_parent()
	var tree_position = mesh_instance.global_position
	
	# Create the harvestable tree node
	var tree = HarvestableTreeClass.new()
	tree.tree_type = HarvestableTreeClass.TreeType.PALM
	
	# Set collision for harvesting
	tree.collision_layer = 2
	tree.collision_mask = 0
	
	# Create tree visual
	var trunk_height = 3.0 + randf() * 1.5
	var trunk_radius = 0.25
	
	var trunk_mesh = MeshInstance3D.new()
	tree.add_child(trunk_mesh)
	
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = trunk_height
	cylinder_mesh.top_radius = trunk_radius * 0.7
	cylinder_mesh.bottom_radius = trunk_radius
	trunk_mesh.mesh = cylinder_mesh
	trunk_mesh.position.y = trunk_height / 2
	
	# Pixelated bark texture - PALM style with tan/beige
	var bark_texture = PixelTextureGenerator.create_palm_bark_texture()
	var trunk_material = PixelTextureGenerator.create_pixel_material(bark_texture, Color(1.15, 1.05, 0.85))  # Tan/beige tint
	trunk_mesh.set_surface_override_material(0, trunk_material)
	
	# Palm fronds with pixelated texture
	var leaves_texture = PixelTextureGenerator.create_leaves_texture()
	var palm_count = 6
	for i in range(palm_count):
		var frond = MeshInstance3D.new()
		trunk_mesh.add_child(frond)
		
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.2, 0.1, 2.0)
		frond.mesh = box_mesh
		
		var angle = (i / float(palm_count)) * TAU
		frond.position = Vector3(0, trunk_height * 0.45, 0)
		frond.rotation.y = angle
		frond.rotation.x = -0.5
		
		# Bright green pixelated texture for palm fronds
		var frond_material = PixelTextureGenerator.create_pixel_material(leaves_texture, Color(0.6, 1.4, 0.8))
		frond.set_surface_override_material(0, frond_material)
	
	# Add collision shape for the tree
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = trunk_radius
	shape.height = trunk_height
	collision.shape = shape
	collision.position.y = trunk_height / 2
	tree.add_child(collision)
	
	# Replace mesh_instance with tree in scene
	parent.remove_child(mesh_instance)
	parent.add_child(tree)
	tree.global_position = tree_position
	mesh_instance.queue_free()

func create_rock(mesh_instance: MeshInstance3D, is_boulder: bool):
	var size = 0.6 + randf() * 0.4 if not is_boulder else 1.2 + randf() * 0.8
	
	var parent = mesh_instance.get_parent()
	var rock_position = mesh_instance.global_position
	
	var resource_node = ResourceNodeClass.new()
	resource_node.resource_type = "stone"
	resource_node.resource_name = "Boulder" if is_boulder else "Rock"
	resource_node.harvest_time = 3.0 if is_boulder else 2.0
	resource_node.drop_item = "stone"
	resource_node.drop_amount_min = 6 if is_boulder else 2
	resource_node.drop_amount_max = 10 if is_boulder else 4
	
	resource_node.collision_layer = 2
	resource_node.collision_mask = 0
	
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
	
	sphere_mesh.material = material
	rock_mesh.mesh = sphere_mesh
	
	rock_mesh.rotation.x = (randf() - 0.5) * 0.3
	rock_mesh.rotation.z = (randf() - 0.5) * 0.3
	rock_mesh.scale = Vector3(1.0, 0.6, 0.9)
	
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = size / 2
	collision.shape = shape
	resource_node.add_child(collision)
	
	parent.remove_child(mesh_instance)
	parent.add_child(resource_node)
	resource_node.global_position = rock_position
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

func create_harvestable_strawberry(mesh_instance: MeshInstance3D):
	"""Create a harvestable strawberry bush"""
	var parent = mesh_instance.get_parent()
	var strawberry_position = mesh_instance.global_position
	
	# Create the harvestable strawberry node
	var strawberry = HarvestableStrawberryClass.new()
	
	# Set collision for harvesting
	strawberry.collision_layer = 2
	strawberry.collision_mask = 0
	
	# Create the visual mesh - small leafy bush with red berries
	var bush_mesh = MeshInstance3D.new()
	strawberry.add_child(bush_mesh)
	
	create_strawberry_bush_visual(bush_mesh)
	
	# Add collision shape for the strawberry bush (bigger to match new size)
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.5  # Increased from 0.4
	collision.shape = shape
	collision.position.y = 0.4  # Raised from 0.3
	strawberry.add_child(collision)
	
	# Replace mesh_instance with strawberry in scene
	parent.remove_child(mesh_instance)
	parent.add_child(strawberry)
	strawberry.global_position = strawberry_position
	mesh_instance.queue_free()

func create_strawberry_bush_visual(mesh_instance: MeshInstance3D):
	"""Create the visual appearance of a strawberry bush with pixelated textures"""
	var bush_height = 0.6 + randf() * 0.3  # 0.6-0.9m tall (taller)
	var bush_radius = 0.4 + randf() * 0.15  # Base radius (wider)
	
	# Create bush body (leaves)
	var bush_body = MeshInstance3D.new()
	mesh_instance.add_child(bush_body)
	create_bush_body_mesh(bush_body, bush_height, bush_radius)
	
	# Apply pixelated dark green leaf texture
	var leaf_texture = PixelTextureGenerator.create_strawberry_leaf_texture()
	var leaf_material = PixelTextureGenerator.create_pixel_material(leaf_texture, Color(1.0, 1.0, 1.0))
	bush_body.set_surface_override_material(0, leaf_material)
	
	# Add strawberry berries with solid color (too small for texture)
	var berry_count = 12 + randi() % 8  # 12-19 berries
	
	# Create solid berry material (no texture)
	var berry_material = StandardMaterial3D.new()
	berry_material.albedo_color = Color(0.85, 0.15, 0.12)  # Bright red
	berry_material.roughness = 0.7
	berry_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	
	for i in range(berry_count):
		var berry = MeshInstance3D.new()
		mesh_instance.add_child(berry)
		
		# Position berry around the bush
		var berry_angle = randf() * TAU
		var berry_height_t = 0.15 + randf() * 0.7  # More vertical spread
		var berry_height = berry_height_t * bush_height
		
		var radius_mult = sin(berry_height_t * PI)
		var berry_radius = bush_radius * (0.3 + radius_mult * 0.7)
		var berry_offset = berry_radius * 1.05  # Slightly closer to bush
		
		var berry_x = cos(berry_angle) * berry_offset
		var berry_z = sin(berry_angle) * berry_offset
		berry.position = Vector3(berry_x, berry_height, berry_z)
		
		# Create smaller berry sphere mesh
		var sphere = SphereMesh.new()
		sphere.radius = 0.04 + randf() * 0.02  # 0.04-0.06 (smaller)
		sphere.height = sphere.radius * 2
		sphere.radial_segments = 6
		sphere.rings = 4
		berry.mesh = sphere
		
		# Apply solid color material
		berry.set_surface_override_material(0, berry_material)
	
	mesh_instance.rotation.y = randf() * TAU

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
