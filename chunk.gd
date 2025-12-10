extends StaticBody3D
class_name Chunk

# Note: PixelTextureGenerator is a global class, no need to preload

var chunk_position: Vector2i
var chunk_size: int
var chunk_height: int
var noise: FastNoiseLite
var height_multiplier: float
var temperature_noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var detail_noise: FastNoiseLite  # Small bumps/hills
var ridge_noise: FastNoiseLite   # Mountain ridges
var edge_heights: Dictionary      # Shared edge heights from ChunkManager
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
		   temp_noise: FastNoiseLite, moist_noise: FastNoiseLite, 
		   detail_noise_gen: FastNoiseLite, ridge_noise_gen: FastNoiseLite,
		   shared_edge_heights: Dictionary):
	chunk_position = pos
	chunk_size = size
	chunk_height = height
	noise = noise_generator
	height_multiplier = height_mult
	temperature_noise = temp_noise
	moisture_noise = moist_noise
	detail_noise = detail_noise_gen
	ridge_noise = ridge_noise_gen
	edge_heights = shared_edge_heights  # Reference to shared cache
	
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
	
	# SEAM FIX: Check for neighbor edges that we should reuse
	var left_edge_key = "%d,%d,right" % [chunk_position.x - 1, chunk_position.y]
	var bottom_edge_key = "%d,%d,top" % [chunk_position.x, chunk_position.y - 1]
	var has_left_neighbor = edge_heights.has(left_edge_key)
	var has_bottom_neighbor = edge_heights.has(bottom_edge_key)
	
	# Prepare to store our right and top edges for future neighbors
	var right_edge_heights = []
	var top_edge_heights = []
	
	# Generate vertices
	var vertices = []
	
	for z in range(chunk_size + 1):
		for x in range(chunk_size + 1):
			var height: float
			
			# SEAM FIX: Reuse edge heights from neighbors when available
			var is_left_edge = (x == 0)
			var is_bottom_edge = (z == 0)
			
			if is_left_edge and has_left_neighbor:
				# Reuse left neighbor's right edge
				height = edge_heights[left_edge_key][z]
			elif is_bottom_edge and has_bottom_neighbor:
				# Reuse bottom neighbor's top edge
				height = edge_heights[bottom_edge_key][x]
			else:
				# Calculate height normally
				var world_x = chunk_position.x * chunk_size + x
				var world_z = chunk_position.y * chunk_size + z
				
				# LAYERED NOISE: Combine base + detail + ridge for varied terrain
				var base_height = noise.get_noise_2d(world_x, world_z)
				var detail = detail_noise.get_noise_2d(world_x, world_z)
				var ridge = ridge_noise.get_noise_2d(world_x, world_z)
				
				# Determine primary biome based on base noise value (not final height)
				var biome = get_biome(world_x, world_z, base_height)
				
				# Calculate smooth beach transition blend factor
				var beach_blend = calculate_beach_blend(base_height)
				
				# Apply biome-specific height modifier
				var height_mod = get_biome_height_modifier(biome)
				var roughness_mod = get_biome_roughness(biome)
				
				# Modify the noise based on biome characteristics
				var modified_height = base_height * roughness_mod
				
				# Add detail noise (small bumps everywhere)
				modified_height += detail * 0.2
				
				# Mountains get exponential height + ridge features
				if biome == Biome.MOUNTAIN or biome == Biome.SNOW:
					# Exponential makes tall peaks dramatically taller (sharp mountains)
					var exponential_height = sign(modified_height) * pow(abs(modified_height), 1.4)
					
					# Add ridge noise for mountain peaks and valleys
					height = (exponential_height + ridge * 0.15) * height_multiplier * height_mod
				else:
					# Normal terrain uses standard calculation
					height = modified_height * height_multiplier * height_mod
				
				# Smooth beach transition (blend between ocean and land height)
				if biome == Biome.OCEAN:
					height = height - (height_multiplier * 0.6)  # Deep ocean
				elif biome == Biome.BEACH:
					# BEACH BLENDING: Smoothly transition from ocean depth to land height
					var ocean_height = height - (height_multiplier * 0.6)
					var land_height = height + (height_multiplier * 0.2)
					height = lerp(ocean_height, land_height, beach_blend)
				else:
					height = height + (height_multiplier * 0.5)  # Normal baseline
			
			# Store vertex
			var vertex = Vector3(x, height, z)
			vertices.append(vertex)
			
			# SEAM FIX: Cache edge heights for neighbors
			if x == chunk_size:  # Right edge
				right_edge_heights.append(height)
			if z == chunk_size:  # Top edge
				top_edge_heights.append(height)
	
	# SEAM FIX: Store our edges in the shared cache for future neighbors
	var right_edge_key = "%d,%d,right" % [chunk_position.x, chunk_position.y]
	var top_edge_key = "%d,%d,top" % [chunk_position.x, chunk_position.y]
	edge_heights[right_edge_key] = right_edge_heights
	edge_heights[top_edge_key] = top_edge_heights
	
	# Generate triangles WITHOUT vertex colors
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
	# Vertex color blending disabled - was darkening terrain
	# material.vertex_color_use_as_albedo = true
	final_mesh.surface_set_material(0, material)
	
	# Set the mesh on the mesh instance
	mesh_instance.mesh = final_mesh

func calculate_beach_blend(base_noise: float) -> float:
	"""Calculate smooth blend factor for beach transitions
	
	IMPROVEMENT #5: Beach Transition Blending
	Returns 0.0 to 1.0 based on position in beach zone:
	- base_noise < -0.35: 0.0 (deep ocean, no blend)
	- base_noise -0.35 to -0.2: 0.0→1.0 (beach zone, smooth gradient)
	- base_noise > -0.2: 1.0 (land, no blend)
	
	INTEGRATION: Used in height calculation to smoothly lerp between ocean and land elevation
	"""
	if base_noise < -0.35:
		return 0.0  # Pure ocean
	elif base_noise > -0.2:
		return 1.0  # Pure land
	else:
		# Beach zone: smooth transition
		# Normalize -0.35→-0.2 range to 0.0→1.0
		var blend = (base_noise + 0.35) / 0.15
		# Apply smoothstep for even smoother transition
		return blend * blend * (3.0 - 2.0 * blend)

func calculate_biome_blend_color(world_x: float, world_z: float, base_noise: float, primary_biome: Biome) -> Color:
	"""Calculate vertex color for biome blending
	
	IMPROVEMENT #4: Biome Transition Blending
	Currently disabled - returning white to preserve base textures.
	Vertex color tinting was darkening terrain too much.
	TODO: Implement via multi-material system instead of vertex colors
	"""
	# Return pure white (no tinting) - preserves original texture brightness
	return Color(1.0, 1.0, 1.0)

func get_biome_tint_color(biome: Biome) -> Color:
	"""Get the tint color for a specific biome - subtle tints preserve texture detail"""
	match biome:
		Biome.OCEAN:
			return Color(0.92, 0.94, 1.0)      # Very subtle blue
		Biome.BEACH:
			return Color(1.0, 0.99, 0.96)      # Very subtle sand
		Biome.GRASSLAND:
			return Color(0.96, 1.0, 0.96)      # Very subtle green
		Biome.FOREST:
			return Color(0.92, 0.98, 0.92)     # Subtle dark green
		Biome.DESERT:
			return Color(1.0, 0.98, 0.94)      # Subtle yellow-brown
		Biome.MOUNTAIN:
			return Color(0.98, 0.98, 0.98)     # Almost white
		Biome.SNOW:
			return Color(1.0, 1.0, 1.0)        # Pure white
	
	return Color(1.0, 1.0, 1.0)  # Default white (no tint)

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
	
	# SEAM FIX: Check for neighbor edges in collision too
	var left_edge_key = "%d,%d,right" % [chunk_position.x - 1, chunk_position.y]
	var bottom_edge_key = "%d,%d,top" % [chunk_position.x, chunk_position.y - 1]
	var has_left_neighbor = edge_heights.has(left_edge_key)
	var has_bottom_neighbor = edge_heights.has(bottom_edge_key)
	
	# Create heightmap data - must match the mesh generation exactly
	var height_data = []
	for z in range(chunk_size + 1):
		for x in range(chunk_size + 1):
			var height: float
			
			# SEAM FIX: Reuse edge heights from neighbors (same as mesh)
			var is_left_edge = (x == 0)
			var is_bottom_edge = (z == 0)
			
			if is_left_edge and has_left_neighbor:
				# Reuse left neighbor's right edge
				height = edge_heights[left_edge_key][z]
			elif is_bottom_edge and has_bottom_neighbor:
				# Reuse bottom neighbor's top edge
				height = edge_heights[bottom_edge_key][x]
			else:
				# Calculate height normally (MUST MATCH generate_mesh)
				var world_x = chunk_position.x * chunk_size + x
				var world_z = chunk_position.y * chunk_size + z
				
				var base_height = noise.get_noise_2d(world_x, world_z)
				var detail = detail_noise.get_noise_2d(world_x, world_z)
				var ridge = ridge_noise.get_noise_2d(world_x, world_z)
				
				# Determine biome based on base noise (same as mesh generation)
				var biome = get_biome(world_x, world_z, base_height)
				
				# Calculate beach blend (same as mesh generation)
				var beach_blend = calculate_beach_blend(base_height)
				
				# Apply biome modifiers (same as mesh generation)
				var height_mod = get_biome_height_modifier(biome)
				var roughness_mod = get_biome_roughness(biome)
				
				var modified_height = base_height * roughness_mod
				modified_height += detail * 0.2  # Detail layer
				
				# Mountains get exponential + ridge (same as mesh generation)
				if biome == Biome.MOUNTAIN or biome == Biome.SNOW:
					var exponential_height = sign(modified_height) * pow(abs(modified_height), 1.4)
					height = (exponential_height + ridge * 0.15) * height_multiplier * height_mod
				else:
					height = modified_height * height_multiplier * height_mod
				
				# Apply same baseline offset with beach blending (MUST MATCH!)
				if biome == Biome.OCEAN:
					height = height - (height_multiplier * 0.6)  # Deep ocean
				elif biome == Biome.BEACH:
					# Smooth beach transition
					var ocean_height = height - (height_multiplier * 0.6)
					var land_height = height + (height_multiplier * 0.2)
					height = lerp(ocean_height, land_height, beach_blend)
				else:
					height = height + (height_multiplier * 0.5)  # Normal baseline
			
			# Don't clamp - allow negative heights for ocean underwater terrain
			
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
			return 0.15  # MUCH lower for deeper oceans (was 0.3)
		Biome.BEACH:
			return 0.7  # Low - coastal transition
		Biome.GRASSLAND:
			return 1.0  # Normal height - rolling hills
		Biome.FOREST:
			return 1.05  # Very slightly elevated
		Biome.DESERT:
			return 0.9  # Flatter
		Biome.MOUNTAIN:
			return 1.5  # Taller for dramatic peaks (was 1.3)
		Biome.SNOW:
			return 1.6  # Tallest for dramatic peaks (was 1.4)
	
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
			return 1.2  # Rougher for varied peaks (was 1.1)
		Biome.SNOW:
			return 1.15  # Rougher for varied peaks (was 1.05)
	
	return 1.0
