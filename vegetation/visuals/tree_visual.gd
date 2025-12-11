class_name TreeVisual
extends Node

"""
TreeVisual - Procedural tree mesh generator

Creates harvestable oak/deciduous trees with:
- Variety in shape (pyramidal, round, wide-spread)
- Trunk tilt and asymmetric branching
- Rare "character" trees with unique features
- Natural color variation

Called by VegetationSpawner during chunk population.
"""

const HarvestableTreeClass = preload("res://harvestable_tree.gd")

## Create a harvestable tree with variety in shape, trunk tilt, asymmetry, and rare character trees
static func create(
	mesh_instance: MeshInstance3D,
	spawner: VegetationSpawner
) -> void:
	var parent = mesh_instance.get_parent()
	var tree_position = mesh_instance.global_position
	
	# Create the harvestable tree node
	var tree = HarvestableTreeClass.new()
	tree.tree_type = HarvestableTreeClass.TreeType.NORMAL
	
	# Set collision for harvesting
	tree.collision_layer = 2
	tree.collision_mask = 0
	
	# Much more varied tree sizes - configurable
	var trunk_height: float = spawner.tree_height_min + randf() * (spawner.tree_height_max - spawner.tree_height_min)
	
	# Scale trunk radius and foliage based on height
	var height_ratio = (trunk_height - spawner.tree_height_min) / (spawner.tree_height_max - spawner.tree_height_min)
	var trunk_radius = spawner.trunk_radius_base * (0.8 + height_ratio * 0.6)  # 80-140% of base
	var foliage_size_multiplier = 0.9 + height_ratio * 0.8  # 0.9-1.7 multiplier
	
	# Character tree check (rare special trees)
	var is_character_tree = randf() < spawner.character_tree_chance
	var character_type = 0  # 0=gnarly, 1=lightning, 2=ancient
	if is_character_tree:
		character_type = randi() % 3
	
	# Determine tree shape (affects branch angles and distribution)
	var shape_roll = randf()
	var tree_shape: VegetationSpawner.TreeShape
	if is_character_tree and character_type == 2:  # Ancient trees are wide spread
		tree_shape = VegetationSpawner.TreeShape.WIDE_SPREAD
	elif shape_roll < 0.3:
		tree_shape = VegetationSpawner.TreeShape.PYRAMIDAL
	elif shape_roll < 0.7:
		tree_shape = VegetationSpawner.TreeShape.ROUND
	else:
		tree_shape = VegetationSpawner.TreeShape.WIDE_SPREAD
	
	# Calculate trunk tilt using noise for natural randomness
	var tilt_noise = spawner.vegetation_noise.get_noise_2d(tree_position.x * 0.1, tree_position.z * 0.1)
	var tilt_amount = abs(tilt_noise) * spawner.trunk_tilt_max * (0.5 + height_ratio * spawner.trunk_tilt_influence)
	if is_character_tree and character_type == 0:  # Gnarly trees lean more
		tilt_amount *= 1.8
	var tilt_direction = randf() * TAU  # Random direction
	var trunk_tilt_x = cos(tilt_direction) * tilt_amount
	var trunk_tilt_z = sin(tilt_direction) * tilt_amount
	
	# Branch asymmetry direction (used for wind-stressed look)
	var asymmetry_angle = randf() * TAU
	var asymmetry_strength = spawner.branch_asymmetry_amount * randf()
	
	# Create trunk
	var trunk_mesh = MeshInstance3D.new()
	tree.add_child(trunk_mesh)
	
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = trunk_height
	
	# Character tree trunk modifications
	if is_character_tree:
		match character_type:
			0:  # Gnarly - thicker, more tapered
				cylinder_mesh.top_radius = trunk_radius * 0.5
				cylinder_mesh.bottom_radius = trunk_radius * 1.3
			1:  # Lightning struck - thinner top
				cylinder_mesh.top_radius = trunk_radius * 0.4
				cylinder_mesh.bottom_radius = trunk_radius
			2:  # Ancient - massive trunk
				cylinder_mesh.top_radius = trunk_radius * 0.9
				cylinder_mesh.bottom_radius = trunk_radius * 1.5
				trunk_height *= 1.2
				cylinder_mesh.height = trunk_height
	else:
		cylinder_mesh.top_radius = trunk_radius * 0.7  # Tapers toward top
		cylinder_mesh.bottom_radius = trunk_radius
	
	trunk_mesh.mesh = cylinder_mesh
	trunk_mesh.position.y = trunk_height / 2
	
	# Apply trunk tilt BEFORE adding branches/foliage so local space is correct
	trunk_mesh.rotation.x = trunk_tilt_x
	trunk_mesh.rotation.z = trunk_tilt_z
	
	# Bark texture with more color variation
	var bark_texture = PixelTextureGenerator.create_bark_texture()
	var bark_hue_shift = randf() * 0.25  # More variation
	var bark_tint: Color
	
	# Character trees can have distinct bark
	if is_character_tree and character_type == 2:  # Ancient - darker, grayer bark
		bark_tint = Color(0.45 + bark_hue_shift * 0.4, 0.40 + bark_hue_shift * 0.3, 0.35 + bark_hue_shift * 0.25)
	else:
		# Normal variation: medium browns to gray-browns
		var brown_intensity = randf()
		if brown_intensity > 0.7:
			bark_tint = Color(0.60 + bark_hue_shift * 0.5, 0.48 + bark_hue_shift * 0.4, 0.32 + bark_hue_shift * 0.3)  # Warmer brown
		elif brown_intensity > 0.3:
			bark_tint = Color(0.55 + bark_hue_shift * 0.5, 0.42 + bark_hue_shift * 0.4, 0.28 + bark_hue_shift * 0.3)  # Medium brown
		else:
			bark_tint = Color(0.48 + bark_hue_shift * 0.5, 0.44 + bark_hue_shift * 0.4, 0.38 + bark_hue_shift * 0.35)  # Gray-brown
	
	var trunk_material = PixelTextureGenerator.create_pixel_material(bark_texture, bark_tint)
	trunk_mesh.set_surface_override_material(0, trunk_material)
	
	# Pixelated leaves texture with color variation
	var leaves_texture = PixelTextureGenerator.create_leaves_texture()
	var green_variation = randf()
	var foliage_tint: Color
	if green_variation > 0.7:
		foliage_tint = Color(0.9, 1.0, 0.9)  # Lighter green
	elif green_variation > 0.3:
		foliage_tint = Color(0.85, 0.95, 0.85)  # Standard green
	else:
		foliage_tint = Color(0.75, 0.85, 0.75)  # Darker green
	var foliage_material = PixelTextureGenerator.create_pixel_material(leaves_texture, foliage_tint)
	
	# Shape-specific parameters
	var branch_count: int
	var branch_angle_variation: float
	var branch_vertical_angle: float
	var top_crown_size_mod: float
	var branch_height_range_end: float  # How high branches go (fraction of trunk)
	
	match tree_shape:
		VegetationSpawner.TreeShape.PYRAMIDAL:
			branch_count = spawner.branch_count_min + 1
			branch_angle_variation = 0.3  # Less horizontal spread
			branch_vertical_angle = spawner.branch_upward_angle * 1.5  # Steeper upward
			top_crown_size_mod = 0.8  # Smaller top crown
			branch_height_range_end = spawner.branch_height_end  # Standard
		VegetationSpawner.TreeShape.ROUND:
			branch_count = (spawner.branch_count_min + spawner.branch_count_max) / 2
			branch_angle_variation = 0.6  # Moderate spread
			branch_vertical_angle = spawner.branch_upward_angle  # Standard angle
			top_crown_size_mod = 1.0  # Normal crown
			branch_height_range_end = spawner.branch_height_end  # Standard
		VegetationSpawner.TreeShape.WIDE_SPREAD:
			branch_count = spawner.branch_count_max
			branch_angle_variation = 1.2  # Maximum spread
			branch_vertical_angle = spawner.branch_upward_angle * 0.4  # Nearly horizontal
			top_crown_size_mod = 1.3  # Larger, flatter crown
			branch_height_range_end = min(0.92, spawner.branch_height_end + 0.07)  # Branches reach higher
	
	# Character tree modifications
	if is_character_tree:
		match character_type:
			0:  # Gnarly - more branches, wild angles
				branch_count += 2
				branch_angle_variation *= 1.5
			1:  # Lightning struck - fewer branches, reduced top crown
				branch_count = max(2, branch_count - 2)
				top_crown_size_mod *= 0.5
			2:  # Ancient - more branches, wider spread
				branch_count += 1
				branch_angle_variation *= 1.3
				top_crown_size_mod *= 1.4
	
	# Create natural branching structure with asymmetry
	var top_foliage_height_ratio = spawner.top_crown_height_ratio + randf() * 0.08
	if is_character_tree and character_type == 1:  # Lightning struck - lower crown
		top_foliage_height_ratio *= 0.7
	elif tree_shape == VegetationSpawner.TreeShape.WIDE_SPREAD:  # Wide-spread trees have lower crowns
		top_foliage_height_ratio *= 0.92  # Start crown slightly lower (8% lower)
	var top_foliage_height = trunk_height * top_foliage_height_ratio
	
	for i in range(branch_count):
		# Base angle distribution
		var branch_angle = (i / float(branch_count)) * TAU + (randf() - 0.5) * 1.0
		
		# Apply asymmetry (branches favor one side)
		var angle_diff = fmod(branch_angle - asymmetry_angle + PI, TAU) - PI  # Distance from favored direction
		var asymmetry_factor = 1.0 - abs(angle_diff) / PI  # 1.0 at favored angle, 0.0 at opposite
		var branch_probability = 1.0 - asymmetry_strength * (1.0 - asymmetry_factor)
		
		# Skip some branches on the "away" side for asymmetric look
		if randf() > branch_probability:
			continue
		
		var branch_height_ratio = spawner.branch_height_start + (i / float(branch_count)) * (branch_height_range_end - spawner.branch_height_start)
		var branch_height_local = trunk_height * branch_height_ratio
		
		# Branch length varies by shape and asymmetry
		var branch_length = (spawner.branch_length_min + randf() * (spawner.branch_length_max - spawner.branch_length_min)) * foliage_size_multiplier
		branch_length *= (0.9 + randf() * 0.3)  # Individual variation
		# Branches on favored side are slightly longer
		branch_length *= (1.0 + asymmetry_factor * asymmetry_strength * 0.3)
		
		# Calculate branch start point (on trunk at height)
		var branch_start_local = Vector3(0, branch_height_local - trunk_height / 2, 0)
		
		# Calculate branch end point with shape-specific spread
		var horizontal_extent = branch_length * (0.85 + branch_angle_variation * 0.15)
		var vertical_rise = branch_length * branch_vertical_angle
		var branch_end_local = Vector3(
			cos(branch_angle) * horizontal_extent,
			(branch_height_local - trunk_height / 2) + vertical_rise,
			sin(branch_angle) * horizontal_extent
		)
		
		# Create branch cylinder
		var branch = MeshInstance3D.new()
		trunk_mesh.add_child(branch)
		
		var branch_mesh = CylinderMesh.new()
		branch_mesh.height = branch_length
		branch_mesh.top_radius = trunk_radius * 0.15
		branch_mesh.bottom_radius = trunk_radius * 0.22
		branch.mesh = branch_mesh
		
		# Position branch at midpoint between start and end
		branch.position = (branch_start_local + branch_end_local) / 2.0
		
		# Rotate branch to point from start to end
		var branch_direction = (branch_end_local - branch_start_local).normalized()
		var default_up = Vector3.UP
		
		# Only rotate if not already aligned
		if not branch_direction.is_equal_approx(default_up):
			var rotation_axis = default_up.cross(branch_direction)
			if rotation_axis.length() > 0.001:
				rotation_axis = rotation_axis.normalized()
				var rotation_angle = acos(clamp(default_up.dot(branch_direction), -1.0, 1.0))
				branch.rotate(rotation_axis, rotation_angle)
		
		branch.set_surface_override_material(0, trunk_material)
		
		# Foliage cluster at branch end - layered discs
		var layer_count = spawner.branch_foliage_layers + (randi() % 2)
		
		for layer in range(layer_count):
			var foliage = MeshInstance3D.new()
			trunk_mesh.add_child(foliage)
			
			var disc_mesh = CylinderMesh.new()
			var disc_size = spawner.foliage_disc_size * (0.6 + randf() * 0.3) * foliage_size_multiplier
			disc_size *= (1.0 - layer * 0.18)  # Each layer progressively smaller
			disc_mesh.top_radius = disc_size
			disc_mesh.bottom_radius = disc_size * 0.9
			
			# Progressive thickness
			var base_thickness = spawner.foliage_disc_thickness + randf() * 0.15
			var thickness_factor = 1.0 - (layer / float(layer_count)) * 0.6
			disc_mesh.height = base_thickness * thickness_factor
			
			disc_mesh.radial_segments = 8
			disc_mesh.rings = 1
			foliage.mesh = disc_mesh
			
			# Stack layers vertically
			var layer_offset = layer * spawner.foliage_layer_gap
			foliage.position = branch_end_local + Vector3(0, layer_offset, 0)
			foliage.rotation.y = randf() * TAU
			
			foliage.set_surface_override_material(0, foliage_material)
	
	# Add top crown foliage - shape-specific sizing (skip for some character trees)
	if not (is_character_tree and character_type == 1 and randf() < 0.5):  # Lightning struck sometimes has no top crown
		var top_layer_count = spawner.top_foliage_layers + (randi() % 2)
		
		# Calculate crown centering offset for heavily tilted trees with asymmetric branches
		# This prevents top crown from looking disconnected on extreme lean + asymmetry
		var crown_center_offset = Vector3.ZERO
		if tilt_amount > spawner.trunk_tilt_max * 0.5 and asymmetry_strength > 0.2:
			# Shift crown slightly opposite to asymmetry direction to stay over branch mass
			var centering_strength = (tilt_amount / spawner.trunk_tilt_max) * asymmetry_strength * 0.4
			crown_center_offset = Vector3(
				-cos(asymmetry_angle) * centering_strength * trunk_height * 0.15,
				0,
				-sin(asymmetry_angle) * centering_strength * trunk_height * 0.15
			)
		
		for layer in range(top_layer_count):
			var top_foliage = MeshInstance3D.new()
			trunk_mesh.add_child(top_foliage)
			
			var top_disc = CylinderMesh.new()
			var top_size = spawner.foliage_disc_size * (0.8 + randf() * 0.4) * foliage_size_multiplier * top_crown_size_mod
			top_size *= (1.0 - layer * 0.15)
			top_disc.top_radius = top_size
			top_disc.bottom_radius = top_size * 0.85
			
			# Progressive thickness
			var base_thickness = spawner.foliage_disc_thickness * 1.1 + randf() * 0.2
			var thickness_factor = 1.0 - (layer / float(top_layer_count)) * 0.65
			top_disc.height = base_thickness * thickness_factor
			
			top_disc.radial_segments = 8
			top_disc.rings = 1
			top_foliage.mesh = top_disc
			
			# Stack layers with centering offset applied
			var layer_height_local = (top_foliage_height - trunk_height / 2) + layer * (spawner.foliage_layer_gap * 1.25)
			top_foliage.position = Vector3(0, layer_height_local, 0) + crown_center_offset
			top_foliage.rotation.y = randf() * TAU
			
			top_foliage.set_surface_override_material(0, foliage_material)
	
	# Add collision shape for the tree (scaled to trunk size)
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
