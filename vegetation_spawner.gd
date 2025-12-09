extends Node3D
class_name VegetationSpawner

# Preload resource node classes
const ResourceNodeClass = preload("res://resource_node.gd")
const HarvestableTreeClass = preload("res://harvestable_tree.gd")

# References
var chunk_manager: ChunkManager
var noise: FastNoiseLite
var vegetation_noise: FastNoiseLite
var player: Node3D

# Vegetation settings
@export var vegetation_density: float = 0.4  # 0.0 to 1.0, how much vegetation to spawn (increased)
@export var spawn_radius: int = 2  # How many chunks around player to populate

# Track which chunks have vegetation
var populated_chunks: Dictionary = {}
var initialized: bool = false

# Vegetation types per biome
enum VegType {
	TREE,
	PINE_TREE,
	ROCK,
	BOULDER,
	CACTUS,
	GRASS_TUFT,
	PALM_TREE,
	MUSHROOM_RED,      # Red cap with white spots (toadstool)
	MUSHROOM_BROWN,    # Brown cap (normal mushroom)
	MUSHROOM_CLUSTER   # Small cluster of tiny mushrooms
}

func _ready():
	# Initialize vegetation noise (different from terrain noise)
	vegetation_noise = FastNoiseLite.new()
	vegetation_noise.seed = randi()
	vegetation_noise.frequency = 0.5  # High frequency for scattered placement
	vegetation_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	print("VegetationSpawner ready, waiting for initialization...")

func initialize(chunk_mgr: ChunkManager):
	chunk_manager = chunk_mgr
	noise = chunk_manager.noise
	player = chunk_manager.player
	initialized = true
	print("VegetationSpawner initialized with player and chunk manager")

func _process(_delta):
	if not initialized or chunk_manager == null or player == null:
		return
	
	# Get player's chunk position
	var player_pos = player.global_position
	var player_chunk = chunk_manager.world_to_chunk(player_pos)
	
	# Populate chunks around player
	for x in range(player_chunk.x - spawn_radius, player_chunk.x + spawn_radius + 1):
		for z in range(player_chunk.y - spawn_radius, player_chunk.y + spawn_radius + 1):
			var chunk_pos = Vector2i(x, z)
			if not populated_chunks.has(chunk_pos) and chunk_manager.chunks.has(chunk_pos):
				populate_chunk(chunk_pos)
				print("Populating chunk: ", chunk_pos)

func populate_chunk(chunk_pos: Vector2i):
	if populated_chunks.has(chunk_pos):
		return
	
	populated_chunks[chunk_pos] = true
	
	var chunk_size = chunk_manager.chunk_size
	var world_offset = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)
	
	# Sample points across the chunk
	var samples_per_chunk = 25  # Moderate number of spawn attempts
	
	for i in range(samples_per_chunk):
		# Random position within chunk
		var local_x = randf() * chunk_size
		var local_z = randf() * chunk_size
		var world_x = world_offset.x + local_x
		var world_z = world_offset.y + local_z
		
		# Use vegetation noise to determine if we spawn here
		var veg_noise = vegetation_noise.get_noise_2d(world_x, world_z)
		# Use absolute value and check if above threshold (cellular noise ranges differently)
		if abs(veg_noise) < 0.3:
			continue  # Skip spots with low noise
		
		# Get terrain info at this position
		var base_noise = noise.get_noise_2d(world_x, world_z)
		var biome = get_biome_at_position(world_x, world_z, base_noise)
		
		# Get height at this position
		var height = get_terrain_height_at_position(world_x, world_z, base_noise, biome)
		
		# Don't spawn in water
		if biome == Chunk.Biome.OCEAN:
			continue
		
		# Spawn appropriate vegetation for this biome
		spawn_vegetation_for_biome(biome, Vector3(world_x, height, world_z), world_x, world_z)

func get_biome_at_position(world_x: float, world_z: float, base_noise: float) -> Chunk.Biome:
	# Same logic as chunk biome determination
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

func get_terrain_height_at_position(_world_x: float, _world_z: float, base_noise: float, biome: Chunk.Biome) -> float:
	# Approximate the terrain height calculation from chunk generation
	var height_multiplier = chunk_manager.height_multiplier
	
	# Get modifiers matching chunk.gd exactly
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
	
	# Apply baseline offset (MUST MATCH CHUNK.GD!)
	if biome == Chunk.Biome.OCEAN:
		height = height - (height_multiplier * 0.3)  # Ocean goes DOWN
	elif biome == Chunk.Biome.BEACH:
		height = height + (height_multiplier * 0.2)  # Beach at sea level
	else:
		height = height + (height_multiplier * 0.5)  # Normal baseline
	
	# Don't clamp - allow negative heights for ocean
	return height

func spawn_vegetation_for_biome(biome: Chunk.Biome, spawn_pos: Vector3, world_x: float, world_z: float):
	var veg_type: VegType
	
	# Determine vegetation type based on biome
	match biome:
		Chunk.Biome.FOREST:
			# Dense forest with mix of trees, undergrowth, and mushrooms
			var rand = randf()
			if rand > 0.65:
				veg_type = VegType.TREE
			elif rand > 0.35:
				veg_type = VegType.PINE_TREE
			elif rand > 0.25:
				veg_type = VegType.GRASS_TUFT
			elif rand > 0.15:
				# Mushrooms! More variety
				var mushroom_rand = randf()
				if mushroom_rand > 0.6:
					veg_type = VegType.MUSHROOM_RED
				elif mushroom_rand > 0.3:
					veg_type = VegType.MUSHROOM_BROWN
				else:
					veg_type = VegType.MUSHROOM_CLUSTER
			else:
				veg_type = VegType.ROCK  # Rocks in forest
		Chunk.Biome.GRASSLAND:
			# Lots of grass, some trees and rocks
			var rand = randf()
			if rand > 0.85:
				veg_type = VegType.TREE  # Rare trees
			elif rand > 0.7:
				veg_type = VegType.ROCK  # More rocks
			else:
				veg_type = VegType.GRASS_TUFT  # Mostly grass
		Chunk.Biome.DESERT:
			# Cacti and rocks
			var rand = randf()
			if rand > 0.6:
				veg_type = VegType.CACTUS
			elif rand > 0.2:
				veg_type = VegType.ROCK
			else:
				return  # Some empty desert
		Chunk.Biome.MOUNTAIN:
			# Very rocky
			var rand = randf()
			if rand > 0.5:
				veg_type = VegType.BOULDER
			else:
				veg_type = VegType.ROCK
		Chunk.Biome.SNOW:
			# Sparse pine trees and rocks
			var rand = randf()
			if rand > 0.7:
				veg_type = VegType.PINE_TREE
			elif rand > 0.3:
				veg_type = VegType.ROCK
			else:
				return  # Some empty snowy areas
		Chunk.Biome.BEACH:
			# Sparse vegetation
			var rand = randf()
			if rand > 0.85:
				veg_type = VegType.PALM_TREE
			elif rand > 0.7:
				veg_type = VegType.GRASS_TUFT
			else:
				return  # Mostly empty beach
		_:
			return
	
	# Create the vegetation mesh
	print("Spawning ", VegType.keys()[veg_type], " in biome ", Chunk.Biome.keys()[biome])
	create_vegetation_mesh(veg_type, spawn_pos, world_x, world_z)

func create_vegetation_mesh(veg_type: VegType, spawn_pos: Vector3, _world_x: float, _world_z: float):
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Height offsets for all vegetation types
	# Add small random downward jitter to prevent floating
	var jitter = randf_range(0.0, 0.15)  # Random sink 0-0.15m
	var adjusted_position = spawn_pos
	adjusted_position.y -= jitter  # Apply jitter to all vegetation
	
	match veg_type:
		VegType.ROCK:
			adjusted_position.y -= 0.15  # Sink rocks into ground
		VegType.BOULDER:
			adjusted_position.y -= 0.15  # Sink boulders into ground
		VegType.GRASS_TUFT:
			adjusted_position.y -= 0.1  # Sink grass slightly
		VegType.CACTUS:
			adjusted_position.y += 0.2  # Cacti lift (after jitter)
		VegType.TREE, VegType.PALM_TREE, VegType.PINE_TREE:
			adjusted_position.y += 0.0  # Trees at ground level
		VegType.MUSHROOM_RED, VegType.MUSHROOM_BROWN:
			adjusted_position.y -= 0.1  # Sink mushrooms
		VegType.MUSHROOM_CLUSTER:
			adjusted_position.y -= 0.1  # Sink clusters
	
	mesh_instance.global_position = adjusted_position
	
	# Add slight random rotation
	mesh_instance.rotation.y = randf() * TAU
	
	# Create appropriate mesh based on type
	match veg_type:
		VegType.TREE:
			create_harvestable_tree(mesh_instance, HarvestableTreeClass.TreeType.NORMAL)
		VegType.PINE_TREE:
			create_harvestable_tree(mesh_instance, HarvestableTreeClass.TreeType.PINE)
		VegType.PALM_TREE:
			create_harvestable_tree(mesh_instance, HarvestableTreeClass.TreeType.PALM)
		VegType.ROCK:
			create_rock(mesh_instance, false)
		VegType.BOULDER:
			create_rock(mesh_instance, true)
		VegType.CACTUS:
			create_cactus(mesh_instance)
		VegType.GRASS_TUFT:
			create_grass_tuft(mesh_instance)
		VegType.MUSHROOM_RED:
			create_mushroom(mesh_instance, true, false)
		VegType.MUSHROOM_BROWN:
			create_mushroom(mesh_instance, false, false)
		VegType.MUSHROOM_CLUSTER:
			create_mushroom(mesh_instance, false, true)

func create_harvestable_tree(mesh_instance: MeshInstance3D, tree_type: HarvestableTreeClass.TreeType):
	"""Convert a tree mesh instance into a HarvestableTree"""
	# Store position before replacement
	var tree_position = mesh_instance.global_position
	var parent = mesh_instance.get_parent()
	
	# Create a HarvestableTree to replace the mesh instance
	var harvestable_tree = HarvestableTreeClass.new()
	harvestable_tree.tree_type = tree_type
	
	# Determine tree height based on type
	var tree_height = 6.0
	match tree_type:
		HarvestableTreeClass.TreeType.NORMAL:
			tree_height = 4.0 + randf() * 2.0
		HarvestableTreeClass.TreeType.PINE:
			tree_height = 5.0 + randf() * 2.0
		HarvestableTreeClass.TreeType.PALM:
			tree_height = 3.5 + randf() * 1.5
	
	harvestable_tree.tree_height = tree_height
	
	# Create the tree mesh as a child
	var tree_mesh = MeshInstance3D.new()
	harvestable_tree.add_child(tree_mesh)
	
	# Generate the appropriate tree mesh
	match tree_type:
		HarvestableTreeClass.TreeType.NORMAL:
			create_tree(tree_mesh, false)
		HarvestableTreeClass.TreeType.PINE:
			create_pine_tree(tree_mesh)
		HarvestableTreeClass.TreeType.PALM:
			create_tree(tree_mesh, true)
	
	# Add collision to the tree (cylinder around trunk)
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.5  # Slightly larger than visual trunk
	shape.height = tree_height
	collision.shape = shape
	collision.position.y = tree_height / 2.0  # Center vertically
	harvestable_tree.add_child(collision)
	
	# Replace mesh_instance with harvestable_tree in scene tree
	parent.remove_child(mesh_instance)
	parent.add_child(harvestable_tree)
	
	# Set position after adding to tree
	harvestable_tree.global_position = tree_position
	
	mesh_instance.queue_free()

func create_tree(mesh_instance: MeshInstance3D, is_palm: bool):
	# Simple tree: cylinder trunk + cone/sphere canopy (REALISTIC PROPORTIONS)
	var trunk_height = 5.0 + randf() * 3.0  # 5-8m tall (realistic)
	var trunk_radius = 0.15  # Thinner trunk (0.3m diameter)
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Trunk (simple cylinder approximation)
	var trunk_color = Color(0.4, 0.25, 0.1) if not is_palm else Color(0.6, 0.4, 0.2)
	var sides = 8  # More sides for smoother look
	for i in range(sides):
		var angle1 = (i / float(sides)) * TAU
		var angle2 = ((i + 1) / float(sides)) * TAU
		
		var x1 = cos(angle1) * trunk_radius
		var z1 = sin(angle1) * trunk_radius
		var x2 = cos(angle2) * trunk_radius
		var z2 = sin(angle2) * trunk_radius
		
		# Bottom triangle
		surface_tool.set_color(trunk_color)
		surface_tool.add_vertex(Vector3(x1, 0, z1))
		surface_tool.add_vertex(Vector3(x2, 0, z2))
		surface_tool.add_vertex(Vector3(x1, trunk_height, z1))
		
		# Top triangle
		surface_tool.add_vertex(Vector3(x2, 0, z2))
		surface_tool.add_vertex(Vector3(x2, trunk_height, z2))
		surface_tool.add_vertex(Vector3(x1, trunk_height, z1))
	
	# Canopy (simple cone/sphere) - REALISTIC PROPORTIONS
	var canopy_color = Color(0.2, 0.6, 0.2) if not is_palm else Color(0.3, 0.7, 0.3)
	var canopy_radius = 1.5 if not is_palm else 1.2  # Narrower canopy (3m wide)
	var canopy_height = 4.0 if not is_palm else 3.0  # Taller canopy
	var canopy_base_y = trunk_height
	
	for i in range(sides):
		var angle1 = (i / float(sides)) * TAU
		var angle2 = ((i + 1) / float(sides)) * TAU
		
		var x1 = cos(angle1) * canopy_radius
		var z1 = sin(angle1) * canopy_radius
		var x2 = cos(angle2) * canopy_radius
		var z2 = sin(angle2) * canopy_radius
		
		# Cone sides
		surface_tool.set_color(canopy_color)
		surface_tool.add_vertex(Vector3(x1, canopy_base_y, z1))
		surface_tool.add_vertex(Vector3(x2, canopy_base_y, z2))
		surface_tool.add_vertex(Vector3(0, canopy_base_y + canopy_height, 0))
		
		# Bottom disc (close the hole)
		surface_tool.set_color(canopy_color * 0.8)  # Slightly darker
		surface_tool.add_vertex(Vector3(0, canopy_base_y, 0))  # Center
		surface_tool.add_vertex(Vector3(x2, canopy_base_y, z2))
		surface_tool.add_vertex(Vector3(x1, canopy_base_y, z1))
	
	surface_tool.generate_normals()
	var tree_mesh = surface_tool.commit()
	
	# Create material that uses vertex colors
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	tree_mesh.surface_set_material(0, material)
	
	mesh_instance.mesh = tree_mesh

func create_pine_tree(mesh_instance: MeshInstance3D):
	# Taller, thinner cone for pine trees (REALISTIC)
	var trunk_height = 6.0 + randf() * 3.0  # 6-9m tall
	var trunk_radius = 0.12  # Thin trunk
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var trunk_color = Color(0.3, 0.2, 0.1)
	var foliage_color = Color(0.1, 0.4, 0.2)
	
	# Simple trunk
	var sides = 6
	for i in range(sides):
		var angle1 = (i / float(sides)) * TAU
		var angle2 = ((i + 1) / float(sides)) * TAU
		
		var x1 = cos(angle1) * trunk_radius
		var z1 = sin(angle1) * trunk_radius
		var x2 = cos(angle2) * trunk_radius
		var z2 = sin(angle2) * trunk_radius
		
		surface_tool.set_color(trunk_color)
		surface_tool.add_vertex(Vector3(x1, 0, z1))
		surface_tool.add_vertex(Vector3(x2, 0, z2))
		surface_tool.add_vertex(Vector3(0, trunk_height, 0))
	
	# Cone-shaped foliage (narrower for realistic pine)
	var cone_radius = 1.0  # 2m wide
	var cone_height = trunk_height * 0.75  # Most of the tree
	var cone_start_y = trunk_height * 0.25  # Starts 1/4 up
	
	for i in range(sides):
		var angle1 = (i / float(sides)) * TAU
		var angle2 = ((i + 1) / float(sides)) * TAU
		
		var x1 = cos(angle1) * cone_radius
		var z1 = sin(angle1) * cone_radius
		var x2 = cos(angle2) * cone_radius
		var z2 = sin(angle2) * cone_radius
		
		# Cone sides
		surface_tool.set_color(foliage_color)
		surface_tool.add_vertex(Vector3(x1, cone_start_y, z1))
		surface_tool.add_vertex(Vector3(x2, cone_start_y, z2))
		surface_tool.add_vertex(Vector3(0, cone_start_y + cone_height, 0))
		
		# Bottom disc
		surface_tool.set_color(foliage_color * 0.8)
		surface_tool.add_vertex(Vector3(0, cone_start_y, 0))
		surface_tool.add_vertex(Vector3(x2, cone_start_y, z2))
		surface_tool.add_vertex(Vector3(x1, cone_start_y, z1))
	
	surface_tool.generate_normals()
	var pine_mesh = surface_tool.commit()
	
	# Create material that uses vertex colors
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	pine_mesh.surface_set_material(0, material)
	
	mesh_instance.mesh = pine_mesh

func create_rock(mesh_instance: MeshInstance3D, is_boulder: bool):
	# Convert the mesh instance parent to a ResourceNode
	var parent = mesh_instance.get_parent()
	
	# Store the position before creating the new node
	var rock_position = mesh_instance.global_position
	
	# Create a ResourceNode to replace the mesh instance
	var resource_node = ResourceNodeClass.new()
	resource_node.node_type = ResourceNodeClass.NodeType.STONE_DEPOSIT if is_boulder else ResourceNodeClass.NodeType.ROCK
	
	# Create the mesh as a child of the resource node
	var rock_mesh = MeshInstance3D.new()
	resource_node.add_child(rock_mesh)
	
	# Use SphereMesh - simple and works perfectly
	var size = 0.4 + randf() * 0.3 if not is_boulder else 0.7 + randf() * 0.4  # Smaller rocks
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = size / 2
	sphere_mesh.height = size
	
	# Create material with natural rock colors
	var material = StandardMaterial3D.new()
	if is_boulder:
		material.albedo_color = Color(0.35, 0.35, 0.35)  # Dark gray
	else:
		material.albedo_color = Color(0.55, 0.5, 0.45)  # Light gray-brown
	material.roughness = 0.95
	
	sphere_mesh.material = material
	
	rock_mesh.mesh = sphere_mesh
	# Position is already adjusted in create_vegetation_mesh
	
	# Random slight tilt
	rock_mesh.rotation.x = (randf() - 0.5) * 0.3
	rock_mesh.rotation.z = (randf() - 0.5) * 0.3
	
	# Flatten it to make it look more rock-like
	rock_mesh.scale = Vector3(1.0, 0.6, 0.9)  # Flatter
	
	# Add collision shape for the resource
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = size / 2
	collision.shape = shape
	resource_node.add_child(collision)
	
	# Replace mesh_instance with resource_node in the scene tree
	parent.remove_child(mesh_instance)
	parent.add_child(resource_node)
	
	# Now set the position (after it's in the tree)
	resource_node.global_position = rock_position
	
	mesh_instance.queue_free()

func create_cactus(mesh_instance: MeshInstance3D):
	# Simple cactus: tall cylinder
	var height = 1.5 + randf() * 1.0
	var radius = 0.2
	
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = height
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	
	mesh_instance.mesh = cylinder_mesh
	# Position is handled in create_vegetation_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.6, 0.3)
	material.roughness = 0.7
	mesh_instance.set_surface_override_material(0, material)

func create_grass_tuft(mesh_instance: MeshInstance3D):
	# Realistic grass tuft size (0.3-0.6m tall)
	var height = 0.3 + randf() * 0.3  # 0.3-0.6m tall
	var width = 0.05 + randf() * 0.05  # 0.05-0.1m wide (thin blades)
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width, height, width)
	
	mesh_instance.mesh = box_mesh
	# Position is handled in create_vegetation_mesh
	
	var material = StandardMaterial3D.new()
	# Bright, varied greens so they're very visible
	var green_variation = randf()
	if green_variation > 0.7:
		material.albedo_color = Color(0.8, 1.0, 0.3)  # Yellow-green
	elif green_variation > 0.4:
		material.albedo_color = Color(0.3, 0.9, 0.3)  # Bright green
	else:
		material.albedo_color = Color(0.4, 0.8, 0.2)  # Regular green
	material.roughness = 0.5
	mesh_instance.set_surface_override_material(0, material)

func create_mushroom(mesh_instance: MeshInstance3D, is_red: bool, is_cluster: bool):
	if is_cluster:
		# Create a cluster of small mushrooms
		var cluster_count = 3 + randi() % 3  # 3-5 mushrooms
		
		for i in range(cluster_count):
			var small_mushroom = MeshInstance3D.new()
			mesh_instance.add_child(small_mushroom)
			
			# Random offset within small area
			var offset_x = (randf() - 0.5) * 0.3
			var offset_z = (randf() - 0.5) * 0.3
			small_mushroom.position = Vector3(offset_x, 0, offset_z)
			
			# Create tiny mushroom
			create_single_mushroom(small_mushroom, false, 0.15 + randf() * 0.1)
	else:
		# Create single mushroom
		var size = 0.2 + randf() * 0.15
		create_single_mushroom(mesh_instance, is_red, size)

func create_single_mushroom(mesh_instance: MeshInstance3D, is_red: bool, size: float):
	# Mushroom = stem (cylinder) + cap (hemisphere/cone)
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Stem dimensions
	var stem_height = size * 1.5
	var stem_radius = size * 0.15
	
	# Cap dimensions
	var cap_radius = size * 0.8
	var cap_height = size * 0.5
	
	# Colors
	var stem_color = Color(0.9, 0.85, 0.75)  # Off-white/cream
	var cap_color = Color(0.8, 0.15, 0.1) if is_red else Color(0.5, 0.35, 0.25)  # Red or brown
	var spot_color = Color(0.95, 0.95, 0.9)  # White spots for red mushrooms
	
	var sides = 8
	
	# Create stem (cylinder)
	for i in range(sides):
		var angle1 = (i / float(sides)) * TAU
		var angle2 = ((i + 1) / float(sides)) * TAU
		
		var x1 = cos(angle1) * stem_radius
		var z1 = sin(angle1) * stem_radius
		var x2 = cos(angle2) * stem_radius
		var z2 = sin(angle2) * stem_radius
		
		# Stem side
		surface_tool.set_color(stem_color)
		surface_tool.add_vertex(Vector3(x1, 0, z1))
		surface_tool.add_vertex(Vector3(x2, 0, z2))
		surface_tool.add_vertex(Vector3(x1, stem_height, z1))
		
		surface_tool.add_vertex(Vector3(x2, 0, z2))
		surface_tool.add_vertex(Vector3(x2, stem_height, z2))
		surface_tool.add_vertex(Vector3(x1, stem_height, z1))
	
	# Create cap (rounded dome shape with proper top closure)
	var cap_base_y = stem_height
	var cap_segments = 5  # Vertical segments for roundness
	
	for segment in range(cap_segments):
		var t1 = segment / float(cap_segments)
		var t2 = (segment + 1) / float(cap_segments)
		
		# Use sine curve for dome shape
		var radius1 = cap_radius * sin(t1 * PI * 0.5)
		var radius2 = cap_radius * sin(t2 * PI * 0.5)
		var height1 = cap_base_y + (1.0 - cos(t1 * PI * 0.5)) * cap_height
		var height2 = cap_base_y + (1.0 - cos(t2 * PI * 0.5)) * cap_height
		
		# Last segment closes to a point at top
		if segment == cap_segments - 1:
			radius2 = 0.0
			height2 = cap_base_y + cap_height
			
			# Make triangles that converge to center point
			for i in range(sides):
				var angle1 = (i / float(sides)) * TAU
				var angle2 = ((i + 1) / float(sides)) * TAU
				
				var x1 = cos(angle1) * radius1
				var z1 = sin(angle1) * radius1
				var x2 = cos(angle2) * radius1
				var z2 = sin(angle2) * radius1
				
				surface_tool.set_color(cap_color)
				surface_tool.add_vertex(Vector3(x1, height1, z1))
				surface_tool.add_vertex(Vector3(x2, height1, z2))
				surface_tool.add_vertex(Vector3(0, height2, 0))  # Top center point
		else:
			# Normal dome segments
			for i in range(sides):
				var angle1 = (i / float(sides)) * TAU
				var angle2 = ((i + 1) / float(sides)) * TAU
				
				var x1a = cos(angle1) * radius1
				var z1a = sin(angle1) * radius1
				var x2a = cos(angle2) * radius1
				var z2a = sin(angle2) * radius1
				
				var x1b = cos(angle1) * radius2
				var z1b = sin(angle1) * radius2
				var x2b = cos(angle2) * radius2
				var z2b = sin(angle2) * radius2
				
				# Cap segment (quad as two triangles)
				surface_tool.set_color(cap_color)
				surface_tool.add_vertex(Vector3(x1a, height1, z1a))
				surface_tool.add_vertex(Vector3(x2a, height1, z2a))
				surface_tool.add_vertex(Vector3(x1b, height2, z1b))
				
				surface_tool.add_vertex(Vector3(x2a, height1, z2a))
				surface_tool.add_vertex(Vector3(x2b, height2, z2b))
				surface_tool.add_vertex(Vector3(x1b, height2, z1b))
	
	# Add underside (gills) - flat disc under the cap
	for i in range(sides):
		var angle1 = (i / float(sides)) * TAU
		var angle2 = ((i + 1) / float(sides)) * TAU
		
		var x1 = cos(angle1) * cap_radius
		var z1 = sin(angle1) * cap_radius
		var x2 = cos(angle2) * cap_radius
		var z2 = sin(angle2) * cap_radius
		
		# Underside triangles (darker color for gills)
		surface_tool.set_color(cap_color * 0.7)
		surface_tool.add_vertex(Vector3(0, cap_base_y, 0))  # Center
		surface_tool.add_vertex(Vector3(x2, cap_base_y, z2))  # Note: reversed winding
		surface_tool.add_vertex(Vector3(x1, cap_base_y, z1))
	
	# Add white spots for red mushrooms (simple small circles on top)
	if is_red:
		var spot_count = 3 + randi() % 3  # 3-5 spots
		for spot in range(spot_count):
			var spot_angle = (spot / float(spot_count)) * TAU + randf() * 0.5
			var spot_distance = cap_radius * (0.4 + randf() * 0.3)
			var spot_x = cos(spot_angle) * spot_distance
			var spot_z = sin(spot_angle) * spot_distance
			var spot_y = cap_base_y + cap_height * 0.7  # Near top
			var spot_size = size * 0.15
			
			# Simple spot (small quad)
			for i in range(4):
				var a = (i / 4.0) * TAU
				var sx = spot_x + cos(a) * spot_size
				var sz = spot_z + sin(a) * spot_size
				
				surface_tool.set_color(spot_color)
				surface_tool.add_vertex(Vector3(spot_x, spot_y, spot_z))
				surface_tool.add_vertex(Vector3(sx, spot_y, sz))
				
				var next_a = ((i + 1) / 4.0) * TAU
				var next_sx = spot_x + cos(next_a) * spot_size
				var next_sz = spot_z + sin(next_a) * spot_size
				surface_tool.add_vertex(Vector3(next_sx, spot_y, next_sz))
	
	# Generate normals and commit
	surface_tool.generate_normals()
	var mushroom_mesh = surface_tool.commit()
	
	# Create material
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	material.roughness = 0.6
	mushroom_mesh.surface_set_material(0, material)
	
	mesh_instance.mesh = mushroom_mesh
