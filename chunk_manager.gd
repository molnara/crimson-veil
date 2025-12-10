extends Node3D
class_name ChunkManager

# Chunk settings
@export var chunk_size: int = 16  # Size of each chunk in units
@export var chunk_height: int = 64  # Maximum height of terrain
@export var view_distance: int = 3  # Number of chunks to load in each direction

# Noise settings
@export var noise_scale: float = 0.03  # Lower = smoother, larger features
@export var height_multiplier: float = 10.0  # Maximum terrain height (reduced for gentler terrain)

# Biome settings
@export var biome_scale: float = 0.01  # Lower = larger biomes (easier to find)
@export var temperature_scale: float = 0.008  # Temperature variation (larger regions)
@export var moisture_scale: float = 0.01  # Moisture variation (larger regions)

# Internal variables
var chunks: Dictionary = {}  # Dictionary to store loaded chunks
var chunk_edge_heights: Dictionary = {}  # Cache edge heights to prevent seams: "x,z,edge" -> heights_array
var noise: FastNoiseLite
var detail_noise: FastNoiseLite  # Small hills/bumps
var ridge_noise: FastNoiseLite   # Mountain ridges/sharp features
var biome_noise: FastNoiseLite
var temperature_noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var player: Node3D

func _ready():
	# Initialize noise generator for terrain height (base terrain)
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = noise_scale
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Initialize detail noise for small hills and bumps
	# PERFORMANCE: Higher frequency = smaller features, adds variety without changing base shape
	detail_noise = FastNoiseLite.new()
	detail_noise.seed = noise.seed + 10
	detail_noise.frequency = noise_scale * 4.0  # 4x frequency = smaller bumps
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Initialize ridge noise for mountain peaks and valleys
	# INTEGRATION: Used only in mountain biomes for dramatic peaks
	ridge_noise = FastNoiseLite.new()
	ridge_noise.seed = noise.seed + 20
	ridge_noise.frequency = noise_scale * 2.0  # 2x frequency = medium features
	ridge_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Initialize biome noise for biome distribution
	biome_noise = FastNoiseLite.new()
	biome_noise.seed = noise.seed + 1
	biome_noise.frequency = biome_scale
	biome_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	biome_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	
	# Initialize temperature noise
	temperature_noise = FastNoiseLite.new()
	temperature_noise.seed = noise.seed + 2
	temperature_noise.frequency = temperature_scale
	temperature_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Initialize moisture noise
	moisture_noise = FastNoiseLite.new()
	moisture_noise.seed = noise.seed + 3
	moisture_noise.frequency = moisture_scale
	moisture_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	print("ChunkManager initialized with seed: ", noise.seed)
	
	# Don't generate initial chunks here - let world.gd call it when ready

func set_player(player_node: Node3D):
	player = player_node

func _process(_delta):
	if player == null:
		return
	
	update_chunks()

func update_chunks():
	# Get player's chunk position
	var player_chunk_pos = world_to_chunk(player.global_position)
	
	# Load chunks around player
	for x in range(player_chunk_pos.x - view_distance, player_chunk_pos.x + view_distance + 1):
		for z in range(player_chunk_pos.y - view_distance, player_chunk_pos.y + view_distance + 1):
			var chunk_pos = Vector2i(x, z)
			if not chunks.has(chunk_pos):
				load_chunk(chunk_pos)
	
	# Unload chunks that are too far
	var chunks_to_unload = []
	for chunk_pos in chunks.keys():
		var distance = (chunk_pos - player_chunk_pos).length()
		if distance > view_distance + 2:  # Extra buffer prevents pop-in
			chunks_to_unload.append(chunk_pos)
	
	for chunk_pos in chunks_to_unload:
		unload_chunk(chunk_pos)

func world_to_chunk(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / chunk_size)),
		int(floor(world_pos.z / chunk_size))
	)

func load_chunk(chunk_pos: Vector2i):
	# INTEGRATION: Pass detail_noise and ridge_noise to Chunk for layered terrain
	# Pass edge height cache to prevent seams between chunks
	var chunk = Chunk.new(chunk_pos, chunk_size, chunk_height, noise, height_multiplier, 
						   temperature_noise, moisture_noise, detail_noise, ridge_noise, 
						   chunk_edge_heights)
	add_child(chunk)
	chunks[chunk_pos] = chunk

func unload_chunk(chunk_pos: Vector2i):
	if chunks.has(chunk_pos):
		var chunk = chunks[chunk_pos]
		chunk.queue_free()
		chunks.erase(chunk_pos)

func calculate_terrain_height_at_position(world_x: float, world_z: float) -> float:
	"""Calculate terrain height at a world position using noise generators
	
	This duplicates the logic from Chunk.generate_mesh() to allow height
	calculation before chunks are fully loaded. Used for player spawn positioning.
	"""
	# Get base noise value
	var base_height = noise.get_noise_2d(world_x, world_z)
	var detail = detail_noise.get_noise_2d(world_x, world_z)
	var ridge = ridge_noise.get_noise_2d(world_x, world_z)
	
	# Determine biome
	var temperature = temperature_noise.get_noise_2d(world_x, world_z)
	var moisture = moisture_noise.get_noise_2d(world_x, world_z)
	
	var biome: int
	if base_height < -0.2:
		if base_height < -0.35:
			biome = 0  # OCEAN
		else:
			biome = 1  # BEACH
	elif base_height > 0.4:
		if temperature < -0.2:
			biome = 6  # SNOW
		else:
			biome = 5  # MOUNTAIN
	else:
		if temperature > 0.2 and moisture < 0.0:
			biome = 4  # DESERT
		elif moisture > 0.15:
			biome = 3  # FOREST
		else:
			biome = 2  # GRASSLAND
	
	# Calculate beach blend
	var beach_blend = 0.0
	if base_height < -0.35:
		beach_blend = 0.0
	elif base_height > -0.2:
		beach_blend = 1.0
	else:
		var blend = (base_height + 0.35) / 0.15
		beach_blend = blend * blend * (3.0 - 2.0 * blend)
	
	# Apply biome modifiers
	var height_mod = 1.0
	var roughness_mod = 1.0
	
	match biome:
		0:  # OCEAN
			height_mod = 0.15
			roughness_mod = 0.7
		1:  # BEACH
			height_mod = 0.7
			roughness_mod = 0.7
		2:  # GRASSLAND
			height_mod = 1.0
			roughness_mod = 0.85
		3:  # FOREST
			height_mod = 1.05
			roughness_mod = 0.95
		4:  # DESERT
			height_mod = 0.9
			roughness_mod = 0.8
		5:  # MOUNTAIN
			height_mod = 1.5
			roughness_mod = 1.2
		6:  # SNOW
			height_mod = 1.6
			roughness_mod = 1.15
	
	var modified_height = base_height * roughness_mod
	modified_height += detail * 0.2
	
	var height: float
	
	# Mountains get exponential + ridge
	if biome == 5 or biome == 6:  # MOUNTAIN or SNOW
		var exponential_height = sign(modified_height) * pow(abs(modified_height), 1.4)
		height = (exponential_height + ridge * 0.15) * height_multiplier * height_mod
	else:
		height = modified_height * height_multiplier * height_mod
	
	# Apply baseline offset with beach blending
	if biome == 0:  # OCEAN
		height = height - (height_multiplier * 0.6)
	elif biome == 1:  # BEACH
		var ocean_height = height - (height_multiplier * 0.6)
		var land_height = height + (height_multiplier * 0.2)
		height = lerp(ocean_height, land_height, beach_blend)
	else:
		height = height + (height_multiplier * 0.5)
	
	return height

func generate_initial_chunks():
	# Generate chunks around the spawn point (0, 0) immediately
	var spawn_chunk = Vector2i(0, 0)
	for x in range(-view_distance, view_distance + 1):
		for z in range(-view_distance, view_distance + 1):
			var chunk_pos = spawn_chunk + Vector2i(x, z)
			load_chunk(chunk_pos)
	
	print("Initial ", chunks.size(), " chunks generated")
