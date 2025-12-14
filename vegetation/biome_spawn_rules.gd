class_name BiomeSpawnRules
extends RefCounted

"""
BiomeSpawnRules - Defines what vegetation spawns in each biome

v0.8.0: Extracted from vegetation_spawner.gd for better organization

Usage:
	var veg_type = BiomeSpawnRules.get_large_vegetation(biome, spawn_pos, config)
	var ground_type = BiomeSpawnRules.get_ground_cover(biome, config, cluster_value)
"""

const VT = preload("res://vegetation/vegetation_types.gd")

# ============================================================================
# LARGE VEGETATION (Trees, Rocks, Cacti, etc.)
# ============================================================================

static func get_large_vegetation(biome: Chunk.Biome, spawn_pos: Vector3, config: Dictionary) -> int:
	"""Returns VegType for large vegetation, or -1 if nothing should spawn"""
	var rand = randf()
	
	match biome:
		Chunk.Biome.FOREST:
			return _get_forest_large(rand, config)
		Chunk.Biome.GRASSLAND:
			return _get_grassland_large(rand, config)
		Chunk.Biome.DESERT:
			return _get_desert_large(rand, config)
		Chunk.Biome.MOUNTAIN:
			return _get_mountain_large(rand, config)
		Chunk.Biome.SNOW:
			return _get_snow_large(rand, config)
		Chunk.Biome.BEACH:
			return _get_beach_large(rand, spawn_pos, config)
		_:
			return -1


static func _get_forest_large(rand: float, config: Dictionary) -> int:
	var tree_chance = config.tree_density * config.forest_tree_density
	var mushroom_chance = config.mushroom_density * config.forest_mushroom_density
	var rock_chance = config.rock_density * config.forest_rock_density
	
	if rand > (1.0 - tree_chance):
		return VT.VegType.TREE
	elif rand > (1.0 - tree_chance - mushroom_chance):
		var mushroom_rand = randf()
		if mushroom_rand > 0.6:
			return VT.VegType.MUSHROOM_RED
		elif mushroom_rand > 0.3:
			return VT.VegType.MUSHROOM_BROWN
		else:
			return VT.VegType.MUSHROOM_CLUSTER
	elif rand > (1.0 - tree_chance - mushroom_chance - rock_chance):
		return _get_rock_type(0.05, 0.15)  # 5% boulder, 10% rock, 85% small
	# Forest extras
	elif rand > 0.75:
		var extra = randf()
		if extra > 0.6:
			return VT.VegType.FALLEN_LOG
		else:
			return VT.VegType.TREE_STUMP
	return -1


static func _get_grassland_large(rand: float, config: Dictionary) -> int:
	var tree_chance = config.tree_density * config.grassland_tree_density
	var strawberry_chance = config.strawberry_density * config.grassland_strawberry_density
	var rock_chance = config.rock_density * config.grassland_rock_density
	
	if rand > (1.0 - tree_chance):
		return VT.VegType.TREE
	elif rand > (1.0 - tree_chance - strawberry_chance):
		var size_rand = randf()
		if size_rand > 0.85:
			return VT.VegType.STRAWBERRY_BUSH_LARGE
		elif size_rand > 0.30:
			return VT.VegType.STRAWBERRY_BUSH_MEDIUM
		else:
			return VT.VegType.STRAWBERRY_BUSH_SMALL
	elif rand > (1.0 - tree_chance - strawberry_chance - rock_chance):
		return _get_rock_type(0.08, 0.20)  # 8% boulder, 12% rock, 80% small
	return -1


static func _get_desert_large(rand: float, config: Dictionary) -> int:
	var cactus_chance = config.tree_density * config.desert_cactus_density
	var rock_chance = config.rock_density * config.desert_rock_density
	
	if rand > (1.0 - cactus_chance):
		return VT.VegType.CACTUS
	elif rand > (1.0 - cactus_chance - rock_chance):
		return _get_rock_type(0.10, 0.20)
	# Desert extras - dead vegetation (sparse)
	elif rand > 0.75:
		var extra = randf()
		if extra > 0.6:
			return VT.VegType.DEAD_SHRUB
		elif extra > 0.3:
			return VT.VegType.DESERT_BONES
		else:
			return VT.VegType.DRY_GRASS_TUFT
	return -1


static func _get_mountain_large(rand: float, config: Dictionary) -> int:
	var pine_chance = config.tree_density * config.mountain_pine_density
	var rock_chance = config.rock_density * config.mountain_rock_density * 0.6
	
	if rand > (1.0 - pine_chance):
		return VT.VegType.PINE_TREE
	elif rand > (1.0 - pine_chance - rock_chance):
		var rock_rand = randf()
		if rock_rand > (1.0 - config.mountain_boulder_ratio):
			return VT.VegType.BOULDER
		elif rock_rand > 0.35:
			return VT.VegType.ROCK
		else:
			return VT.VegType.SMALL_ROCK
	# Mountain extras - rare
	elif rand > 0.85:
		var extra = randf()
		if extra > 0.7:
			return VT.VegType.FALLEN_LOG
		elif extra > 0.4:
			return VT.VegType.TREE_STUMP
		else:
			return VT.VegType.EVERGREEN_SHRUB
	return -1


static func _get_snow_large(rand: float, config: Dictionary) -> int:
	var pine_chance = config.tree_density * config.snow_pine_density
	var rock_chance = config.rock_density * config.snow_rock_density * 0.6
	
	if rand > (1.0 - pine_chance):
		# 50% chance of snow-covered variant
		if randf() > 0.5:
			return VT.VegType.SNOW_PINE_TREE
		else:
			return VT.VegType.PINE_TREE
	elif rand > (1.0 - pine_chance - rock_chance):
		var rock_rand = randf()
		if rock_rand > 0.90:
			return VT.VegType.BOULDER
		elif rock_rand > 0.60:
			return VT.VegType.SNOW_ROCK
		elif rock_rand > 0.40:
			return VT.VegType.ROCK
		else:
			return VT.VegType.SMALL_ROCK
	# Snow extras - rare
	elif rand > 0.85:
		var extra = randf()
		if extra > 0.6:
			return VT.VegType.FROZEN_SHRUB
		elif extra > 0.3:
			return VT.VegType.BERRY_BUSH_SNOW
		else:
			return VT.VegType.FALLEN_LOG
	return -1


static func _get_beach_large(rand: float, spawn_pos: Vector3, config: Dictionary) -> int:
	var palm_chance = config.tree_density * config.beach_palm_density
	var rock_chance = config.rock_density * config.beach_rock_density
	
	# Palm trees only spawn at low elevations
	if spawn_pos.y < 5.0 and rand > (1.0 - palm_chance):
		return VT.VegType.PALM_TREE
	elif rand > (1.0 - rock_chance):
		if randf() > 0.75:
			return VT.VegType.ROCK
		else:
			return VT.VegType.SMALL_ROCK
	return -1


static func _get_rock_type(boulder_threshold: float, rock_threshold: float) -> int:
	var rock_rand = randf()
	if rock_rand > (1.0 - boulder_threshold):
		return VT.VegType.BOULDER
	elif rock_rand > (1.0 - boulder_threshold - rock_threshold):
		return VT.VegType.ROCK
	else:
		return VT.VegType.SMALL_ROCK


# ============================================================================
# GROUND COVER (Grass, Flowers, Debris, etc.)
# ============================================================================

static func get_ground_cover(biome: Chunk.Biome, config: Dictionary, cluster_value: float) -> Dictionary:
	"""Returns {type: VegType, is_grass: bool} or {type: -1} if nothing spawns
	
	is_grass = true means it should be added to MultiMesh instead of individual spawn
	"""
	var rand = randf()
	
	match biome:
		Chunk.Biome.GRASSLAND:
			return _get_grassland_ground(rand, config, cluster_value)
		Chunk.Biome.FOREST:
			return _get_forest_ground(rand, config, cluster_value)
		Chunk.Biome.DESERT:
			return _get_desert_ground(rand)
		Chunk.Biome.SNOW:
			return _get_snow_ground(rand)
		Chunk.Biome.BEACH:
			return _get_beach_ground(rand)
		Chunk.Biome.MOUNTAIN:
			return _get_mountain_ground(rand, config, cluster_value)
		_:
			return {"type": -1, "is_grass": false}


static func _get_grassland_ground(rand: float, config: Dictionary, cluster_value: float) -> Dictionary:
	# Flowers in patches - sparse
	if rand < config.flower_density * 0.3:
		var flower_rand = randf()
		if flower_rand > 0.65:
			return {"type": VT.VegType.WILDFLOWER_YELLOW, "is_grass": false}
		elif flower_rand > 0.35:
			return {"type": VT.VegType.WILDFLOWER_PURPLE, "is_grass": false}
		else:
			return {"type": VT.VegType.WILDFLOWER_WHITE, "is_grass": false}
	# Grass - collect for MultiMesh
	elif rand < config.grass_density * 0.5:
		var is_dense = cluster_value > 0.3
		return {"type": VT.VegType.GRASS_TUFT, "is_grass": true, "dense": is_dense}
	return {"type": -1, "is_grass": false}


static func _get_forest_ground(rand: float, config: Dictionary, cluster_value: float) -> Dictionary:
	# Small mushrooms
	if rand < config.mushroom_density * 0.15:
		if randf() > 0.5:
			return {"type": VT.VegType.MUSHROOM_BROWN, "is_grass": false}
		else:
			return {"type": VT.VegType.MUSHROOM_CLUSTER, "is_grass": false}
	# Grass (less dense in forest)
	elif rand < config.grass_density * 0.3:
		var is_dense = cluster_value > 0.2
		return {"type": VT.VegType.GRASS_TUFT, "is_grass": true, "dense": is_dense}
	# Moss patches - sparse
	elif rand < 0.15:
		return {"type": VT.VegType.MOSS_PATCH, "is_grass": false}
	return {"type": -1, "is_grass": false}


static func _get_desert_ground(rand: float) -> Dictionary:
	# NO GRASS - only dead vegetation (sparse)
	if rand < 0.15:
		return {"type": VT.VegType.DEAD_SHRUB, "is_grass": false}
	elif rand < 0.25:
		return {"type": VT.VegType.DRY_GRASS_TUFT, "is_grass": false}
	elif rand < 0.30:
		return {"type": VT.VegType.DESERT_BONES, "is_grass": false}
	return {"type": -1, "is_grass": false}


static func _get_snow_ground(rand: float) -> Dictionary:
	# NO GRASS - sparse snow/ice features
	if rand < 0.06:
		return {"type": VT.VegType.SNOW_MOUND, "is_grass": false}
	elif rand < 0.10:
		return {"type": VT.VegType.ICE_CRYSTAL, "is_grass": false}
	elif rand < 0.13:
		return {"type": VT.VegType.FROZEN_SHRUB, "is_grass": false}
	elif rand < 0.15:
		return {"type": VT.VegType.ICICLE_CLUSTER, "is_grass": false}
	elif rand < 0.17:
		return {"type": VT.VegType.FROZEN_LAKE_EDGE, "is_grass": false}
	return {"type": -1, "is_grass": false}


static func _get_beach_ground(rand: float) -> Dictionary:
	# NO GRASS - only beach debris (sparse)
	if rand < 0.12:
		return {"type": VT.VegType.BEACH_SHELL, "is_grass": false}
	elif rand < 0.20:
		return {"type": VT.VegType.BEACH_SEAWEED, "is_grass": false}
	elif rand < 0.25:
		return {"type": VT.VegType.BEACH_DRIFTWOOD, "is_grass": false}
	return {"type": -1, "is_grass": false}


static func _get_mountain_ground(rand: float, config: Dictionary, cluster_value: float) -> Dictionary:
	# Sparse alpine vegetation
	if rand < config.grass_density * 0.15:
		return {"type": VT.VegType.ALPINE_GRASS, "is_grass": true, "dense": false}
	elif rand < 0.08:
		return {"type": VT.VegType.MOUNTAIN_LICHEN, "is_grass": false}
	elif rand < 0.12:
		return {"type": VT.VegType.MOSS_PATCH, "is_grass": false}
	elif rand < 0.16:
		return {"type": VT.VegType.MOUNTAIN_FLOWER, "is_grass": false}
	elif rand < 0.18:
		return {"type": VT.VegType.EVERGREEN_SHRUB, "is_grass": false}
	elif rand < 0.20:
		return {"type": VT.VegType.SMALL_ROCK, "is_grass": false}
	return {"type": -1, "is_grass": false}


# ============================================================================
# CLUSTER THRESHOLDS
# ============================================================================

static func get_cluster_threshold(biome: Chunk.Biome) -> float:
	"""Returns minimum cluster noise value for spawning ground cover"""
	match biome:
		Chunk.Biome.DESERT, Chunk.Biome.SNOW, Chunk.Biome.BEACH, Chunk.Biome.MOUNTAIN:
			return -0.5  # 75% of area for sparse biomes
		Chunk.Biome.GRASSLAND, Chunk.Biome.FOREST:
			return 0.0   # 50% of area for grass patches
		_:
			return 0.0
