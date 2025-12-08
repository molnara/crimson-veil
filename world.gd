extends Node3D

@onready var chunk_manager = $ChunkManager
@onready var player = $Player

var chunks_ready = false

func _ready():
	# Connect the player to the chunk manager
	chunk_manager.set_player(player)
	
	# Generate initial chunks
	chunk_manager.generate_initial_chunks()
	
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
