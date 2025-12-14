extends Node

## BiomeTeleporter - Debug tool for v0.8.0 testing
##
## Hotkeys (hold ALT + number key):
##   Alt+1 - Teleport to GRASSLAND
##   Alt+2 - Teleport to FOREST
##   Alt+3 - Teleport to DESERT
##   Alt+4 - Teleport to SNOW
##   Alt+5 - Teleport to BEACH
##   Alt+6 - Teleport to MOUNTAIN
##   Alt+7 - Teleport to OCEAN (edge)
##   Alt+0 - Teleport to SPAWN (origin)
##
## Add this script to your World node or as an autoload.

class_name BiomeTeleporter

var player: CharacterBody3D = null
var chunk_manager: ChunkManager = null
var scan_complete: bool = false

# Search patterns for each biome
# We'll search outward from origin to find biome locations
var biome_cache: Dictionary = {}  # biome_id -> Vector3 position

func _ready():
	# Use call_deferred to run after parent _ready completes
	call_deferred("_delayed_init")

func _delayed_init():
	# Wait for world to fully initialize
	await get_tree().create_timer(1.0).timeout
	
	# Try to get references from parent (World node)
	var parent = get_parent()
	if parent:
		if parent.has_node("Player"):
			player = parent.get_node("Player")
		if parent.has_node("ChunkManager"):
			chunk_manager = parent.get_node("ChunkManager")
	
	# Fallback: search by group
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if not chunk_manager:
		var managers = get_tree().get_nodes_in_group("chunk_manager")
		if managers.size() > 0:
			chunk_manager = managers[0]
	
	if player and chunk_manager:
		print("[BiomeTeleporter] Ready! Hold Alt + press 1-7 to teleport to biomes, Alt+0 for spawn")
		# Pre-scan for biome locations
		_scan_for_biomes()
	else:
		print("[BiomeTeleporter] ERROR: Could not find player (%s) or chunk_manager (%s)" % [player != null, chunk_manager != null])

func _scan_for_biomes():
	"""Scan the world to find locations of each biome"""
	print("[BiomeTeleporter] Scanning for biome locations...")
	
	# Search in expanding squares - much larger area
	var search_radius = 2000  # Search within 2000 units
	var step = 50  # Check every 50 units
	
	for x in range(-search_radius, search_radius + 1, step):
		for z in range(-search_radius, search_radius + 1, step):
			var world_pos = Vector3(x, 0, z)
			var biome = _get_biome_at(float(x), float(z))
			
			# Store first found location for each biome
			if not biome_cache.has(biome):
				biome_cache[biome] = world_pos
				print("[BiomeTeleporter] Found %s at (%d, %d)" % [_biome_name(biome), x, z])
				
				# Early exit if we found all 7 biomes
				if biome_cache.size() >= 7:
					break
		if biome_cache.size() >= 7:
			break
	
	scan_complete = true
	print("[BiomeTeleporter] Scan complete. Found %d biomes:" % biome_cache.size())
	
	# List what we found
	for biome_id in biome_cache:
		var pos = biome_cache[biome_id]
		print("[BiomeTeleporter]   %s -> (%.0f, %.0f)" % [_biome_name(biome_id), pos.x, pos.z])

func _get_biome_at(world_x: float, world_z: float) -> int:
	"""Get biome at world position using chunk_manager's noise and thresholds"""
	if not chunk_manager:
		return 2  # Default to grassland
	
	var base_noise = chunk_manager.noise.get_noise_2d(world_x, world_z)
	var temperature = chunk_manager.temperature_noise.get_noise_2d(world_x, world_z)
	var moisture = chunk_manager.moisture_noise.get_noise_2d(world_x, world_z)
	
	# v0.8.0 FIX: Use chunk_manager thresholds to match terrain visuals
	# SPAWN ZONE OVERRIDE: Match chunk.gd behavior
	var distance_from_origin = sqrt(world_x * world_x + world_z * world_z)
	if distance_from_origin < chunk_manager.spawn_zone_radius:
		return 2  # GRASSLAND
	
	# Use configurable thresholds from chunk_manager
	if base_noise < chunk_manager.beach_threshold:
		if base_noise < chunk_manager.ocean_threshold:
			return 0  # OCEAN
		else:
			return 1  # BEACH
	elif base_noise > chunk_manager.mountain_threshold:
		if temperature < chunk_manager.snow_temperature:
			return 6  # SNOW
		else:
			return 5  # MOUNTAIN
	else:
		if temperature > chunk_manager.desert_temperature and moisture < chunk_manager.desert_moisture:
			return 4  # DESERT
		elif moisture > chunk_manager.forest_moisture:
			return 3  # FOREST
		else:
			return 2  # GRASSLAND

func _biome_name(biome_id: int) -> String:
	match biome_id:
		0: return "OCEAN"
		1: return "BEACH"
		2: return "GRASSLAND"
		3: return "FOREST"
		4: return "DESERT"
		5: return "MOUNTAIN"
		6: return "SNOW"
		_: return "UNKNOWN"

func _input(event: InputEvent):
	if not event is InputEventKey:
		return
	
	# Require ALT to be held
	if not event.pressed or event.echo or not event.alt_pressed:
		return
	
	var target_biome: int = -1
	var target_name: String = ""
	
	match event.keycode:
		KEY_1:
			target_biome = 2  # GRASSLAND
			target_name = "GRASSLAND"
			get_viewport().set_input_as_handled()
		KEY_2:
			target_biome = 3  # FOREST
			target_name = "FOREST"
			get_viewport().set_input_as_handled()
		KEY_3:
			target_biome = 4  # DESERT
			target_name = "DESERT"
			get_viewport().set_input_as_handled()
		KEY_4:
			target_biome = 6  # SNOW
			target_name = "SNOW"
			get_viewport().set_input_as_handled()
		KEY_5:
			target_biome = 1  # BEACH
			target_name = "BEACH"
			get_viewport().set_input_as_handled()
		KEY_6:
			target_biome = 5  # MOUNTAIN
			target_name = "MOUNTAIN"
			get_viewport().set_input_as_handled()
		KEY_7:
			target_biome = 0  # OCEAN
			target_name = "OCEAN"
			get_viewport().set_input_as_handled()
		KEY_0:
			# Teleport to spawn
			_teleport_to(Vector3(0, 20, 0))
			print("[BiomeTeleporter] Teleported to SPAWN (origin)")
			get_viewport().set_input_as_handled()
			return
		_:
			return
	
	if target_biome >= 0:
		_teleport_to_biome(target_biome, target_name)

func _teleport_to_biome(biome_id: int, biome_name: String):
	"""Teleport player to the specified biome"""
	if not player:
		print("[BiomeTeleporter] Error: No player found")
		return
	
	# v0.8.0: Always do a fresh search to ensure we find the actual biome
	# The cache may have been built with incorrect thresholds
	print("[BiomeTeleporter] Searching for %s..." % biome_name)
	var target_pos = _search_for_biome(biome_id)
	
	if target_pos == Vector3.ZERO:
		print("[BiomeTeleporter] Could not find %s biome!" % biome_name)
		return
	
	# Get terrain height at target
	target_pos.y = _get_terrain_height(target_pos.x, target_pos.z) + 2.0
	
	_teleport_to(target_pos)
	print("[BiomeTeleporter] Teleported to %s at (%.0f, %.0f, %.0f)" % [
		biome_name, target_pos.x, target_pos.y, target_pos.z
	])

func _search_for_biome(target_biome: int) -> Vector3:
	"""Search outward from origin to find a specific biome"""
	var search_radius = 3000  # Much larger search area
	var step = 50
	
	print("[BiomeTeleporter] Searching up to %d units for %s..." % [search_radius, _biome_name(target_biome)])
	
	for radius in range(step, search_radius, step):
		# Search in a square pattern at this radius
		for x in range(-radius, radius + 1, step):
			for z in [-radius, radius]:  # Top and bottom edges
				var biome = _get_biome_at(float(x), float(z))
				if biome == target_biome:
					biome_cache[target_biome] = Vector3(x, 0, z)  # Cache it
					return Vector3(x, 0, z)
		
		for z in range(-radius + step, radius, step):
			for x in [-radius, radius]:  # Left and right edges
				var biome = _get_biome_at(float(x), float(z))
				if biome == target_biome:
					biome_cache[target_biome] = Vector3(x, 0, z)  # Cache it
					return Vector3(x, 0, z)
	
	return Vector3.ZERO

func _get_terrain_height(world_x: float, world_z: float) -> float:
	"""Get terrain height using chunk_manager's calculation (same as respawn)"""
	if chunk_manager and chunk_manager.has_method("calculate_terrain_height_at_position"):
		return chunk_manager.calculate_terrain_height_at_position(world_x, world_z)
	
	# Fallback to raycast if chunk_manager method not available
	var space_state = get_tree().root.get_world_3d().direct_space_state
	var ray_start = Vector3(world_x, 100, world_z)
	var ray_end = Vector3(world_x, -50, world_z)
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 1  # Terrain layer
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position.y
	
	return 10.0  # Default height

func _teleport_to(position: Vector3):
	"""Teleport player to position and refresh chunks"""
	if player:
		player.global_position = position
		player.velocity = Vector3.ZERO
		
		# v0.8.0: Force chunk system to update around new position
		if chunk_manager and chunk_manager.has_method("update_chunks"):
			# Trigger chunk update (it will use player's new position)
			chunk_manager.update_chunks()
		
		# Trigger vegetation spawner to populate new area
		var veg_spawner = get_tree().get_first_node_in_group("vegetation_spawner")
		if not veg_spawner:
			# Try to find by name
			var parent = get_parent()
			if parent and parent.has_node("VegetationSpawner"):
				veg_spawner = parent.get_node("VegetationSpawner")
		
		if veg_spawner and veg_spawner.has_method("_on_player_chunk_changed"):
			# Calculate chunk position
			var chunk_size = chunk_manager.chunk_size if chunk_manager else 32
			var chunk_x = int(floor(position.x / chunk_size))
			var chunk_z = int(floor(position.z / chunk_size))
			veg_spawner._on_player_chunk_changed(Vector2i(chunk_x, chunk_z))
