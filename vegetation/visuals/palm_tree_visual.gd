class_name PalmTreeVisual
extends Node

"""
PalmTreeVisual - Procedural palm tree mesh generator

Creates harvestable palm trees with:
- Characteristic fronds radiating from top
- Natural lean and curve (palms tilt more than other trees)
- Rare "character" trees (bent, hurricane-damaged, ancient)
- Tropical color variation

Called by VegetationSpawner during chunk population in beach biomes.
"""

const HarvestableTreeClass = preload("res://harvestable_tree.gd")

## Create a harvestable palm tree with variety in shape, trunk tilt, and character trees
static func create(
	mesh_instance: MeshInstance3D,
	spawner: VegetationSpawner
) -> void:
	var parent = mesh_instance.get_parent()
	var tree_position = mesh_instance.global_position
	
	# Create the harvestable tree node
	var tree = HarvestableTreeClass.new()
	tree.tree_type = HarvestableTreeClass.TreeType.PALM
	
	# Set collision for harvesting
	tree.collision_layer = 2
	tree.collision_mask = 0
	
	# Size variation for palms
	var trunk_height = spawner.tree_height_min * 0.7 + randf() * (spawner.tree_height_max * 0.6 - spawner.tree_height_min * 0.7)  # Palms are shorter
	var height_ratio = (trunk_height - spawner.tree_height_min * 0.7) / (spawner.tree_height_max * 0.6 - spawner.tree_height_min * 0.7)
	var trunk_radius = spawner.trunk_radius_base * 0.75 * (0.9 + height_ratio * 0.4)  # Slightly thinner than oaks
	
	# Character tree check (rare special palms)
	var is_character_tree = randf() < spawner.character_tree_chance
	var character_type = 0  # 0=bent, 1=hurricane-damaged, 2=ancient
	if is_character_tree:
		character_type = randi() % 3
	
	# Calculate trunk tilt (palms naturally lean more)
	var tilt_noise = spawner.vegetation_noise.get_noise_2d(tree_position.x * 0.1, tree_position.z * 0.1)
	var tilt_amount = abs(tilt_noise) * spawner.trunk_tilt_max * 1.5 * (0.6 + height_ratio * spawner.trunk_tilt_influence)  # Palms lean more
	if is_character_tree and character_type == 0:  # Bent palms lean dramatically
		tilt_amount *= 2.5
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
			0:  # Bent - more curved/tapered
				cylinder_mesh.top_radius = trunk_radius * 0.5
				cylinder_mesh.bottom_radius = trunk_radius * 1.1
			1:  # Hurricane-damaged - broken/thin top
				cylinder_mesh.top_radius = trunk_radius * 0.4
				cylinder_mesh.bottom_radius = trunk_radius
				trunk_height *= 0.7  # Shorter from damage
				cylinder_mesh.height = trunk_height
			2:  # Ancient - thicker, taller
				cylinder_mesh.top_radius = trunk_radius * 0.8
				cylinder_mesh.bottom_radius = trunk_radius * 1.3
				trunk_height *= 1.25
				cylinder_mesh.height = trunk_height
	else:
		cylinder_mesh.top_radius = trunk_radius * 0.7
		cylinder_mesh.bottom_radius = trunk_radius
	
	trunk_mesh.mesh = cylinder_mesh
	trunk_mesh.position.y = trunk_height / 2
	
	# Apply trunk tilt
	trunk_mesh.rotation.x = trunk_tilt_x
	trunk_mesh.rotation.z = trunk_tilt_z
	
	# Bark texture with variation
	var bark_texture = PixelTextureGenerator.create_palm_bark_texture()
	var bark_hue_shift = randf() * 0.15
	var bark_tint: Color
	
	if is_character_tree and character_type == 2:  # Ancient - darker bark
		bark_tint = Color(1.05 + bark_hue_shift * 0.3, 0.95 + bark_hue_shift * 0.25, 0.75 + bark_hue_shift * 0.2)
	else:
		# Normal palm bark variation (tan/beige tones)
		var tone = randf()
		if tone > 0.6:
			bark_tint = Color(1.20 + bark_hue_shift * 0.4, 1.10 + bark_hue_shift * 0.3, 0.90 + bark_hue_shift * 0.25)  # Light tan
		else:
			bark_tint = Color(1.15 + bark_hue_shift * 0.4, 1.05 + bark_hue_shift * 0.3, 0.85 + bark_hue_shift * 0.25)  # Standard tan
	
	var trunk_material = PixelTextureGenerator.create_pixel_material(bark_texture, bark_tint)
	trunk_mesh.set_surface_override_material(0, trunk_material)
	
	# Palm fronds with pixelated texture
	var leaves_texture = PixelTextureGenerator.create_leaves_texture()
	
	# Foliage color variation
	var green_variation = randf()
	var foliage_tint: Color
	if green_variation > 0.7:
		foliage_tint = Color(0.7, 1.5, 0.9)  # Lighter tropical green
	elif green_variation > 0.3:
		foliage_tint = Color(0.6, 1.4, 0.8)  # Standard tropical green
	else:
		foliage_tint = Color(0.5, 1.3, 0.7)  # Darker tropical green
	
	# Character tree frond modifications
	var palm_count = 6 + randi() % 3  # 6-8 fronds
	var frond_length = 2.0 + randf() * 0.8
	
	if is_character_tree:
		match character_type:
			0:  # Bent - fronds droop more
				frond_length *= 1.2
			1:  # Hurricane-damaged - fewer, broken fronds
				palm_count = 3 + randi() % 3  # Only 3-5 fronds
				frond_length *= 0.7
			2:  # Ancient - more, longer fronds
				palm_count = 8 + randi() % 3  # 8-10 fronds
				frond_length *= 1.3
	
	# Asymmetry for wind effect
	var asymmetry_angle = randf() * TAU
	var asymmetry_strength = spawner.branch_asymmetry_amount * randf() * 0.7  # Palms have less asymmetry
	
	for i in range(palm_count):
		# Base angle distribution
		var angle = (i / float(palm_count)) * TAU
		
		# Apply asymmetry (some fronds favor one side)
		var angle_diff = fmod(angle - asymmetry_angle + PI, TAU) - PI
		var asymmetry_factor = 1.0 - abs(angle_diff) / PI
		var frond_probability = 1.0 - asymmetry_strength * (1.0 - asymmetry_factor)
		
		# Skip some fronds on "away" side
		if randf() > frond_probability and not is_character_tree:
			continue
		
		var frond = MeshInstance3D.new()
		trunk_mesh.add_child(frond)
		
		var box_mesh = BoxMesh.new()
		var this_frond_length = frond_length * (0.9 + randf() * 0.2)  # Individual variation
		# Favored side fronds are slightly longer
		this_frond_length *= (1.0 + asymmetry_factor * asymmetry_strength * 0.25)
		box_mesh.size = Vector3(0.2, 0.1, this_frond_length)
		frond.mesh = box_mesh
		
		frond.position = Vector3(0, trunk_height * 0.45, 0)
		frond.rotation.y = angle
		
		# Droop angle varies
		var droop = -0.5 - randf() * 0.3  # Base droop
		if is_character_tree and character_type == 0:  # Bent palms droop more
			droop -= 0.4
		frond.rotation.x = droop
		
		var frond_material = PixelTextureGenerator.create_pixel_material(leaves_texture, foliage_tint)
		frond.set_surface_override_material(0, frond_material)
	
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
