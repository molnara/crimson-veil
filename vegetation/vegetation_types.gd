class_name VegetationTypes
extends RefCounted

"""
VegetationTypes - Enum definitions and visibility settings for all vegetation

v0.8.0: Extracted from vegetation_spawner.gd for better organization
"""

enum VegType {
	# Trees
	TREE,
	PINE_TREE,
	PALM_TREE,
	SNOW_PINE_TREE,
	
	# Rocks
	ROCK,
	SMALL_ROCK,
	BOULDER,
	SNOW_ROCK,
	
	# Desert
	CACTUS,
	DEAD_SHRUB,
	DRY_GRASS_TUFT,
	DESERT_BONES,
	
	# Forest
	MUSHROOM_RED,
	MUSHROOM_BROWN,
	MUSHROOM_CLUSTER,
	FALLEN_LOG,
	TREE_STUMP,
	
	# Grassland
	GRASS_TUFT,
	GRASS_PATCH,
	WILDFLOWER_YELLOW,
	WILDFLOWER_PURPLE,
	WILDFLOWER_WHITE,
	STRAWBERRY_BUSH_SMALL,
	STRAWBERRY_BUSH_MEDIUM,
	STRAWBERRY_BUSH_LARGE,
	
	# Snow
	SNOW_MOUND,
	ICE_CRYSTAL,
	FROZEN_SHRUB,
	ICICLE_CLUSTER,
	FROZEN_LAKE_EDGE,
	BERRY_BUSH_SNOW,
	
	# Beach
	BEACH_SHELL,
	BEACH_SEAWEED,
	BEACH_DRIFTWOOD,
	
	# Mountain
	ALPINE_GRASS,
	MOUNTAIN_LICHEN,
	EVERGREEN_SHRUB,
	MOUNTAIN_FLOWER,
	MOSS_PATCH
}

# Visibility range settings for LOD culling
static func get_visibility_settings(veg_type: VegType) -> Dictionary:
	"""Returns {end: float, margin: float} for visibility range"""
	match veg_type:
		# Trees - visible from far
		VegType.TREE, VegType.PINE_TREE, VegType.PALM_TREE:
			return {"end": 80.0, "margin": 15.0}
		VegType.SNOW_PINE_TREE:
			return {"end": 80.0, "margin": 15.0}
		
		# Large rocks
		VegType.BOULDER:
			return {"end": 70.0, "margin": 12.0}
		VegType.ROCK, VegType.SNOW_ROCK:
			return {"end": 55.0, "margin": 10.0}
		VegType.SMALL_ROCK:
			return {"end": 35.0, "margin": 6.0}
		
		# Medium vegetation
		VegType.CACTUS:
			return {"end": 60.0, "margin": 10.0}
		VegType.FALLEN_LOG, VegType.TREE_STUMP:
			return {"end": 55.0, "margin": 10.0}
		
		# Harvestables
		VegType.MUSHROOM_RED, VegType.MUSHROOM_BROWN, VegType.MUSHROOM_CLUSTER:
			return {"end": 40.0, "margin": 8.0}
		VegType.STRAWBERRY_BUSH_SMALL, VegType.STRAWBERRY_BUSH_MEDIUM, VegType.STRAWBERRY_BUSH_LARGE:
			return {"end": 45.0, "margin": 8.0}
		
		# Ground cover - shorter range
		VegType.GRASS_TUFT, VegType.GRASS_PATCH, VegType.ALPINE_GRASS:
			return {"end": 30.0, "margin": 5.0}
		VegType.WILDFLOWER_YELLOW, VegType.WILDFLOWER_PURPLE, VegType.WILDFLOWER_WHITE:
			return {"end": 35.0, "margin": 6.0}
		VegType.MOUNTAIN_FLOWER:
			return {"end": 30.0, "margin": 5.0}
		
		# Snow/Ice
		VegType.SNOW_MOUND:
			return {"end": 50.0, "margin": 8.0}
		VegType.ICE_CRYSTAL, VegType.ICICLE_CLUSTER:
			return {"end": 45.0, "margin": 8.0}
		VegType.FROZEN_LAKE_EDGE:
			return {"end": 50.0, "margin": 8.0}
		VegType.FROZEN_SHRUB, VegType.BERRY_BUSH_SNOW:
			return {"end": 40.0, "margin": 6.0}
		
		# Desert ground cover
		VegType.DEAD_SHRUB, VegType.DRY_GRASS_TUFT:
			return {"end": 40.0, "margin": 8.0}
		VegType.DESERT_BONES:
			return {"end": 30.0, "margin": 5.0}
		
		# Beach
		VegType.BEACH_SHELL, VegType.BEACH_SEAWEED, VegType.BEACH_DRIFTWOOD:
			return {"end": 30.0, "margin": 5.0}
		
		# Mountain ground cover
		VegType.MOUNTAIN_LICHEN, VegType.MOSS_PATCH:
			return {"end": 35.0, "margin": 5.0}
		VegType.EVERGREEN_SHRUB:
			return {"end": 40.0, "margin": 6.0}
		
		_:
			return {"end": 60.0, "margin": 10.0}
