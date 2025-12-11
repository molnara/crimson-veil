class_name PineTreeVisual
extends Node

"""
PineTreeVisual - Procedural pine tree mesh generator

Creates harvestable pine/conifer trees with:
- Conical shape with multiple cone levels
- Trunk tilt and asymmetry for wind-stressed look
- Rare "character" trees (windswept, dead/sparse, ancient)
- Natural color variation in bark and needles

Called by VegetationSpawner during chunk population in mountain/snow biomes.
"""

const HarvestableTreeClass = preload("res://harvestable_tree.gd")

## Create a harvestable pine tree with variety in shape, trunk tilt, and character trees
static func create(
	mesh_instance: MeshInstance3D,
	spawner: VegetationSpawner
) -> void:
	var parent = mesh_instance.get_parent()
	var tree_position = mesh_instance.global_position
	
	# Create the harvestable tree node
	var tree = HarvestableTreeClass.new()
	tree.tree_type = HarvestableTreeClass.TreeType.PINE
	
	# Set collision for harvesting
	tree.collision_layer = 2
	tree.collision_mask = 0
	
	# Size variation for pines
	var trunk_height = spawner.tree_height_min * 0.8 + randf() * (spawner.tree_height_max * 0.9 - spawner.tree_height_min * 0.8)  # Slightly shorter than oaks
	var height_ratio = (trunk_height - spawner.tree_height_min * 0.8) / (spawner.tree_height_max * 0.9 - spawner.tree_height_min * 0.8)
	var trunk_radius = spawner.trunk_radius_base * 0.8 * (0.85 + height_ratio * 0.5)  # Thinner than oaks
	
	# Character tree check (rare special pines)
	var is_character_tree = randf() < spawner.character_tree_chance
	var character_type = 0  # 0=windswept, 1=dead/sparse, 2=ancient
	if is_character_tree:
		character_type = randi() % 3
	
	# Calculate trunk tilt
	var tilt_noise = spawner.vegetation_noise.get_noise_2d(tree_position.x * 0.1, tree_position.z * 0.1)
	var tilt_amount = abs(tilt_noise) * spawner.trunk_tilt_max * (0.5 + height_ratio * spawner.trunk_tilt_influence)
	if is_character_tree and character_type == 0:  # Windswept pines lean more
		tilt_amount *= 2.2
	var tilt_direction = randf() * TAU
	var trunk_tilt_x = cos(tilt_direction) * tilt_amount
	var trunk_tilt_z = sin(tilt_direction) * tilt_amount
	
	var trunk_mesh = MeshInstance3D.new()
	tree.add_child(trunk_mesh)
	
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = trunk_height
	
	# Character tree trunk modifications
	if is_character_tree:
		match character_type:
			0:  # Windswept - more taper
				cylinder_mesh.top_radius = trunk_radius * 0.4
				cylinder_mesh.bottom_radius = trunk_radius * 1.2
			1:  # Dead/sparse - thinner
				cylinder_mesh.top_radius = trunk_radius * 0.5
				cylinder_mesh.bottom_radius = trunk_radius * 0.9
			2:  # Ancient - thicker
				cylinder_mesh.top_radius = trunk_radius * 0.7
				cylinder_mesh.bottom_radius = trunk_radius * 1.4
				trunk_height *= 1.3
				cylinder_mesh.height = trunk_height
	else:
		cylinder_mesh.top_radius = trunk_radius * 0.6
		cylinder_mesh.bottom_radius = trunk_radius
	
	trunk_mesh.mesh = cylinder_mesh
	trunk_mesh.position.y = trunk_height / 2
	
	# Apply trunk tilt
	trunk_mesh.rotation.x = trunk_tilt_x
	trunk_mesh.rotation.z = trunk_tilt_z
	
	# Bark texture with variation
	var bark_texture = PixelTextureGenerator.create_pine_bark_texture()
	var bark_hue_shift = randf() * 0.2
	var bark_tint: Color
	
	if is_character_tree and character_type == 2:  # Ancient - darker bark
		bark_tint = Color(0.85 + bark_hue_shift * 0.3, 0.70 + bark_hue_shift * 0.25, 0.60 + bark_hue_shift * 0.2)
	else:
		# Normal pine bark variation (reddish-brown tones)
		bark_tint = Color(1.0 + bark_hue_shift * 0.4, 0.85 + bark_hue_shift * 0.3, 0.75 + bark_hue_shift * 0.25)
	
	var trunk_material = PixelTextureGenerator.create_pixel_material(bark_texture, bark_tint)
	trunk_mesh.set_surface_override_material(0, trunk_material)
	
	# Pine foliage (cone levels) with pixelated texture
	var leaves_texture = PixelTextureGenerator.create_leaves_texture()
	
	# Foliage color variation
	var green_variation = randf()
	var foliage_tint: Color
	if green_variation > 0.7:
		foliage_tint = Color(0.6, 0.9, 0.6)  # Lighter pine green
	elif green_variation > 0.3:
		foliage_tint = Color(0.5, 0.8, 0.5)  # Standard pine green
	else:
		foliage_tint = Color(0.4, 0.7, 0.45)  # Darker pine green
	
	# Character tree cone modifications
	var cone_levels = 3
	if is_character_tree:
		match character_type:
			0:  # Windswept - asymmetric cones
				cone_levels = 3
			1:  # Dead/sparse - fewer, smaller cones
				cone_levels = 2
				foliage_tint = foliage_tint * 0.7  # Browner/dead look
			2:  # Ancient - more cone levels
				cone_levels = 4
	
	# Asymmetry for windswept look
	var asymmetry_angle = randf() * TAU
	var asymmetry_strength = spawner.branch_asymmetry_amount * randf()
	if is_character_tree and character_type == 0:
		asymmetry_strength *= 1.4  # Windswept but not extreme (reduced from 2.0)
	
	for i in range(cone_levels):
		var cone = MeshInstance3D.new()
		trunk_mesh.add_child(cone)
		
		var cone_mesh = CylinderMesh.new()
		# i=0 should be BOTTOM (large), higher i = TOP (small)
		var level_ratio = i / float(cone_levels - 1) if cone_levels > 1 else 0.5
		var level_height = trunk_height * (0.35 + level_ratio * 0.5)  # Distribute along trunk
		var cone_size = (1.8 - level_ratio * 0.9) * (0.9 + height_ratio * 0.4)  # Scale with tree size
		
		cone_mesh.height = cone_size
		cone_mesh.top_radius = 0.0  # Point at top
		cone_mesh.bottom_radius = cone_size * 0.7  # Wide at bottom
		cone.mesh = cone_mesh
		
		# Apply asymmetry to cone position (windswept effect)
		var cone_offset = Vector3.ZERO
		if asymmetry_strength > 0.1:
			var offset_dist = asymmetry_strength * cone_size * 0.08  # Reduced from 0.15 - minimal offset
			cone_offset = Vector3(
				cos(asymmetry_angle) * offset_dist,
				0,
				sin(asymmetry_angle) * offset_dist
			)
		
		cone.position = Vector3(0, level_height, 0) + cone_offset
		cone.rotation.y = randf() * TAU  # Random rotation for variety
		
		var cone_material = PixelTextureGenerator.create_pixel_material(leaves_texture, foliage_tint)
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
