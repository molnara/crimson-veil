extends Node3D
class_name VegetationSpawner

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
	PALM_TREE
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

func get_terrain_height_at_position(world_x: float, world_z: float, base_noise: float, biome: Chunk.Biome) -> float:
	# Approximate the terrain height calculation from chunk generation
	var height_multiplier = chunk_manager.height_multiplier
	
	# Get modifiers (simplified - using fixed values)
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
	
	# Apply baseline offset
	if biome == Chunk.Biome.OCEAN:
		height = height + (height_multiplier * 0.3)
	elif biome == Chunk.Biome.BEACH:
		height = height + (height_multiplier * 0.4)
	else:
		height = height + (height_multiplier * 0.5)
	
	return max(0.0, height)

func spawn_vegetation_for_biome(biome: Chunk.Biome, position: Vector3, world_x: float, world_z: float):
	var veg_type: VegType
	
	# Determine vegetation type based on biome
	match biome:
		Chunk.Biome.FOREST:
			# Dense forest with mix of trees and undergrowth
			var rand = randf()
			if rand > 0.65:
				veg_type = VegType.TREE
			elif rand > 0.35:
				veg_type = VegType.PINE_TREE
			elif rand > 0.15:
				veg_type = VegType.GRASS_TUFT  # More undergrowth
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
	create_vegetation_mesh(veg_type, position, world_x, world_z)

func create_vegetation_mesh(veg_type: VegType, position: Vector3, world_x: float, world_z: float):
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Height offsets for all vegetation types
	var adjusted_position = position
	match veg_type:
		VegType.ROCK:
			adjusted_position.y += 0.15
		VegType.BOULDER:
			adjusted_position.y += 0.15
		VegType.GRASS_TUFT:
			adjusted_position.y += 0.5  # Lower grass
		VegType.CACTUS:
			adjusted_position.y += 1.0  # Cacti need lift
		VegType.TREE, VegType.PALM_TREE, VegType.PINE_TREE:
			adjusted_position.y += 0.0  # Trees start at ground level
	
	mesh_instance.global_position = adjusted_position
	
	# Add slight random rotation
	mesh_instance.rotation.y = randf() * TAU
	
	# Create appropriate mesh based on type
	match veg_type:
		VegType.TREE:
			create_tree(mesh_instance, false)
		VegType.PINE_TREE:
			create_pine_tree(mesh_instance)
		VegType.PALM_TREE:
			create_tree(mesh_instance, true)
		VegType.ROCK:
			create_rock(mesh_instance, false)
		VegType.BOULDER:
			create_rock(mesh_instance, true)
		VegType.CACTUS:
			create_cactus(mesh_instance)
		VegType.GRASS_TUFT:
			create_grass_tuft(mesh_instance)

func create_tree(mesh_instance: MeshInstance3D, is_palm: bool):
	# Simple tree: cylinder trunk + cone/sphere canopy (MUCH LARGER)
	var trunk_height = 4.0 + randf() * 2.0  # Taller trees
	var trunk_radius = 0.3  # Thicker trunk
	
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
	
	# Canopy (simple cone/sphere) - MUCH BIGGER
	var canopy_color = Color(0.2, 0.6, 0.2) if not is_palm else Color(0.3, 0.7, 0.3)
	var canopy_radius = 2.5 if not is_palm else 2.0  # Much larger canopy
	var canopy_height = 3.0 if not is_palm else 2.5  # Taller canopy
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
	# Taller, thinner cone for pine trees
	var trunk_height = 3.0 + randf() * 1.5
	var trunk_radius = 0.1
	
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
	
	# Cone-shaped foliage
	var cone_radius = 0.8
	var cone_height = trunk_height * 0.8
	var cone_start_y = trunk_height * 0.3
	
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
	
	mesh_instance.mesh = sphere_mesh
	# Position is already adjusted in create_vegetation_mesh
	
	# Random slight tilt
	mesh_instance.rotation.x = (randf() - 0.5) * 0.3
	mesh_instance.rotation.z = (randf() - 0.5) * 0.3
	
	# Flatten it to make it look more rock-like
	mesh_instance.scale = Vector3(1.0, 0.6, 0.9)  # Flatter

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
	# Smaller grass tufts
	var size = 0.3 + randf() * 0.2  # Smaller base size
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(size * 0.4, size * 2.5, size * 0.4)  # Shorter and thinner
	
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
