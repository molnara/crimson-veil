extends StaticBody3D
class_name Chunk

# Preload pixel texture generator
const PixelTextureGenerator = preload("res://pixel_texture_generator.gd")

var chunk_position: Vector2i
var chunk_size: int
var chunk_height: int
var noise: FastNoiseLite
var height_multiplier: float
var temperature_noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var mesh_instance: MeshInstance3D

# Biome types
enum Biome {
	OCEAN,
	BEACH,
	GRASSLAND,
	FOREST,
	DESERT,
	MOUNTAIN,
	SNOW
}

func _init(pos: Vector2i, size: int, height: int, noise_generator: FastNoiseLite, height_mult: float,
		   temp_noise: FastNoiseLite, moist_noise: FastNoiseLite):
	chunk_position = pos
	chunk_size = size
	chunk_height = height
	noise = noise_generator
	height_multiplier = height_mult
	temperature_noise = temp_noise
	moisture_noise = moist_noise
	
	# Set collision layers - layer 1 for terrain
	collision_layer = 1
	collision_mask = 0
	
	# Set position in world
	position = Vector3(
		chunk_position.x * chunk_size,
		0,
		chunk_position.y * chunk_size
	)

func _ready():
	# Create everything after the node is in the tree
	# Create mesh instance as a child
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Generate the mesh
	generate_mesh()
	
	# Add collision - call deferred to ensure mesh is fully ready
	call_deferred("create_collision")

func generate_mesh():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Determine the chunk's primary biome (sample at center)
	var center_x = chunk_position.x * chunk_size + chunk_size / 2
	var center_z = chunk_position.y * chunk_size + chunk_size / 2
	var center_noise = noise.get_noise_2d(center_x, center_z)
	var chunk_biome = get_biome(center_x, center_z, center_noise)
	
	# Generate vertices
	var vertices = []
	
	for z in range(chunk_size + 1):
		for x in range(chunk_size + 1):
			var world_x = chunk_position.x * chunk_size + x
			var world_z = chunk_position.y * chunk_size + z
			
			# Get base height from noise (-1 to 1)
			var base_height = noise.get_noise_2d(world_x, world_z)
			
			# Determine primary biome based on base noise value (not final height)
			var biome = get_biome(world_x, world_z, base_height)
			
			# Apply biome-specific height modifier
			var height_mod = get_biome_height_modifier(biome)
			var roughness_mod = get_biome_roughness(biome)
			
			# Modify the noise based on biome characteristics
			var modified_height = base_height * roughness_mod
			
			# Apply height multiplier with biome modifier
			var height = modified_height * height_multiplier * height_mod
			
			# For ocean biomes, put them below sea level
			if biome == Biome.OCEAN:
				height = height - (height_multiplier * 0.3)  # Ocean goes DOWN (negative offset)
			elif biome == Biome.BEACH:
				height = height + (height_multiplier * 0.2)  # Beach at sea level
			else:
				height = height + (height_multiplier * 0.5)  # Normal baseline
			
			# Don't clamp to 0 - allow ocean to go negative (underwater)
			
			var vertex = Vector3(x, height, z)
			vertices.append(vertex)
	
	# Generate triangles with proper winding order
	for z in range(chunk_size):
		for x in range(chunk_size):
			var i = z * (chunk_size + 1) + x
			
			# Get the four corners of this quad
			var top_left = vertices[i]
			var top_right = vertices[i + 1]
			var bottom_left = vertices[i + chunk_size + 1]
			var bottom_right = vertices[i + chunk_size + 2]
			
			# First triangle (top-left, bottom-left, top-right)
			add_triangle(surface_tool, top_left, bottom_left, top_right)
			
			# Second triangle (top-right, bottom-left, bottom-right)
			add_triangle(surface_tool, top_right, bottom_left, bottom_right)
	
	# Generate normals for lighting
	surface_tool.generate_normals()
	
	# Commit the mesh
	var final_mesh = surface_tool.commit()
	
	# Create pixel art material based on chunk's primary biome
	var material = PixelTextureGenerator.get_biome_terrain_material(chunk_biome)
	material.roughness = 0.9  # Slightly matte
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Render both sides
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	final_mesh.surface_set_material(0, material)
	
	# Set the mesh on the mesh instance
	mesh_instance.mesh = final_mesh

func add_triangle(surface_tool: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3):
	"""Add a triangle to the surface tool (no vertex colors, uses texture instead)"""
	surface_tool.add_vertex(v1)
	surface_tool.add_vertex(v2)
	surface_tool.add_vertex(v3)

func add_triangle_with_color(surface_tool: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3,
							  c1: Color, c2: Color, c3: Color):
	surface_tool.set_color(c1)
	surface_tool.add_vertex(v1)
	surface_tool.set_color(c2)
	surface_tool.add_vertex(v2)
	surface_tool.set_color(c3)
	surface_tool.add_vertex(v3)

func create_collision():
	# Create collision using HeightMapShape3D instead of trimesh
	# This is much smoother and less prone to getting stuck
	
	var collision_shape = CollisionShape3D.new()
	add_child(collision_shape)
	
	# Position the collision shape - HeightMapShape3D centers at its origin
	# We need to offset it to match the mesh
	collision_shape.position = Vector3(chunk_size / 2.0, 0, chunk_size / 2.0)
	
	# Create heightmap data - must match the mesh generation exactly
	var height_data = []
	for z in range(chunk_size + 1):
		for x in range(chunk_size + 1):
			var world_x = chunk_position.x * chunk_size + x
			var world_z = chunk_position.y * chunk_size + z
			
			# Get base height (-1 to 1)
			var base_height = noise.get_noise_2d(world_x, world_z)
			
			# Determine biome based on base noise (same as mesh generation)
			var biome = get_biome(world_x, world_z, base_height)
			
			# Apply biome modifiers (same as mesh generation)
			var height_mod = get_biome_height_modifier(biome)
			var roughness_mod = get_biome_roughness(biome)
			
			var modified_height = base_height * roughness_mod
			var height = modified_height * height_multiplier * height_mod
			
			# Apply same baseline offset as mesh generation
			if biome == Biome.OCEAN:
				height = height + (height_multiplier * 0.3)
			elif biome == Biome.BEACH:
				height = height + (height_multiplier * 0.4)
			else:
				height = height + (height_multiplier * 0.5)
			
			height = max(0.0, height)
			
			height_data.append(height)
	
	# Create HeightMapShape3D
	var heightmap_shape = HeightMapShape3D.new()
	heightmap_shape.map_width = chunk_size + 1
	heightmap_shape.map_depth = chunk_size + 1
	heightmap_shape.map_data = height_data
	
	collision_shape.shape = heightmap_shape

func get_biome(world_x: float, world_z: float, base_noise: float) -> Biome:
	# Get temperature and moisture values (-1 to 1)
	var temperature = temperature_noise.get_noise_2d(world_x, world_z)
	var moisture = moisture_noise.get_noise_2d(world_x, world_z)
	
	# Determine biome based on multiple factors
	# Very low areas = ocean/beach (more generous threshold)
	if base_noise < -0.2:  # Much easier to generate ocean
		if base_noise < -0.35:
			return Biome.OCEAN
		else:
			return Biome.BEACH
	
	# High elevation = mountains/snow
	elif base_noise > 0.4:
		if temperature < -0.2:
			return Biome.SNOW
		else:
			return Biome.MOUNTAIN
	
	# Mid-level biomes based on temperature and moisture
	else:
		# Hot and dry = desert
		if temperature > 0.2 and moisture < 0.0:
			return Biome.DESERT
		# Wet = forest
		elif moisture > 0.15:
			return Biome.FOREST
		# Default = grassland
		else:
			return Biome.GRASSLAND
	
	return Biome.GRASSLAND

func get_biome_height_modifier(biome: Biome) -> float:
	# Returns a multiplier for terrain height based on biome type
	match biome:
		Biome.OCEAN:
			return 0.3  # Much lower - clear depressions
		Biome.BEACH:
			return 0.7  # Low - coastal transition
		Biome.GRASSLAND:
			return 1.0  # Normal height - rolling hills
		Biome.FOREST:
			return 1.05  # Very slightly elevated
		Biome.DESERT:
			return 0.9  # Flatter
		Biome.MOUNTAIN:
			return 1.3  # Moderately taller
		Biome.SNOW:
			return 1.4  # Tallest but not extreme
	
	return 1.0

func get_biome_roughness(biome: Biome) -> float:
	# Returns terrain roughness/sharpness multiplier
	match biome:
		Biome.OCEAN:
			return 0.7  # Smooth
		Biome.BEACH:
			return 0.7  # Smooth - sandy
		Biome.GRASSLAND:
			return 0.85  # Gentle rolling
		Biome.FOREST:
			return 0.95  # Slight variation
		Biome.DESERT:
			return 0.8  # Smooth - gentle dunes
		Biome.MOUNTAIN:
			return 1.1  # Slightly rough
		Biome.SNOW:
			return 1.05  # Slightly rough
	
	return 1.0
