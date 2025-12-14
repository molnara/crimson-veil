extends Node3D
class_name VegetationSpawner

"""
VegetationSpawner - Procedurally populates chunks with vegetation and resources

v0.8.0: Refactored into modular files for easier maintenance
- vegetation_types.gd: VegType enum and visibility settings
- biome_spawn_rules.gd: What spawns where
- meshes/*.gd: Individual mesh creation functions

ARCHITECTURE:
- Spawns vegetation in 2-chunk radius around player
- Two-pass system: large vegetation then ground cover
- Uses noise for natural placement and biome-specific distributions
"""

# Import modular files
const VT = preload("res://vegetation/vegetation_types.gd")
const BiomeRules = preload("res://vegetation/biome_spawn_rules.gd")
const TreeMeshes = preload("res://vegetation/meshes/tree_meshes.gd")
const RockMeshes = preload("res://vegetation/meshes/rock_meshes.gd")
const SnowMeshes = preload("res://vegetation/meshes/snow_meshes.gd")
const DesertMeshes = preload("res://vegetation/meshes/desert_meshes.gd")
const ForestMeshes = preload("res://vegetation/meshes/forest_meshes.gd")
const GroundCoverMeshes = preload("res://vegetation/meshes/ground_cover_meshes.gd")
const PlantMeshes = preload("res://vegetation/meshes/plant_meshes.gd")

# Preload tree visual generators (used by TreeMeshes)
const TreeVisual = preload("res://vegetation/visuals/tree_visual.gd")
const PineTreeVisual = preload("res://vegetation/visuals/pine_tree_visual.gd")
const PalmTreeVisual = preload("res://vegetation/visuals/palm_tree_visual.gd")

# Preload harvestable resource classes
const HarvestableMushroomClass = preload("res://harvestable_mushroom.gd")
const HarvestableStrawberryClass = preload("res://harvestable_strawberry.gd")
const ResourceNodeClass = preload("res://resource_node.gd")

# References
var chunk_manager: ChunkManager
var noise: FastNoiseLite
var vegetation_noise: FastNoiseLite
var cluster_noise: FastNoiseLite
var player: Node3D

# Vegetation density settings
@export_group("Vegetation Density")
@export_range(0.0, 1.0) var tree_density: float = 0.40
@export_range(0.0, 1.0) var rock_density: float = 0.08  ## Rare - requires exploration
@export_range(0.0, 1.0) var mushroom_density: float = 0.04  ## Very rare forest delicacy
@export_range(0.0, 1.0) var strawberry_density: float = 0.06  ## Rare food source
@export_range(0.0, 1.0) var grass_density: float = 0.30
@export_range(0.0, 1.0) var flower_density: float = 0.18
@export_range(1, 5) var spawn_radius: int = 2

@export_group("Tree Size Variation")
@export_range(2.0, 15.0) var tree_height_min: float = 4.0
@export_range(2.0, 15.0) var tree_height_max: float = 10.0
@export_range(0.1, 1.0) var trunk_radius_base: float = 0.35

@export_group("Tree Branch Settings")
@export_range(2, 8) var branch_count_min: int = 3
@export_range(2, 8) var branch_count_max: int = 6
@export_range(0.5, 3.0) var branch_length_min: float = 1.5
@export_range(0.5, 3.0) var branch_length_max: float = 2.2
@export_range(0.0, 1.0) var branch_height_start: float = 0.45
@export_range(0.0, 1.0) var branch_height_end: float = 0.85
@export_range(0.0, 0.5) var branch_upward_angle: float = 0.20

@export_group("Tree Foliage Settings")
@export_range(2, 8) var branch_foliage_layers: int = 5
@export_range(2, 10) var top_foliage_layers: int = 6
@export_range(0.1, 1.0) var foliage_disc_thickness: float = 0.45
@export_range(0.0, 1.0) var foliage_layer_gap: float = 0.15
@export_range(0.5, 2.0) var foliage_disc_size: float = 0.80
@export_range(0.7, 1.0) var top_crown_height_ratio: float = 0.85

@export_group("Tree Trunk Tilt Settings")
@export_range(0.0, 0.4) var trunk_tilt_max: float = 0.12
@export_range(0.0, 1.0) var trunk_tilt_influence: float = 0.65

@export_group("Character Tree Settings")
@export_range(0.0, 0.15) var character_tree_chance: float = 0.08
@export_range(0.0, 1.0) var branch_asymmetry_amount: float = 0.35

@export_group("Ground Cover Settings")
@export_range(10, 150) var ground_cover_samples_per_chunk: int = 80
@export_range(5, 50) var large_vegetation_samples_per_chunk: int = 35

@export_group("Forest Biome Configuration")
@export_range(0.0, 1.0) var forest_tree_density: float = 0.60
@export_range(0.0, 1.0) var forest_mushroom_density: float = 0.10  ## Occasional forest finds
@export_range(0.0, 1.0) var forest_rock_density: float = 0.08

@export_group("Grassland Biome Configuration")
@export_range(0.0, 1.0) var grassland_tree_density: float = 0.30
@export_range(0.0, 1.0) var grassland_strawberry_density: float = 0.12  ## Occasional berry patches, need to search
@export_range(0.0, 1.0) var grassland_rock_density: float = 0.10

@export_group("Mountain Biome Configuration")
@export_range(0.0, 1.0) var mountain_pine_density: float = 0.30
@export_range(0.0, 1.0) var mountain_rock_density: float = 0.15  ## Mountains have more rocks but still sparse
@export_range(0.0, 1.0) var mountain_boulder_ratio: float = 0.35

@export_group("Snow Biome Configuration")
@export_range(0.0, 1.0) var snow_pine_density: float = 0.35
@export_range(0.0, 1.0) var snow_rock_density: float = 0.10

@export_group("Desert Biome Configuration")
@export_range(0.0, 1.0) var desert_cactus_density: float = 0.35
@export_range(0.0, 1.0) var desert_rock_density: float = 0.12

@export_group("Beach Biome Configuration")
@export_range(0.0, 1.0) var beach_palm_density: float = 0.40
@export_range(0.0, 1.0) var beach_rock_density: float = 0.08

# Tracking
var populated_chunks: Dictionary = {}
var initialized: bool = false
var _current_chunk: Vector2i = Vector2i.ZERO
var _chunk_grass_positions: Array = []
var _cached_grass_blade_mesh: ArrayMesh = null

# Tree shape types
enum TreeShape { PYRAMIDAL, ROUND, SPREADING, WIDE_SPREAD }


func _ready():
	vegetation_noise = FastNoiseLite.new()
	vegetation_noise.seed = randi()
	vegetation_noise.frequency = 0.5
	vegetation_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	
	cluster_noise = FastNoiseLite.new()
	cluster_noise.seed = vegetation_noise.seed + 1000
	cluster_noise.frequency = 0.15
	cluster_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	print("VegetationSpawner ready, waiting for initialization...")


func initialize(chunk_mgr: ChunkManager):
	chunk_manager = chunk_mgr
	noise = chunk_manager.noise
	player = chunk_manager.player
	
	if not chunk_manager.chunk_unloaded.is_connected(_on_chunk_unloaded):
		chunk_manager.chunk_unloaded.connect(_on_chunk_unloaded)
	
	initialized = true
	print("VegetationSpawner initialized with player and chunk manager")


func _process(_delta):
	if not initialized or chunk_manager == null or player == null:
		return
	
	var player_pos = player.global_position
	var player_chunk = chunk_manager.world_to_chunk(player_pos)
	
	for x in range(player_chunk.x - spawn_radius, player_chunk.x + spawn_radius + 1):
		for z in range(player_chunk.y - spawn_radius, player_chunk.y + spawn_radius + 1):
			var chunk_pos = Vector2i(x, z)
			if not populated_chunks.has(chunk_pos) and chunk_manager.chunks.has(chunk_pos):
				populate_chunk(chunk_pos)


func _on_chunk_unloaded(chunk_pos: Vector2i):
	if not populated_chunks.has(chunk_pos):
		return
	
	var vegetation_nodes = populated_chunks[chunk_pos]
	for node in vegetation_nodes:
		if is_instance_valid(node):
			node.queue_free()
	
	populated_chunks.erase(chunk_pos)


func populate_chunk(chunk_pos: Vector2i):
	if populated_chunks.has(chunk_pos):
		return
	
	populated_chunks[chunk_pos] = []
	_current_chunk = chunk_pos
	_chunk_grass_positions = []
	
	var chunk_size = chunk_manager.chunk_size
	var world_offset = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)
	
	# Build config dictionary for BiomeRules
	var config = _get_spawn_config()
	
	# DEBUG: Track spawn counts
	var spawn_counts = {}
	var biome_counts = {}
	
	# PASS 1: Large vegetation
	for i in range(large_vegetation_samples_per_chunk):
		var local_x = randf() * chunk_size
		var local_z = randf() * chunk_size
		var world_x = world_offset.x + local_x
		var world_z = world_offset.y + local_z
		
		var base_noise = noise.get_noise_2d(world_x, world_z)
		var biome = get_biome_at_position(world_x, world_z, base_noise)
		
		# DEBUG: Count biomes
		var biome_name = Chunk.Biome.keys()[biome]
		biome_counts[biome_name] = biome_counts.get(biome_name, 0) + 1
		
		if biome == Chunk.Biome.OCEAN:
			continue
		
		var height = get_terrain_height_with_raycast(world_x, world_z, base_noise, biome)
		if height < 0.5:
			continue
		
		var spawn_pos = Vector3(world_x, height, world_z)
		var veg_type = BiomeRules.get_large_vegetation(biome, spawn_pos, config)
		
		if veg_type >= 0:
			# DEBUG: Count spawn types
			spawn_counts[veg_type] = spawn_counts.get(veg_type, 0) + 1
			create_vegetation_mesh(veg_type, spawn_pos)
	
	# DEBUG: Print spawn results for this chunk
	if spawn_counts.size() > 0:
		print("[VegSpawner] Chunk %s - Biomes: %s" % [chunk_pos, biome_counts])
		print("[VegSpawner] Chunk %s - Spawned: %s" % [chunk_pos, spawn_counts])
	
	# PASS 2: Ground cover
	for i in range(ground_cover_samples_per_chunk):
		var local_x = randf() * chunk_size
		var local_z = randf() * chunk_size
		var world_x = world_offset.x + local_x
		var world_z = world_offset.y + local_z
		
		var base_noise = noise.get_noise_2d(world_x, world_z)
		var biome = get_biome_at_position(world_x, world_z, base_noise)
		
		if biome == Chunk.Biome.OCEAN:
			continue
		
		var cluster_value = cluster_noise.get_noise_2d(world_x, world_z)
		var cluster_threshold = BiomeRules.get_cluster_threshold(biome)
		
		if cluster_value < cluster_threshold:
			continue
		
		var height = get_terrain_height_with_raycast(world_x, world_z, base_noise, biome)
		if height < 0.3:
			continue
		
		var spawn_pos = Vector3(world_x, height, world_z)
		var result = BiomeRules.get_ground_cover(biome, config, cluster_value)
		
		if result["type"] >= 0:
			if result["is_grass"]:
				_chunk_grass_positions.append({
					"pos": spawn_pos,
					"dense": result.get("dense", false),
					"biome": biome
				})
			else:
				create_vegetation_mesh(result["type"], spawn_pos)
	
	# PASS 3: Create grass MultiMesh
	if _chunk_grass_positions.size() > 0:
		_create_chunk_grass_multimesh(chunk_pos)


func _get_spawn_config() -> Dictionary:
	"""Build config dictionary for BiomeRules"""
	return {
		"tree_density": tree_density,
		"rock_density": rock_density,
		"mushroom_density": mushroom_density,
		"strawberry_density": strawberry_density,
		"grass_density": grass_density,
		"flower_density": flower_density,
		"forest_tree_density": forest_tree_density,
		"forest_mushroom_density": forest_mushroom_density,
		"forest_rock_density": forest_rock_density,
		"grassland_tree_density": grassland_tree_density,
		"grassland_strawberry_density": grassland_strawberry_density,
		"grassland_rock_density": grassland_rock_density,
		"mountain_pine_density": mountain_pine_density,
		"mountain_rock_density": mountain_rock_density,
		"mountain_boulder_ratio": mountain_boulder_ratio,
		"snow_pine_density": snow_pine_density,
		"snow_rock_density": snow_rock_density,
		"desert_cactus_density": desert_cactus_density,
		"desert_rock_density": desert_rock_density,
		"beach_palm_density": beach_palm_density,
		"beach_rock_density": beach_rock_density
	}


func get_terrain_height_with_raycast(world_x: float, world_z: float, base_noise: float, biome: Chunk.Biome) -> float:
	var calculated_height = get_terrain_height_at_position(world_x, world_z, base_noise, biome)
	
	var space_state = get_world_3d().direct_space_state
	var ray_start = Vector3(world_x, calculated_height + 50.0, world_z)
	var ray_end = Vector3(world_x, calculated_height - 30.0, world_z)
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position.y
	
	return calculated_height


func get_biome_at_position(world_x: float, world_z: float, base_noise: float) -> Chunk.Biome:
	"""Get biome at position - uses same thresholds as chunk.gd for consistency"""
	var temperature = chunk_manager.temperature_noise.get_noise_2d(world_x, world_z)
	var moisture = chunk_manager.moisture_noise.get_noise_2d(world_x, world_z)
	
	# SPAWN ZONE OVERRIDE: Match chunk.gd behavior
	var distance_from_origin = sqrt(world_x * world_x + world_z * world_z)
	if distance_from_origin < chunk_manager.spawn_zone_radius:
		return Chunk.Biome.GRASSLAND
	
	# Use chunk_manager thresholds for consistency with terrain visuals
	if base_noise < chunk_manager.beach_threshold:
		if base_noise < chunk_manager.ocean_threshold:
			return Chunk.Biome.OCEAN
		else:
			return Chunk.Biome.BEACH
	elif base_noise > chunk_manager.mountain_threshold:
		if temperature < chunk_manager.snow_temperature:
			return Chunk.Biome.SNOW
		else:
			return Chunk.Biome.MOUNTAIN
	else:
		if temperature > chunk_manager.desert_temperature and moisture < chunk_manager.desert_moisture:
			return Chunk.Biome.DESERT
		elif moisture > chunk_manager.forest_moisture:
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


# ============================================================================
# MESH CREATION - Routes to appropriate mesh module
# ============================================================================

func create_vegetation_mesh(veg_type: int, spawn_position: Vector3):
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	mesh_instance.global_position = spawn_position
	
	# Track for cleanup
	if populated_chunks.has(_current_chunk):
		populated_chunks[_current_chunk].append(mesh_instance)
	
	# Set visibility range
	var vis = VT.get_visibility_settings(veg_type)
	mesh_instance.visibility_range_end = vis["end"]
	mesh_instance.visibility_range_end_margin = vis["margin"]
	mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	
	# Route to correct mesh creator
	match veg_type:
		# Trees
		VT.VegType.TREE:
			TreeMeshes.create_tree(mesh_instance, self)
		VT.VegType.PINE_TREE:
			TreeMeshes.create_pine_tree(mesh_instance, self)
		VT.VegType.PALM_TREE:
			TreeMeshes.create_palm_tree(mesh_instance, self)
		VT.VegType.SNOW_PINE_TREE:
			TreeMeshes.create_snow_pine_tree(mesh_instance, self)
		
		# Rocks
		VT.VegType.ROCK:
			create_rock(mesh_instance, false)
		VT.VegType.SMALL_ROCK:
			create_small_rock(mesh_instance)
		VT.VegType.BOULDER:
			create_rock(mesh_instance, true)
		VT.VegType.SNOW_ROCK:
			create_snow_rock(mesh_instance)
		
		# Desert
		VT.VegType.CACTUS:
			DesertMeshes.create_cactus(mesh_instance)
		VT.VegType.DEAD_SHRUB:
			DesertMeshes.create_dead_shrub(mesh_instance)
		VT.VegType.DRY_GRASS_TUFT:
			DesertMeshes.create_dry_grass_tuft(mesh_instance)
		VT.VegType.DESERT_BONES:
			DesertMeshes.create_desert_bones(mesh_instance)
		
		# Forest
		VT.VegType.MUSHROOM_RED:
			create_harvestable_mushroom(mesh_instance, true, false)
		VT.VegType.MUSHROOM_BROWN:
			create_harvestable_mushroom(mesh_instance, false, false)
		VT.VegType.MUSHROOM_CLUSTER:
			create_harvestable_mushroom(mesh_instance, false, true)
		VT.VegType.FALLEN_LOG:
			ForestMeshes.create_fallen_log(mesh_instance)
		VT.VegType.TREE_STUMP:
			ForestMeshes.create_tree_stump(mesh_instance)
		
		# Snow
		VT.VegType.SNOW_MOUND:
			SnowMeshes.create_snow_mound(mesh_instance)
		VT.VegType.ICE_CRYSTAL:
			SnowMeshes.create_ice_crystal(mesh_instance)
		VT.VegType.FROZEN_SHRUB:
			SnowMeshes.create_frozen_shrub(mesh_instance)
		VT.VegType.ICICLE_CLUSTER:
			SnowMeshes.create_icicle_cluster(mesh_instance)
		VT.VegType.FROZEN_LAKE_EDGE:
			SnowMeshes.create_frozen_lake_edge(mesh_instance)
		VT.VegType.BERRY_BUSH_SNOW:
			SnowMeshes.create_berry_bush_snow(mesh_instance)
		
		# Ground Cover
		VT.VegType.WILDFLOWER_YELLOW:
			GroundCoverMeshes.create_wildflower(mesh_instance, Color(1.0, 0.9, 0.2))
		VT.VegType.WILDFLOWER_PURPLE:
			GroundCoverMeshes.create_wildflower(mesh_instance, Color(0.7, 0.3, 0.9))
		VT.VegType.WILDFLOWER_WHITE:
			GroundCoverMeshes.create_wildflower(mesh_instance, Color(1.0, 1.0, 0.95))
		VT.VegType.MOUNTAIN_LICHEN:
			GroundCoverMeshes.create_mountain_lichen(mesh_instance)
		VT.VegType.MOSS_PATCH:
			GroundCoverMeshes.create_moss_patch(mesh_instance)
		VT.VegType.ALPINE_GRASS:
			GroundCoverMeshes.create_alpine_grass(mesh_instance)
		VT.VegType.MOUNTAIN_FLOWER:
			GroundCoverMeshes.create_mountain_flower(mesh_instance)
		VT.VegType.BEACH_SHELL:
			GroundCoverMeshes.create_beach_shell(mesh_instance)
		VT.VegType.BEACH_SEAWEED:
			GroundCoverMeshes.create_beach_seaweed(mesh_instance)
		VT.VegType.BEACH_DRIFTWOOD:
			GroundCoverMeshes.create_beach_driftwood(mesh_instance)
		
		# Plants
		VT.VegType.STRAWBERRY_BUSH_SMALL:
			create_harvestable_strawberry(mesh_instance, HarvestableStrawberryClass.BushSize.SMALL)
		VT.VegType.STRAWBERRY_BUSH_MEDIUM:
			create_harvestable_strawberry(mesh_instance, HarvestableStrawberryClass.BushSize.MEDIUM)
		VT.VegType.STRAWBERRY_BUSH_LARGE:
			create_harvestable_strawberry(mesh_instance, HarvestableStrawberryClass.BushSize.LARGE)
		VT.VegType.EVERGREEN_SHRUB:
			PlantMeshes.create_evergreen_shrub(mesh_instance)


# ============================================================================
# GRASS MULTIMESH SYSTEM
# ============================================================================

func _create_chunk_grass_multimesh(chunk_pos: Vector2i):
	var grass_count = _chunk_grass_positions.size()
	if grass_count == 0:
		return
	
	var blades_per_tuft_min = 3
	var blades_per_tuft_max = 7
	var total_blades = 0
	var blade_counts = []
	
	for grass_data in _chunk_grass_positions:
		var blade_count = blades_per_tuft_min + randi() % (blades_per_tuft_max - blades_per_tuft_min + 1)
		if grass_data["dense"]:
			blade_count += 2
		blade_counts.append(blade_count)
		total_blades += blade_count
	
	var multi_mesh_instance = MultiMeshInstance3D.new()
	add_child(multi_mesh_instance)
	multi_mesh_instance.global_position = Vector3.ZERO
	
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.use_colors = true
	multi_mesh.instance_count = total_blades
	multi_mesh.mesh = _get_cached_grass_blade_mesh()
	
	var instance_idx = 0
	for i in range(grass_count):
		var grass_data = _chunk_grass_positions[i]
		var base_pos: Vector3 = grass_data["pos"]
		var blade_count = blade_counts[i]
		
		for j in range(blade_count):
			var offset_angle = randf() * TAU
			var offset_dist = randf() * 0.15
			var blade_x = base_pos.x + cos(offset_angle) * offset_dist
			var blade_z = base_pos.z + sin(offset_angle) * offset_dist
			
			var transform = Transform3D.IDENTITY
			transform = transform.rotated(Vector3.UP, randf() * TAU)
			
			var lean_angle = (randf() - 0.5) * 0.25
			var lean_dir = randf() * TAU
			transform = transform.rotated(Vector3(cos(lean_dir), 0, sin(lean_dir)), lean_angle)
			
			var scale = 0.8 + randf() * 0.5
			transform = transform.scaled(Vector3(scale, scale * (0.85 + randf() * 0.3), scale))
			transform.origin = Vector3(blade_x, base_pos.y, blade_z)
			
			multi_mesh.set_instance_transform(instance_idx, transform)
			
			var grass_biome = grass_data.get("biome", Chunk.Biome.GRASSLAND)
			var grass_tint = _get_grass_tint_for_biome(grass_biome)
			multi_mesh.set_instance_color(instance_idx, grass_tint)
			instance_idx += 1
	
	multi_mesh_instance.multimesh = multi_mesh
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.8
	multi_mesh_instance.material_override = material
	
	if populated_chunks.has(chunk_pos):
		populated_chunks[chunk_pos].append(multi_mesh_instance)


func _get_grass_tint_for_biome(biome: Chunk.Biome) -> Color:
	var color_rand = randf()
	
	match biome:
		Chunk.Biome.GRASSLAND:
			if color_rand > 0.7:
				return Color(0.95, 1.10, 0.85)
			elif color_rand > 0.4:
				return Color(1.0, 1.0, 1.0)
			else:
				return Color(0.90, 1.05, 0.85)
		
		Chunk.Biome.FOREST:
			if color_rand > 0.7:
				return Color(0.80, 0.95, 0.75)
			elif color_rand > 0.4:
				return Color(0.75, 0.90, 0.70)
			else:
				return Color(0.70, 0.85, 0.65)
		
		Chunk.Biome.MOUNTAIN:
			if color_rand > 0.5:
				return Color(0.85, 0.90, 0.80)
			else:
				return Color(0.80, 0.85, 0.75)
		
		_:
			return Color(1.0, 1.0, 1.0)


func _get_cached_grass_blade_mesh() -> ArrayMesh:
	if _cached_grass_blade_mesh == null:
		_cached_grass_blade_mesh = _create_grass_blade_mesh()
	return _cached_grass_blade_mesh


func _create_grass_blade_mesh() -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var height = 0.5
	var width_base = 0.08
	var width_tip = 0.02
	var segments = 3
	
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


# ============================================================================
# HARVESTABLE RESOURCE CREATION
# ============================================================================

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
	var mushroom_mesh = MeshInstance3D.new()
	mushroom.add_child(mushroom_mesh)
	ForestMeshes.create_mushroom_visual(mushroom_mesh, is_red, is_cluster)
	
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
	
	# Register replacement node for chunk cleanup
	if populated_chunks.has(_current_chunk):
		populated_chunks[_current_chunk].append(mushroom)
	
	mesh_instance.queue_free()


func create_harvestable_strawberry(mesh_instance: MeshInstance3D, bush_size: HarvestableStrawberryClass.BushSize = HarvestableStrawberryClass.BushSize.MEDIUM):
	"""Create a harvestable strawberry bush with specified size"""
	var parent = mesh_instance.get_parent()
	var strawberry_position = mesh_instance.global_position
	
	# Create the harvestable strawberry node with size
	var strawberry = HarvestableStrawberryClass.new()
	strawberry.bush_size = bush_size
	
	# Set collision for harvesting
	strawberry.collision_layer = 2
	strawberry.collision_mask = 0
	
	# Create the visual mesh
	var bush_mesh = MeshInstance3D.new()
	strawberry.add_child(bush_mesh)
	
	# Convert enum to string for PlantMeshes
	var size_string = "medium"
	match bush_size:
		HarvestableStrawberryClass.BushSize.SMALL:
			size_string = "small"
		HarvestableStrawberryClass.BushSize.MEDIUM:
			size_string = "medium"
		HarvestableStrawberryClass.BushSize.LARGE:
			size_string = "large"
	
	PlantMeshes.create_strawberry_visual(bush_mesh, size_string)
	
	# Add collision shape for the strawberry bush (size-dependent)
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	
	# Scale collision based on bush size
	match bush_size:
		HarvestableStrawberryClass.BushSize.SMALL:
			shape.radius = 0.35
			collision.position.y = 0.25
		HarvestableStrawberryClass.BushSize.MEDIUM:
			shape.radius = 0.5
			collision.position.y = 0.4
		HarvestableStrawberryClass.BushSize.LARGE:
			shape.radius = 0.65
			collision.position.y = 0.5
	
	collision.shape = shape
	strawberry.add_child(collision)
	
	# Replace mesh_instance with strawberry in scene
	parent.remove_child(mesh_instance)
	parent.add_child(strawberry)
	strawberry.global_position = strawberry_position
	
	# Register replacement node for chunk cleanup
	if populated_chunks.has(_current_chunk):
		populated_chunks[_current_chunk].append(strawberry)
	
	mesh_instance.queue_free()


func create_rock(mesh_instance: MeshInstance3D, is_boulder: bool):
	"""Create a harvestable rock resource"""
	var size = 0.7 + randf() * 0.5 if not is_boulder else 1.4 + randf() * 1.0
	
	var parent = mesh_instance.get_parent()
	var rock_position = mesh_instance.global_position
	
	var resource_node = ResourceNodeClass.new()
	resource_node.node_type = ResourceNodeClass.NodeType.ROCK
	
	# Override properties for boulders vs regular rocks
	if is_boulder:
		resource_node.resource_name = "Boulder"
		resource_node.harvest_time = 3.0
		resource_node.drop_amount_min = 6
		resource_node.drop_amount_max = 10
		resource_node.max_health = 100.0
		resource_node.current_health = 100.0
	
	resource_node.collision_layer = 2
	resource_node.collision_mask = 0
	
	# Create rock mesh
	var rock_mesh = MeshInstance3D.new()
	resource_node.add_child(rock_mesh)
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = size / 2
	sphere_mesh.height = size
	sphere_mesh.radial_segments = 8
	sphere_mesh.rings = 6
	
	# Pixelated stone texture
	var stone_texture = PixelTextureGenerator.create_stone_texture()
	var stone_tint = Color(0.9 + randf() * 0.2, 0.9 + randf() * 0.2, 0.9 + randf() * 0.2)
	var material = PixelTextureGenerator.create_pixel_material(stone_texture, stone_tint)
	material = material.duplicate()
	
	rock_mesh.mesh = sphere_mesh
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
	
	# Replace mesh_instance with resource_node in scene
	parent.remove_child(mesh_instance)
	parent.add_child(resource_node)
	resource_node.global_position = rock_position
	
	if populated_chunks.has(_current_chunk):
		populated_chunks[_current_chunk].append(resource_node)
	
	mesh_instance.queue_free()


func create_small_rock(mesh_instance: MeshInstance3D):
	"""Create a small harvestable rock"""
	var size = 0.4 + randf() * 0.2
	
	var parent = mesh_instance.get_parent()
	var rock_position = mesh_instance.global_position
	
	var resource_node = ResourceNodeClass.new()
	resource_node.node_type = ResourceNodeClass.NodeType.ROCK
	
	# Small rock properties
	resource_node.resource_name = "Small Rock"
	resource_node.harvest_time = 1.0
	resource_node.drop_amount_min = 1
	resource_node.drop_amount_max = 1
	resource_node.max_health = 30.0
	resource_node.current_health = 30.0
	
	resource_node.collision_layer = 2
	resource_node.collision_mask = 0
	
	# Create rock mesh
	var rock_mesh = MeshInstance3D.new()
	resource_node.add_child(rock_mesh)
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = size / 2
	sphere_mesh.height = size
	sphere_mesh.radial_segments = 8
	sphere_mesh.rings = 6
	
	# Pixelated stone texture
	var stone_texture = PixelTextureGenerator.create_stone_texture()
	var stone_tint = Color(0.9 + randf() * 0.2, 0.9 + randf() * 0.2, 0.9 + randf() * 0.2)
	var material = PixelTextureGenerator.create_pixel_material(stone_texture, stone_tint)
	material = material.duplicate()
	
	rock_mesh.mesh = sphere_mesh
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
	
	# Replace mesh_instance with resource_node in scene
	parent.remove_child(mesh_instance)
	parent.add_child(resource_node)
	resource_node.global_position = rock_position
	
	if populated_chunks.has(_current_chunk):
		populated_chunks[_current_chunk].append(resource_node)
	
	mesh_instance.queue_free()


func create_snow_rock(mesh_instance: MeshInstance3D):
	"""Create a snow-covered rock"""
	var size = 0.6 + randf() * 0.4
	
	var parent = mesh_instance.get_parent()
	var rock_position = mesh_instance.global_position
	
	var resource_node = ResourceNodeClass.new()
	resource_node.node_type = ResourceNodeClass.NodeType.ROCK
	
	resource_node.resource_name = "Snow Rock"
	resource_node.collision_layer = 2
	resource_node.collision_mask = 0
	
	# Create rock mesh
	var rock_mesh = MeshInstance3D.new()
	resource_node.add_child(rock_mesh)
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = size / 2
	sphere_mesh.height = size
	sphere_mesh.radial_segments = 8
	sphere_mesh.rings = 6
	
	# Snow-covered stone texture (lighter/whiter)
	var stone_texture = PixelTextureGenerator.create_stone_texture()
	var snow_tint = Color(0.85 + randf() * 0.15, 0.88 + randf() * 0.12, 0.95 + randf() * 0.05)
	var material = PixelTextureGenerator.create_pixel_material(stone_texture, snow_tint)
	material = material.duplicate()
	
	rock_mesh.mesh = sphere_mesh
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
	
	# Replace mesh_instance with resource_node in scene
	parent.remove_child(mesh_instance)
	parent.add_child(resource_node)
	resource_node.global_position = rock_position
	
	if populated_chunks.has(_current_chunk):
		populated_chunks[_current_chunk].append(resource_node)
	
	mesh_instance.queue_free()
