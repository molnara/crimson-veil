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
var noise: FastNoiseLite
var biome_noise: FastNoiseLite
var temperature_noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var player: Node3D

func _ready():
	# Initialize noise generator for terrain height
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = noise_scale
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
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
		if distance > view_distance + 1:
			chunks_to_unload.append(chunk_pos)
	
	for chunk_pos in chunks_to_unload:
		unload_chunk(chunk_pos)

func world_to_chunk(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / chunk_size)),
		int(floor(world_pos.z / chunk_size))
	)

func load_chunk(chunk_pos: Vector2i):
	var chunk = Chunk.new(chunk_pos, chunk_size, chunk_height, noise, height_multiplier, 
						   temperature_noise, moisture_noise)
	add_child(chunk)
	chunks[chunk_pos] = chunk

func unload_chunk(chunk_pos: Vector2i):
	if chunks.has(chunk_pos):
		var chunk = chunks[chunk_pos]
		chunk.queue_free()
		chunks.erase(chunk_pos)

func generate_initial_chunks():
	# Generate chunks around the spawn point (0, 0) immediately
	var spawn_chunk = Vector2i(0, 0)
	for x in range(-view_distance, view_distance + 1):
		for z in range(-view_distance, view_distance + 1):
			var chunk_pos = spawn_chunk + Vector2i(x, z)
			load_chunk(chunk_pos)
	
	print("Initial ", chunks.size(), " chunks generated")
