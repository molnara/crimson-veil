extends Node3D

@onready var chunk_manager = $ChunkManager
@onready var player = $Player
@onready var vegetation_spawner = $VegetationSpawner
@onready var critter_spawner = $CritterSpawner

var chunks_ready = false

func _ready():
	# Connect the player to the chunk manager
	chunk_manager.set_player(player)
	
	# Initialize vegetation spawner
	if vegetation_spawner:
		vegetation_spawner.initialize(chunk_manager)
	
	# Initialize critter spawner
	if critter_spawner:
		critter_spawner.initialize(chunk_manager)
	
	# Generate initial chunks
	chunk_manager.generate_initial_chunks()
	
	# Calculate terrain height at spawn position and place player on ground
	var spawn_x = player.global_position.x
	var spawn_z = player.global_position.z
	var terrain_height = chunk_manager.calculate_terrain_height_at_position(spawn_x, spawn_z)
	
	# Place player slightly above terrain (account for capsule height)
	player.global_position.y = terrain_height + 2.0  # +2.0 for capsule radius
	
	# Wait a couple frames for physics to settle
	await get_tree().process_frame
	await get_tree().process_frame
	
	chunks_ready = true
	
	print("World initialized. Player connected to ChunkManager.")
	print("Controls:")
	print("  WASD - Move")
	print("  Space - Jump")  
	print("  Shift - Sprint")
	print("  Mouse - Look around")
	print("  Esc - Toggle mouse capture")
