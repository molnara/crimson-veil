extends StaticBody3D
class_name Chunk

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
	
	# Generate vertices with biome colors
	var vertices = []
	var vertex_colors = []
	
	for z in range(chunk_size + 1):
		for x in range(chunk_size + 1):
			var world_x = chunk_position.x * chunk_size + x
			var world_z = chunk_position.y * chunk_size + z
			
			# Get height from noise - offset by half the multiplier so terrain goes up and down
			var height = noise.get_noise_2d(world_x, world_z) * height_multiplier
			# Add offset so terrain is always positive (above y=0)
			height = height + (height_multiplier * 0.5)
			height = max(0.0, height)  # Ensure height is not negative
			
			var vertex = Vector3(x, height, z)
			vertices.append(vertex)
			
			# Determine biome and color for this vertex
			var biome = get_biome(world_x, world_z, height)
			var color = get_biome_color(biome)
			vertex_colors.append(color)
	
	# Generate triangles with proper winding order and colors
	for z in range(chunk_size):
		for x in range(chunk_size):
			var i = z * (chunk_size + 1) + x
			
			# Get the four corners of this quad
			var top_left = vertices[i]
			var top_right = vertices[i + 1]
			var bottom_left = vertices[i + chunk_size + 1]
			var bottom_right = vertices[i + chunk_size + 2]
			
			# Colors for each corner
			var c_top_left = vertex_colors[i]
			var c_top_right = vertex_colors[i + 1]
			var c_bottom_left = vertex_colors[i + chunk_size + 1]
			var c_bottom_right = vertex_colors[i + chunk_size + 2]
			
			# First triangle (top-left, bottom-left, top-right)
			add_triangle_with_color(surface_tool, top_left, bottom_left, top_right,
									c_top_left, c_bottom_left, c_top_right)
			
			# Second triangle (top-right, bottom-left, bottom-right)
			add_triangle_with_color(surface_tool, top_right, bottom_left, bottom_right,
									c_top_right, c_bottom_left, c_bottom_right)
	
	# Generate normals for lighting
	surface_tool.generate_normals()
	
	# Commit the mesh
	var final_mesh = surface_tool.commit()
	
	# Create a simple material that uses vertex colors
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true  # Use vertex colors
	material.roughness = 0.8
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Render both sides to fix artifacts
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	final_mesh.surface_set_material(0, material)
	
	# Set the mesh on the mesh instance
	mesh_instance.mesh = final_mesh

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
			var height = noise.get_noise_2d(world_x, world_z) * height_multiplier
			# Add same offset as mesh generation
			height = height + (height_multiplier * 0.5)
			height = max(0.0, height)
			height_data.append(height)
	
	# Create HeightMapShape3D
	var heightmap_shape = HeightMapShape3D.new()
	heightmap_shape.map_width = chunk_size + 1
	heightmap_shape.map_depth = chunk_size + 1
	heightmap_shape.map_data = height_data
	
	collision_shape.shape = heightmap_shape

func get_biome(world_x: float, world_z: float, height: float) -> Biome:
	# Get temperature and moisture values (-1 to 1)
	var temperature = temperature_noise.get_noise_2d(world_x, world_z)
	var moisture = moisture_noise.get_noise_2d(world_x, world_z)
	
	# Normalize height (0 to 1)
	var normalized_height = height / (height_multiplier * 1.5)
	
	# Determine biome based on height, temperature, and moisture
	if normalized_height < 0.2:
		return Biome.OCEAN
	elif normalized_height < 0.3:
		return Biome.BEACH
	elif normalized_height > 0.7:
		if temperature < -0.2:
			return Biome.SNOW
		else:
			return Biome.MOUNTAIN
	else:
		# Mid-level biomes based on temperature and moisture
		if temperature > 0.3:
			return Biome.DESERT
		elif moisture > 0.2:
			return Biome.FOREST
		else:
			return Biome.GRASSLAND
	
	return Biome.GRASSLAND

func get_biome_color(biome: Biome) -> Color:
	match biome:
		Biome.OCEAN:
			return Color(0.1, 0.3, 0.6)  # Deep blue
		Biome.BEACH:
			return Color(0.9, 0.85, 0.6)  # Sandy
		Biome.GRASSLAND:
			return Color(0.3, 0.6, 0.3)  # Green
		Biome.FOREST:
			return Color(0.2, 0.5, 0.2)  # Dark green
		Biome.DESERT:
			return Color(0.85, 0.7, 0.4)  # Sandy brown
		Biome.MOUNTAIN:
			return Color(0.5, 0.5, 0.5)  # Gray rock
		Biome.SNOW:
			return Color(0.95, 0.95, 0.98)  # White snow
	
	return Color(0.5, 0.5, 0.5)
