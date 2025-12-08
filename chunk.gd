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
			
			# For ocean biomes, allow them to go below baseline
			if biome == Biome.OCEAN:
				height = height + (height_multiplier * 0.3)  # Ocean baseline lower
			elif biome == Biome.BEACH:
				height = height + (height_multiplier * 0.4)  # Beach baseline lower
			else:
				height = height + (height_multiplier * 0.5)  # Normal baseline
			
			height = max(0.0, height)
			
			var vertex = Vector3(x, height, z)
			vertices.append(vertex)
			
			# Blend biome colors for smooth transitions
			var color = get_blended_biome_color(world_x, world_z, base_height, biome)
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

func get_blended_biome_color(world_x: float, world_z: float, base_height: float, primary_biome: Biome) -> Color:
	# Sample nearby biomes for blending
	var blend_radius = 3.0  # How far to sample for blending
	var primary_color = get_biome_color(primary_biome)
	
	# Sample biomes in a small area around this point
	var sample_points = [
		Vector2(world_x + blend_radius, world_z),
		Vector2(world_x - blend_radius, world_z),
		Vector2(world_x, world_z + blend_radius),
		Vector2(world_x, world_z - blend_radius)
	]
	
	var blended_color = primary_color
	var blend_count = 1.0
	
	for point in sample_points:
		var sample_noise = noise.get_noise_2d(point.x, point.y)
		var sample_biome = get_biome(point.x, point.y, sample_noise)
		
		# Only blend with different biomes
		if sample_biome != primary_biome:
			var sample_color = get_biome_color(sample_biome)
			# Weight the blend based on distance
			var blend_weight = 0.15  # How much neighboring biomes influence
			blended_color = blended_color.lerp(sample_color, blend_weight / blend_count)
			blend_count += 1.0
	
	return blended_color
