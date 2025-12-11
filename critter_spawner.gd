extends Node3D
class_name CritterSpawner

"""
Spawns and manages ambient critters across biomes.

ARCHITECTURE:
- Manages diverse critter types with biome-specific spawning
- Flying critters (eagles) use separate altitude management
- Particle-based critters (fireflies) use simple 3D positions

DEPENDENCIES:
- ChunkManager for terrain/biome data
- DayNightCycle (in "day_night_cycle" group) for time-based spawning
- Collision layer 8 for non-solid critters

PERFORMANCE NOTES:
- Critters are CharacterBody3D but don't use move_and_slide (layer 8, no collisions)
- Raycasting only on movement to minimize overhead
- Particle critters use simple Node3D (no physics body)
"""

# References
var chunk_manager: ChunkManager
var noise: FastNoiseLite
var critter_noise: FastNoiseLite
var player: Node3D
var day_night_cycle: DayNightCycle = null

# Critter density settings - Valheim-inspired ambient life
@export_group("Ground Critter Density")
@export_range(0.0, 1.0) var rabbit_density: float = 0.15  ## Common in grasslands
@export_range(0.0, 1.0) var fox_density: float = 0.10  ## Rare predators
@export_range(0.0, 1.0) var arctic_fox_density: float = 0.12  ## Snow biome
@export_range(0.0, 1.0) var crab_density: float = 0.18  ## Beaches feel alive
@export_range(0.0, 1.0) var lizard_density: float = 0.14  ## Desert activity

@export_group("Flying Critter Density")
@export_range(0.0, 1.0) var butterfly_density: float = 0.25  ## Daytime magic
@export_range(0.0, 1.0) var eagle_density: float = 0.04  ## Rare majesty

@export_group("Particle Critter Density")
@export_range(0.0, 1.0) var firefly_density: float = 0.30  ## Night forest magic

@export_group("Spawn Settings")
@export_range(5, 50) var critters_per_chunk: int = 4  ## More life (was 3)
@export_range(2, 6) var spawn_radius_chunks: int = 3  
@export_range(1.5, 3.0) var despawn_distance_multiplier: float = 2.0  

@export_group("Behavior Settings")
@export_range(1.0, 10.0) var ground_move_speed: float = 2.5  ## Slower, natural (was 3.0)
@export_range(0.5, 5.0) var idle_time_min: float = 1.5  ## Longer pauses (was 1.0)
@export_range(0.5, 5.0) var idle_time_max: float = 4.0  ## More varied (was 3.0)
@export_range(5.0, 15.0) var flying_speed: float = 7.0  ## Graceful (was 8.0)
@export_range(15.0, 40.0) var flying_height_min: float = 18.0  ## Lower eagles (was 20.0)
@export_range(5.0, 20.0) var flying_height_variation: float = 12.0  ## More variety (was 10.0)

# Track spawned critters
var active_critters: Array = []
var populated_chunks: Dictionary = {}
var initialized: bool = false
var last_firefly_check_time: float = -1.0  # Track when we last checked firefly spawning
var last_butterfly_check_time: float = -1.0  # Track when we last checked butterfly spawning

# Critter types
enum CritterType {
	RABBIT,
	BUTTERFLY,
	EAGLE,
	CRAB,
	LIZARD,
	FOX,
	ARCTIC_FOX,
	FIREFLY
}

func _ready():
	critter_noise = FastNoiseLite.new()
	critter_noise.seed = randi()
	critter_noise.frequency = 0.6
	critter_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	
	# Find day/night cycle for firefly spawning
	call_deferred("find_day_night_cycle")

func find_day_night_cycle():
	"""Find DayNightCycle using groups (O(1) lookup)"""
	var cycles = get_tree().get_nodes_in_group("day_night_cycle")
	if cycles.size() > 0:
		day_night_cycle = cycles[0]

func initialize(chunk_mgr: ChunkManager):
	chunk_manager = chunk_mgr
	noise = chunk_manager.noise
	player = chunk_manager.player
	initialized = true

func _process(delta):
	if not initialized or chunk_manager == null or player == null:
		return
	
	var player_pos = player.global_position
	var player_chunk = chunk_manager.world_to_chunk(player_pos)
	
	# Check for time-based firefly spawning every few seconds
	if day_night_cycle:
		var current_time = day_night_cycle.get_time_of_day()
		if abs(current_time - last_firefly_check_time) > 0.01 or last_firefly_check_time < 0:  # Check every ~14 seconds game time
			last_firefly_check_time = current_time
			update_firefly_spawning(player_chunk, current_time)
		
		# Check for time-based butterfly spawning every few seconds
		if abs(current_time - last_butterfly_check_time) > 0.01 or last_butterfly_check_time < 0:
			last_butterfly_check_time = current_time
			update_butterfly_spawning(player_chunk, current_time)
	
	for x in range(player_chunk.x - spawn_radius_chunks, player_chunk.x + spawn_radius_chunks + 1):
		for z in range(player_chunk.y - spawn_radius_chunks, player_chunk.y + spawn_radius_chunks + 1):
			var chunk_pos = Vector2i(x, z)
			if chunk_manager.chunks.has(chunk_pos) and not populated_chunks.has(chunk_pos):
				call_deferred("populate_chunk", chunk_pos)
	
	cleanup_distant_chunks(player_chunk, spawn_radius_chunks * 2)
	cleanup_distant_critters(delta)

func cleanup_distant_chunks(player_chunk: Vector2i, max_distance: int):
	var chunks_to_remove = []
	
	for chunk_pos in populated_chunks.keys():
		var dx = abs(chunk_pos.x - player_chunk.x)
		var dy = abs(chunk_pos.y - player_chunk.y)
		var distance = max(dx, dy)
		
		if distance > max_distance:
			chunks_to_remove.append(chunk_pos)
	
	for chunk_pos in chunks_to_remove:
		var critters_in_chunk = populated_chunks[chunk_pos]
		for critter in critters_in_chunk:
			if is_instance_valid(critter):
				active_critters.erase(critter)
				critter.queue_free()
		
		populated_chunks.erase(chunk_pos)

func update_firefly_spawning(player_chunk: Vector2i, current_time: float):
	"""Dynamically spawn/despawn fireflies based on time of day"""
	# Fireflies active from 10 PM (0.9167) to 6 AM (0.25)
	var is_firefly_time = current_time >= 0.9167 or current_time < 0.25
	
	if is_firefly_time:
		# Time for fireflies - spawn them in forest chunks
		for x in range(player_chunk.x - spawn_radius_chunks, player_chunk.x + spawn_radius_chunks + 1):
			for z in range(player_chunk.y - spawn_radius_chunks, player_chunk.y + spawn_radius_chunks + 1):
				var chunk_pos = Vector2i(x, z)
				if not populated_chunks.has(chunk_pos) or not chunk_manager.chunks.has(chunk_pos):
					continue
				
				# Check if this chunk needs fireflies
				var chunk_key = "fireflies_%d_%d" % [chunk_pos.x, chunk_pos.y]
				if populated_chunks[chunk_pos].any(func(c): return is_instance_valid(c) and c.get_meta("type") == "firefly"):
					continue  # Already has fireflies
				
				# Spawn fireflies in this chunk if it's forest
				var chunk_size = chunk_manager.chunk_size
				var world_offset = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)
				
				for i in range(2):  # Spawn 2 fireflies per forest chunk
					var local_x = randf() * chunk_size
					var local_z = randf() * chunk_size
					var world_x = world_offset.x + local_x
					var world_z = world_offset.y + local_z
					
					var base_noise = noise.get_noise_2d(world_x, world_z)
					var biome = get_biome_at_position(world_x, world_z, base_noise)
					
					if biome != Chunk.Biome.FOREST:
						continue
					
					var height = get_terrain_height_with_raycast(world_x, world_z, base_noise, biome)
					if height < 2.0:
						continue
					
					if randf() < firefly_density:
						var firefly = create_firefly(Vector3(world_x, height, world_z))
						if firefly and populated_chunks.has(chunk_pos):
							populated_chunks[chunk_pos].append(firefly)
	else:
		# Not firefly time - remove all fireflies
		var fireflies_to_remove = []
		for critter in active_critters:
			if is_instance_valid(critter) and critter.get_meta("type") == "firefly":
				fireflies_to_remove.append(critter)
		
		for firefly in fireflies_to_remove:
			active_critters.erase(firefly)
			firefly.queue_free()
		
		# Clean up from populated_chunks tracking
		for chunk_pos in populated_chunks.keys():
			var critters_in_chunk = populated_chunks[chunk_pos]
			var non_fireflies = critters_in_chunk.filter(func(c): return not (is_instance_valid(c) and c.get_meta("type") == "firefly"))
			populated_chunks[chunk_pos] = non_fireflies

func update_butterfly_spawning(player_chunk: Vector2i, current_time: float):
	"""Dynamically spawn/despawn butterflies based on time of day"""
	# Butterflies active from 6 AM (0.25) to 10 PM (0.9167)
	var is_butterfly_time = current_time >= 0.25 and current_time < 0.9167
	
	if is_butterfly_time:
		# Time for butterflies - spawn them in appropriate biome chunks
		for x in range(player_chunk.x - spawn_radius_chunks, player_chunk.x + spawn_radius_chunks + 1):
			for z in range(player_chunk.y - spawn_radius_chunks, player_chunk.y + spawn_radius_chunks + 1):
				var chunk_pos = Vector2i(x, z)
				if not populated_chunks.has(chunk_pos) or not chunk_manager.chunks.has(chunk_pos):
					continue
				
				# Check if this chunk already has butterflies
				if populated_chunks[chunk_pos].any(func(c): return is_instance_valid(c) and c.get_meta("type") == "butterfly"):
					continue
				
				# Spawn butterflies in this chunk if appropriate biome
				var chunk_size = chunk_manager.chunk_size
				var world_offset = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)
				
				for i in range(2):  # Spawn up to 2 butterflies per appropriate chunk
					var local_x = randf() * chunk_size
					var local_z = randf() * chunk_size
					var world_x = world_offset.x + local_x
					var world_z = world_offset.y + local_z
					
					var base_noise = noise.get_noise_2d(world_x, world_z)
					var biome = get_biome_at_position(world_x, world_z, base_noise)
					
					# Butterflies spawn in grassland and forest
					if biome != Chunk.Biome.GRASSLAND and biome != Chunk.Biome.FOREST:
						continue
					
					var height = get_terrain_height_with_raycast(world_x, world_z, base_noise, biome)
					if height < 2.0:
						continue
					
					if randf() < butterfly_density:
						var butterfly = create_butterfly(Vector3(world_x, height, world_z))
						if butterfly and populated_chunks.has(chunk_pos):
							populated_chunks[chunk_pos].append(butterfly)
	else:
		# Not butterfly time - remove all butterflies
		var butterflies_to_remove = []
		for critter in active_critters:
			if is_instance_valid(critter) and critter.get_meta("type") == "butterfly":
				butterflies_to_remove.append(critter)
		
		for butterfly in butterflies_to_remove:
			active_critters.erase(butterfly)
			butterfly.queue_free()
		
		# Clean up from populated_chunks tracking
		for chunk_pos in populated_chunks.keys():
			var critters_in_chunk = populated_chunks[chunk_pos]
			var non_butterflies = critters_in_chunk.filter(func(c): return not (is_instance_valid(c) and c.get_meta("type") == "butterfly"))
			populated_chunks[chunk_pos] = non_butterflies

func _physics_process(delta):
	if not initialized:
		return
	
	for critter in active_critters:
		if not is_instance_valid(critter):
			continue
		
		var critter_type = critter.get_meta("type")
		
		# Different update paths based on critter type
		match critter_type:
			"firefly":
				update_firefly_behavior(critter, delta)
			"butterfly", "eagle":
				update_flying_behavior(critter, delta)
			_:
				update_ground_behavior(critter, delta)

func update_ground_behavior(critter: CharacterBody3D, delta: float):
	"""Ground critters: rabbits, foxes, arctic foxes, crabs, lizards"""
	var critter_type = critter.get_meta("type")
	var move_speed = critter.get_meta("move_speed")
	var state = critter.get_meta("state")
	
	var velocity = Vector3.ZERO
	
	if state == "idle":
		var idle_timer = critter.get_meta("idle_timer")
		idle_timer -= delta
		critter.set_meta("idle_timer", idle_timer)
		
		if idle_timer <= 0.0:
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
		
		# Movement patterns per critter type
		match critter_type:
			"rabbit", "fox", "arctic_fox":
				# Hopping motion
				var hop_timer = critter.get_meta("hop_timer")
				hop_timer += delta
				critter.set_meta("hop_timer", hop_timer)
				
				if hop_timer > 0.5:
					critter.set_meta("hop_timer", 0.0)
					velocity.y = 1.5
				
				velocity.x = move_dir.x * move_speed
				velocity.z = move_dir.z * move_speed
			
			"crab":
				# Sideways scuttling - rotate move direction 90 degrees
				var sideways_dir = Vector3(-move_dir.z, 0, move_dir.x)
				velocity.x = sideways_dir.x * move_speed * 0.8
				velocity.z = sideways_dir.z * move_speed * 0.8
			
			"lizard":
				# Quick darting with pauses
				var dart_timer = critter.get_meta("hop_timer")
				dart_timer += delta
				critter.set_meta("hop_timer", dart_timer)
				
				if dart_timer < 0.3:  # Quick burst
					velocity.x = move_dir.x * move_speed * 2.0
					velocity.z = move_dir.z * move_speed * 2.0
				# else pause (0 velocity)
		
		# Face movement direction
		if move_dir.length() > 0.1:
			var target_rotation = atan2(move_dir.x, move_dir.z)
			critter.rotation.y = lerp_angle(critter.rotation.y, target_rotation, delta * 5.0)
		
		if move_timer <= 0.0:
			critter.set_meta("state", "idle")
			critter.set_meta("idle_timer", randf_range(idle_time_min, idle_time_max))
	
	# Apply movement with terrain snapping
	var new_position = critter.global_position + velocity * delta
	
	if velocity.length_squared() > 0.01:
		var space_state = critter.get_world_3d().direct_space_state
		if space_state:
			var ray_start = Vector3(new_position.x, new_position.y + 2.0, new_position.z)
			var ray_end = Vector3(new_position.x, new_position.y - 5.0, new_position.z)
			
			var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
			query.collision_mask = 1
			
			var result = space_state.intersect_ray(query)
			if result:
				new_position.y = result.position.y + 0.1
	
	critter.global_position = new_position

func update_flying_behavior(critter: CharacterBody3D, delta: float):
	"""Flying critters: butterflies (flutter/erratic), eagles (circling overhead)"""
	var critter_type = critter.get_meta("type")
	var move_speed = critter.get_meta("move_speed")
	var base_height = critter.get_meta("base_height")
	
	if critter_type == "butterfly":
		# Erratic butterfly flight with direction changes
		var time = Time.get_ticks_msec() * 0.001
		
		# Change direction randomly every 2-3 seconds
		if not critter.has_meta("direction_change_time"):
			critter.set_meta("direction_change_time", time)
		
		var last_change = critter.get_meta("direction_change_time")
		if time - last_change > randf_range(2.0, 3.0):
			# Pick new random direction
			var new_dir = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
			critter.set_meta("move_direction", new_dir)
			critter.set_meta("direction_change_time", time)
		
		# Fluttering motion - combination of bobbing and zigzag
		var flutter_speed = 8.0
		var bob = sin(time * flutter_speed) * 0.3  # Vertical bobbing
		var zigzag_x = sin(time * flutter_speed * 1.3) * 0.2  # Side-to-side zigzag
		var zigzag_z = cos(time * flutter_speed * 0.9) * 0.2  # Forward-back zigzag
		
		critter.global_position.y = base_height + bob
		
		# Apply drift in current direction with zigzag overlay
		var drift_dir = critter.get_meta("move_direction")
		var flutter_offset = Vector3(zigzag_x, 0, zigzag_z)
		critter.global_position += (drift_dir * move_speed * delta * 0.5) + (flutter_offset * delta)
		
		# Wing flapping animation - rotate the entire butterfly slightly
		var wing_flap = sin(time * flutter_speed) * 0.3  # More dramatic flapping
		critter.rotation.z = wing_flap
		
		# Tilt forward slightly in direction of movement
		if drift_dir.length() > 0.1:
			var target_rotation = atan2(drift_dir.x, drift_dir.z)
			critter.rotation.y = lerp_angle(critter.rotation.y, target_rotation, delta * 3.0)
	
	elif critter_type == "eagle":
		# Circling flight pattern
		var time = Time.get_ticks_msec() * 0.001
		var circle_center = critter.get_meta("circle_center")
		var circle_radius = critter.get_meta("circle_radius")
		var circle_speed = critter.get_meta("circle_speed")
		
		var angle = time * circle_speed
		var offset_x = cos(angle) * circle_radius
		var offset_z = sin(angle) * circle_radius
		
		critter.global_position = circle_center + Vector3(offset_x, 0, offset_z)
		critter.global_position.y = base_height
		
		# Face direction of flight
		var next_angle = angle + 0.1
		var next_x = cos(next_angle) * circle_radius
		var next_z = sin(next_angle) * circle_radius
		var look_dir = Vector3(next_x - offset_x, 0, next_z - offset_z).normalized()
		critter.rotation.y = atan2(look_dir.x, look_dir.z)

func update_firefly_behavior(critter: Node3D, delta: float):
	"""Fireflies: simple particle-like floating with glow"""
	var time = Time.get_ticks_msec() * 0.001
	var base_pos = critter.get_meta("base_position")
	var float_radius = critter.get_meta("float_radius")
	var float_speed = critter.get_meta("float_speed")
	var pulse_offset = critter.get_meta("pulse_offset")
	
	# Random floating pattern
	var offset_x = sin(time * float_speed + base_pos.x) * float_radius
	var offset_y = sin(time * float_speed * 1.3 + base_pos.y) * (float_radius * 0.5)
	var offset_z = cos(time * float_speed + base_pos.z) * float_radius
	
	critter.global_position = base_pos + Vector3(offset_x, offset_y, offset_z)
	
	# Smooth pulsing glow (slower, more organic)
	var glow_pulse = 0.4 + sin(time * 2.0 + pulse_offset) * 0.6  # 0.4 to 1.0 range
	
	# Update core glow (brightest) - dimmer values
	var core_mesh = critter.get_child(0) as MeshInstance3D
	if core_mesh:
		var mat = core_mesh.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 1.8 * glow_pulse  # Reduced from 2.5
			var pulse_color = Color(0.8, 0.9, 0.35).lerp(Color(0.6, 0.8, 0.25), 1.0 - glow_pulse)
			mat.emission = pulse_color
	
	# Update inner halo (medium glow)
	if critter.get_child_count() > 1:
		var halo_mesh = critter.get_child(1) as MeshInstance3D
		if halo_mesh:
			var mat = halo_mesh.material_override as StandardMaterial3D
			if mat:
				mat.emission_energy_multiplier = 0.9 * glow_pulse  # Reduced from 1.2
				var pulse_color = Color(0.8, 0.9, 0.35).lerp(Color(0.6, 0.8, 0.25), 1.0 - glow_pulse)
				mat.emission = pulse_color
	
	# Update outer diffuse halo (subtle glow)
	if critter.get_child_count() > 2:
		var outer_mesh = critter.get_child(2) as MeshInstance3D
		if outer_mesh:
			var mat = outer_mesh.material_override as StandardMaterial3D
			if mat:
				mat.emission_energy_multiplier = 0.4 * glow_pulse  # Reduced from 0.6
				var pulse_color = Color(0.8, 0.9, 0.35).lerp(Color(0.6, 0.8, 0.25), 1.0 - glow_pulse)
				mat.emission = pulse_color

func populate_chunk(chunk_pos: Vector2i):
	if populated_chunks.has(chunk_pos):
		return
	
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
		
		if biome == Chunk.Biome.OCEAN:
			continue
		
		var height = get_terrain_height_with_raycast(world_x, world_z, base_noise, biome)
		
		# Use biome-specific height thresholds
		# Beach/coastal areas are lower elevation, so crabs need lower threshold
		var min_height = 2.0  # Default for most biomes
		if biome == Chunk.Biome.BEACH:
			min_height = 0.3  # Beaches are ~0.5-1.5m high, allow spawning just above water
		
		if height < min_height:
			continue
		
		var critter = spawn_critter_for_biome(biome, Vector3(world_x, height, world_z))
		if critter:
			populated_chunks[chunk_pos].append(critter)

func spawn_critter_for_biome(biome: Chunk.Biome, spawn_pos: Vector3):
	"""Spawn biome-appropriate critter"""
	var critter_type: CritterType
	var rand = randf()
	
	# Check for night-time only critters first (fireflies start at 10 PM)
	if biome == Chunk.Biome.FOREST and day_night_cycle:
		var time_of_day = day_night_cycle.get_time_of_day()
		# 10 PM = 22/24 = 0.9167, fireflies active from 10 PM to 6 AM
		var is_firefly_time = time_of_day >= 0.9167 or time_of_day < 0.25
		
		if is_firefly_time and rand < firefly_density:
			return create_firefly(spawn_pos)
	
	# Biome-specific spawning
	match biome:
		Chunk.Biome.GRASSLAND:
			if rand < rabbit_density:
				critter_type = CritterType.RABBIT
			elif rand < rabbit_density + eagle_density:
				critter_type = CritterType.EAGLE
			else:
				return null
		
		Chunk.Biome.FOREST:
			if rand < rabbit_density * 0.5:
				critter_type = CritterType.RABBIT
			elif rand < rabbit_density * 0.5 + fox_density:
				critter_type = CritterType.FOX
			else:
				return null
		
		Chunk.Biome.BEACH:
			if rand < crab_density:
				# TODO: Add shoreline proximity check back once basic spawning works
				# For now, spawn anywhere on beach for testing
				critter_type = CritterType.CRAB
			else:
				return null
		
		Chunk.Biome.DESERT:
			if rand < lizard_density:
				critter_type = CritterType.LIZARD
			elif rand < lizard_density + eagle_density:
				critter_type = CritterType.EAGLE
			else:
				return null
		
		Chunk.Biome.SNOW:
			if rand < arctic_fox_density:
				critter_type = CritterType.ARCTIC_FOX
			else:
				return null
		
		Chunk.Biome.MOUNTAIN:
			if rand < eagle_density * 2.0:  # More eagles in mountains
				critter_type = CritterType.EAGLE
			else:
				return null
		
		_:
			return null
	
	return create_critter(critter_type, spawn_pos)

func create_critter(critter_type: CritterType, spawn_position: Vector3) -> CharacterBody3D:
	var critter = CharacterBody3D.new()
	add_child(critter)
	critter.global_position = spawn_position
	
	critter.collision_layer = 8
	critter.collision_mask = 0
	critter.floor_stop_on_slope = true
	critter.floor_max_angle = deg_to_rad(46)
	critter.floor_snap_length = 0.5
	
	var mesh_instance = MeshInstance3D.new()
	critter.add_child(mesh_instance)
	
	var collision = CollisionShape3D.new()
	critter.add_child(collision)
	
	# Setup based on type
	match critter_type:
		CritterType.RABBIT:
			critter.set_meta("type", "rabbit")
			critter.set_meta("move_speed", ground_move_speed)
			create_rabbit_visual(mesh_instance, collision)
		
		CritterType.FOX:
			critter.set_meta("type", "fox")
			critter.set_meta("move_speed", ground_move_speed * 1.2)
			create_fox_visual(mesh_instance, collision, Color(0.8, 0.4, 0.1))
		
		CritterType.ARCTIC_FOX:
			critter.set_meta("type", "arctic_fox")
			critter.set_meta("move_speed", ground_move_speed)
			create_fox_visual(mesh_instance, collision, Color(0.95, 0.95, 1.0))
		
		CritterType.CRAB:
			critter.set_meta("type", "crab")
			critter.set_meta("move_speed", ground_move_speed * 0.7)
			create_crab_visual(mesh_instance, collision)
		
		CritterType.LIZARD:
			critter.set_meta("type", "lizard")
			critter.set_meta("move_speed", ground_move_speed * 1.5)
			create_lizard_visual(mesh_instance, collision)
		
		CritterType.BUTTERFLY:
			critter.set_meta("type", "butterfly")
			critter.set_meta("move_speed", flying_speed * 0.3)
			var fly_height = spawn_position.y + 0.5 + randf() * 1.5  # Just 0.5-2m above ground
			critter.global_position.y = fly_height
			critter.set_meta("base_height", fly_height)
			critter.set_meta("move_direction", Vector3(randf() - 0.5, 0, randf() - 0.5).normalized())
			create_butterfly_visual(mesh_instance, collision)
		
		CritterType.EAGLE:
			critter.set_meta("type", "eagle")
			critter.set_meta("move_speed", flying_speed)
			var fly_height = spawn_position.y + flying_height_min + randf() * flying_height_variation
			critter.global_position.y = fly_height
			critter.set_meta("base_height", fly_height)
			critter.set_meta("circle_center", Vector3(spawn_position.x, fly_height, spawn_position.z))
			critter.set_meta("circle_radius", 15.0 + randf() * 20.0)  # Tighter circles for visibility
			critter.set_meta("circle_speed", 0.15 + randf() * 0.2)  # Slower for visibility
			# Random size variation (80% to 120% of base size)
			var size_scale = 0.8 + randf() * 0.4
			critter.set_meta("size_scale", size_scale)
			create_eagle_visual(mesh_instance, collision, size_scale)
	
	# Common behavior metadata
	critter.set_meta("state", "idle")
	critter.set_meta("idle_timer", randf_range(idle_time_min, idle_time_max))
	critter.set_meta("move_direction", Vector3.ZERO)
	critter.set_meta("hop_timer", 0.0)
	critter.set_meta("move_timer", 0.0)
	
	active_critters.append(critter)
	critter.set_physics_process(true)
	
	return critter

func create_butterfly(spawn_position: Vector3) -> CharacterBody3D:
	"""Create a butterfly critter for time-based spawning"""
	var critter = CharacterBody3D.new()
	add_child(critter)
	critter.global_position = spawn_position
	
	critter.collision_layer = 8
	critter.collision_mask = 0
	critter.floor_stop_on_slope = true
	critter.floor_max_angle = deg_to_rad(46)
	critter.floor_snap_length = 0.5
	
	var mesh_instance = MeshInstance3D.new()
	critter.add_child(mesh_instance)
	
	var collision = CollisionShape3D.new()
	critter.add_child(collision)
	
	critter.set_meta("type", "butterfly")
	critter.set_meta("move_speed", flying_speed * 0.3)
	var fly_height = spawn_position.y + 0.5 + randf() * 1.5  # Just 0.5-2m above ground
	critter.global_position.y = fly_height
	critter.set_meta("base_height", fly_height)
	critter.set_meta("move_direction", Vector3(randf() - 0.5, 0, randf() - 0.5).normalized())
	create_butterfly_visual(mesh_instance, collision)
	
	# Common behavior metadata
	critter.set_meta("state", "idle")
	critter.set_meta("idle_timer", randf_range(idle_time_min, idle_time_max))
	critter.set_meta("hop_timer", 0.0)
	critter.set_meta("move_timer", 0.0)
	
	active_critters.append(critter)
	critter.set_physics_process(true)
	
	return critter

func create_firefly(spawn_position: Vector3) -> Node3D:
	"""Fireflies are simple Node3D with glowing mesh (no physics)"""
	var firefly = Node3D.new()
	add_child(firefly)
	firefly.global_position = spawn_position + Vector3(0, 1.0, 0)
	
	# Create tiny core sphere
	var mesh = MeshInstance3D.new()
	firefly.add_child(mesh)
	
	var sphere = SphereMesh.new()
	sphere.radius = 0.03  # Smaller core
	sphere.height = 0.06
	mesh.mesh = sphere
	
	# Warm yellow-green firefly glow - dimmer
	var glow_color = Color(0.8, 0.9, 0.35)  # Less saturated yellow-green
	
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = glow_color
	material.emission_enabled = true
	material.emission = glow_color
	material.emission_energy_multiplier = 1.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED  # Don't write to depth buffer
	mesh.material_override = material
	mesh.layers = 1
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Add medium soft glow halo
	var glow_mesh = MeshInstance3D.new()
	firefly.add_child(glow_mesh)
	
	var glow_sphere = SphereMesh.new()
	glow_sphere.radius = 0.12
	glow_sphere.height = 0.24
	glow_mesh.mesh = glow_sphere
	
	var glow_material = StandardMaterial3D.new()
	glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_material.albedo_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.15)
	glow_material.emission_enabled = true
	glow_material.emission = glow_color
	glow_material.emission_energy_multiplier = 0.9
	glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	glow_mesh.material_override = glow_material
	glow_mesh.layers = 1
	glow_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Add outer diffuse glow (very soft, large radius)
	var outer_glow = MeshInstance3D.new()
	firefly.add_child(outer_glow)
	
	var outer_sphere = SphereMesh.new()
	outer_sphere.radius = 0.25  # Large diffuse halo
	outer_sphere.height = 0.5
	outer_glow.mesh = outer_sphere
	
	var outer_material = StandardMaterial3D.new()
	outer_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outer_material.albedo_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.08)
	outer_material.emission_enabled = true
	outer_material.emission = glow_color
	outer_material.emission_energy_multiplier = 0.4
	outer_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outer_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	outer_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	outer_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	outer_glow.material_override = outer_material
	outer_glow.layers = 1
	outer_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	firefly.set_meta("type", "firefly")
	firefly.set_meta("base_position", spawn_position + Vector3(0, 1.5, 0))
	firefly.set_meta("float_radius", 1.0 + randf() * 1.5)
	firefly.set_meta("float_speed", 0.5 + randf() * 1.0)
	firefly.set_meta("pulse_offset", randf() * TAU)
	
	active_critters.append(firefly)
	
	return firefly

func create_rabbit_visual(mesh_instance: MeshInstance3D, collision: CollisionShape3D):
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var body_color = Color(0.35, 0.25, 0.18)
	var ear_color = Color(0.4, 0.3, 0.22)
	var tail_color = Color(0.5, 0.4, 0.32)
	
	# Scale down by 50% for more realistic size
	var s = 0.5
	
	# Body (main sphere)
	add_box(surface_tool, Vector3(0, 0.3, 0) * s, Vector3(0.45, 0.375, 0.6) * s, body_color)
	# Head (smaller sphere)
	add_box(surface_tool, Vector3(0, 0.525, 0.375) * s, Vector3(0.3, 0.3, 0.375) * s, body_color)
	# Ears (tall boxes)
	add_box(surface_tool, Vector3(-0.12, 0.825, 0.45) * s, Vector3(0.075, 0.225, 0.12) * s, ear_color)
	add_box(surface_tool, Vector3(0.12, 0.825, 0.45) * s, Vector3(0.075, 0.225, 0.12) * s, ear_color)
	# Tail (small fluffy ball)
	add_box(surface_tool, Vector3(0, 0.375, -0.3) * s, Vector3(0.15, 0.15, 0.15) * s, tail_color)
	# Legs (4 small boxes)
	add_box(surface_tool, Vector3(-0.12, 0.05, 0.1) * s, Vector3(0.06, 0.08, 0.06) * s, body_color)
	add_box(surface_tool, Vector3(0.12, 0.05, 0.1) * s, Vector3(0.06, 0.08, 0.06) * s, body_color)
	add_box(surface_tool, Vector3(-0.12, 0.05, -0.1) * s, Vector3(0.06, 0.08, 0.06) * s, body_color)
	add_box(surface_tool, Vector3(0.12, 0.05, -0.1) * s, Vector3(0.06, 0.08, 0.06) * s, body_color)
	
	finalize_mesh(surface_tool, mesh_instance)
	
	var shape = CapsuleShape3D.new()
	shape.radius = 0.3 * s
	shape.height = 0.6 * s
	collision.shape = shape
	collision.position.y = 0.3 * s

func create_fox_visual(mesh_instance: MeshInstance3D, collision: CollisionShape3D, body_color: Color):
	"""Fox - similar to rabbit but longer/sleeker"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var ear_color = body_color.lightened(0.1)
	var tail_color = body_color.darkened(0.1)
	
	# Longer body
	add_box(surface_tool, Vector3(0, 0.3, 0), Vector3(0.4, 0.35, 0.8), body_color)
	# Head
	add_box(surface_tool, Vector3(0, 0.4, 0.5), Vector3(0.35, 0.3, 0.4), body_color)
	# Pointy ears
	add_box(surface_tool, Vector3(-0.15, 0.65, 0.6), Vector3(0.08, 0.2, 0.08), ear_color)
	add_box(surface_tool, Vector3(0.15, 0.65, 0.6), Vector3(0.08, 0.2, 0.08), ear_color)
	# Bushy tail
	add_box(surface_tool, Vector3(0, 0.35, -0.5), Vector3(0.2, 0.2, 0.3), tail_color)
	# Legs
	add_box(surface_tool, Vector3(-0.15, 0.05, 0.3), Vector3(0.06, 0.08, 0.06), body_color)
	add_box(surface_tool, Vector3(0.15, 0.05, 0.3), Vector3(0.06, 0.08, 0.06), body_color)
	add_box(surface_tool, Vector3(-0.15, 0.05, -0.2), Vector3(0.06, 0.08, 0.06), body_color)
	add_box(surface_tool, Vector3(0.15, 0.05, -0.2), Vector3(0.06, 0.08, 0.06), body_color)
	
	finalize_mesh(surface_tool, mesh_instance)
	
	var shape = CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 0.7
	collision.shape = shape
	collision.position.y = 0.35

func create_crab_visual(mesh_instance: MeshInstance3D, collision: CollisionShape3D):
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var shell_color = Color(0.8, 0.3, 0.2)
	var claw_color = Color(0.85, 0.35, 0.25)
	
	# Wide flat body
	add_box(surface_tool, Vector3(0, 0.15, 0), Vector3(0.5, 0.2, 0.4), shell_color)
	# Big claws
	add_box(surface_tool, Vector3(-0.4, 0.2, 0.15), Vector3(0.2, 0.15, 0.15), claw_color)
	add_box(surface_tool, Vector3(0.4, 0.2, 0.15), Vector3(0.2, 0.15, 0.15), claw_color)
	# 6 legs (3 each side)
	add_box(surface_tool, Vector3(-0.3, 0.05, 0.2), Vector3(0.05, 0.05, 0.05), shell_color)
	add_box(surface_tool, Vector3(-0.3, 0.05, 0), Vector3(0.05, 0.05, 0.05), shell_color)
	add_box(surface_tool, Vector3(-0.3, 0.05, -0.2), Vector3(0.05, 0.05, 0.05), shell_color)
	add_box(surface_tool, Vector3(0.3, 0.05, 0.2), Vector3(0.05, 0.05, 0.05), shell_color)
	add_box(surface_tool, Vector3(0.3, 0.05, 0), Vector3(0.05, 0.05, 0.05), shell_color)
	add_box(surface_tool, Vector3(0.3, 0.05, -0.2), Vector3(0.05, 0.05, 0.05), shell_color)
	
	finalize_mesh(surface_tool, mesh_instance)
	
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.5, 0.2, 0.4)
	collision.shape = shape
	collision.position.y = 0.15

func create_lizard_visual(mesh_instance: MeshInstance3D, collision: CollisionShape3D):
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var body_color = Color(0.4, 0.6, 0.3)
	var stripe_color = Color(0.5, 0.7, 0.4)
	
	# Scale down by 60% for realistic lizard size
	var s = 0.4
	
	# Small flat body
	add_box(surface_tool, Vector3(0, 0.08, 0) * s, Vector3(0.25, 0.1, 0.5) * s, body_color)
	# Head
	add_box(surface_tool, Vector3(0, 0.08, 0.3) * s, Vector3(0.2, 0.08, 0.2) * s, body_color)
	# Stripe down back
	add_box(surface_tool, Vector3(0, 0.14, 0) * s, Vector3(0.08, 0.02, 0.5) * s, stripe_color)
	# Long tail
	add_box(surface_tool, Vector3(0, 0.08, -0.4) * s, Vector3(0.06, 0.06, 0.4) * s, body_color)
	# 4 legs
	add_box(surface_tool, Vector3(-0.12, 0.03, 0.15) * s, Vector3(0.04, 0.04, 0.04) * s, body_color)
	add_box(surface_tool, Vector3(0.12, 0.03, 0.15) * s, Vector3(0.04, 0.04, 0.04) * s, body_color)
	add_box(surface_tool, Vector3(-0.12, 0.03, -0.15) * s, Vector3(0.04, 0.04, 0.04) * s, body_color)
	add_box(surface_tool, Vector3(0.12, 0.03, -0.15) * s, Vector3(0.04, 0.04, 0.04) * s, body_color)
	
	finalize_mesh(surface_tool, mesh_instance)
	
	var shape = CapsuleShape3D.new()
	shape.radius = 0.15 * s
	shape.height = 0.5 * s
	collision.shape = shape
	collision.position.y = 0.08 * s

func create_butterfly_visual(mesh_instance: MeshInstance3D, collision: CollisionShape3D):
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Random butterfly color variations
	var color_type = randi() % 5
	var wing_color: Color
	
	match color_type:
		0:  # Monarch orange
			wing_color = Color(0.95, 0.6, 0.2)
		1:  # Yellow
			wing_color = Color(0.95, 0.9, 0.3)
		2:  # White/pale
			wing_color = Color(0.95, 0.95, 0.9)
		3:  # Blue (morpho butterfly)
			wing_color = Color(0.3, 0.6, 0.95)
		4:  # Red/orange
			wing_color = Color(0.95, 0.4, 0.3)
	
	var body_color = Color(0.15, 0.15, 0.15)  # Dark body
	
	# Much smaller butterfly - real-life scale (~10cm wingspan)
	# Thin body
	add_box(surface_tool, Vector3(0, 0, 0), Vector3(0.01, 0.01, 0.06), body_color)
	# Wings - delicate and small
	add_box(surface_tool, Vector3(-0.06, 0, 0), Vector3(0.06, 0.005, 0.05), wing_color)
	add_box(surface_tool, Vector3(0.06, 0, 0), Vector3(0.06, 0.005, 0.05), wing_color)
	
	finalize_mesh(surface_tool, mesh_instance)
	
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.12, 0.02, 0.06)
	collision.shape = shape

func create_eagle_visual(mesh_instance: MeshInstance3D, collision: CollisionShape3D, size_scale: float = 1.0):
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Random eagle color variations
	var color_type = randi() % 4
	var body_color: Color
	var wing_color: Color
	var beak_color = Color(0.8, 0.7, 0.3)  # Yellow beak for all
	
	match color_type:
		0:  # Dark brown eagle
			body_color = Color(0.25, 0.2, 0.15)
			wing_color = Color(0.35, 0.3, 0.25)
		1:  # Light brown/tan
			body_color = Color(0.45, 0.4, 0.3)
			wing_color = Color(0.55, 0.5, 0.4)
		2:  # Gray eagle
			body_color = Color(0.3, 0.3, 0.3)
			wing_color = Color(0.4, 0.4, 0.4)
		3:  # Black eagle
			body_color = Color(0.15, 0.15, 0.15)
			wing_color = Color(0.25, 0.25, 0.25)
	
	# Smaller base size (0.8x instead of 2x), then apply individual size variation
	var s = 0.8 * size_scale
	
	# Body
	add_box(surface_tool, Vector3(0, 0, 0), Vector3(0.4, 0.4, 0.8) * s, body_color)
	# Head
	add_box(surface_tool, Vector3(0, 0.2, 0.5) * s, Vector3(0.35, 0.35, 0.4) * s, body_color)
	# Beak
	add_box(surface_tool, Vector3(0, 0.15, 0.75) * s, Vector3(0.1, 0.1, 0.15) * s, beak_color)
	# Wings - reasonable wingspan
	add_box(surface_tool, Vector3(-1.2, 0, 0) * s, Vector3(1.0, 0.15, 0.6) * s, wing_color)
	add_box(surface_tool, Vector3(1.2, 0, 0) * s, Vector3(1.0, 0.15, 0.6) * s, wing_color)
	# Tail
	add_box(surface_tool, Vector3(0, 0, -0.6) * s, Vector3(0.4, 0.1, 0.3) * s, body_color)
	
	finalize_mesh(surface_tool, mesh_instance)
	
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.8, 0.4, 0.8) * s
	collision.shape = shape

func add_box(surface_tool: SurfaceTool, center: Vector3, size: Vector3, color: Color):
	var half = size / 2.0
	
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
	
	var faces = [
		[0, 1, 2, 3],
		[4, 7, 6, 5],
		[0, 4, 5, 1],
		[2, 6, 7, 3],
		[0, 3, 7, 4],
		[1, 5, 6, 2],
	]
	
	for face in faces:
		surface_tool.set_color(color)
		surface_tool.add_vertex(corners[face[0]])
		surface_tool.add_vertex(corners[face[1]])
		surface_tool.add_vertex(corners[face[2]])
		
		surface_tool.add_vertex(corners[face[0]])
		surface_tool.add_vertex(corners[face[2]])
		surface_tool.add_vertex(corners[face[3]])

func finalize_mesh(surface_tool: SurfaceTool, mesh_instance: MeshInstance3D):
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.roughness = 0.8
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(1.5, 1.5, 1.5)
	
	mesh_instance.set_surface_override_material(0, material)

func cleanup_distant_critters(delta: float):
	if not player or not chunk_manager:
		return
	
	var player_pos = player.global_position
	var critters_to_remove = []
	
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
	var calculated_height = get_terrain_height_at_position(world_x, world_z, base_noise, biome)
	
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return calculated_height
	
	var ray_start = Vector3(world_x, calculated_height + 10.0, world_z)
	var ray_end = Vector3(world_x, calculated_height - 2.0, world_z)
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position.y
	
	return calculated_height

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
