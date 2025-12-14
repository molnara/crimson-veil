class_name PlantMeshes
extends RefCounted

"""
PlantMeshes - Mesh creation for shrubs, bushes, and harvestable plants

v0.8.0: Extracted from vegetation_spawner.gd
v0.8.1: Restored original strawberry geometry (rounded bush body + octahedron berries)

Includes: strawberry bushes, evergreen shrubs
"""


static func create_strawberry_visual(mesh_instance: MeshInstance3D, size: String) -> void:
	"""Create strawberry bush visual mesh"""
	var bush_size: int  # 0=small, 1=medium, 2=large
	match size:
		"small":
			bush_size = 0
		"medium":
			bush_size = 1
		"large":
			bush_size = 2
		_:
			bush_size = 1
	
	_create_strawberry_bush_visual(mesh_instance, bush_size)


static func _create_strawberry_bush_visual(mesh_instance: MeshInstance3D, bush_size: int) -> void:
	"""Create the visual appearance of a strawberry bush with pixelated textures
	
	OPTIMIZATION: All berries combined into single mesh using SurfaceTool
	Instead of 12-26 separate MeshInstance3D, now uses 1 for all berries.
	"""
	# Size-dependent dimensions
	var bush_height: float
	var bush_radius: float
	var berry_count_base: int
	
	match bush_size:
		0:  # SMALL
			bush_height = 0.4 + randf() * 0.15  # 0.4-0.55m
			bush_radius = 0.25 + randf() * 0.1  # 0.25-0.35m
			berry_count_base = 6  # 6-10 berries
		1:  # MEDIUM
			bush_height = 0.6 + randf() * 0.3  # 0.6-0.9m
			bush_radius = 0.4 + randf() * 0.15  # 0.4-0.55m
			berry_count_base = 12  # 12-19 berries
		2:  # LARGE
			bush_height = 0.9 + randf() * 0.4  # 0.9-1.3m
			bush_radius = 0.55 + randf() * 0.2  # 0.55-0.75m
			berry_count_base = 18  # 18-26 berries
	
	# Create bush body (leaves) as child
	var bush_body = MeshInstance3D.new()
	mesh_instance.add_child(bush_body)
	_create_bush_body_mesh(bush_body, bush_height, bush_radius)
	
	# Apply pixelated dark green leaf texture
	var leaf_texture = PixelTextureGenerator.create_strawberry_leaf_texture()
	var leaf_material = PixelTextureGenerator.create_pixel_material(leaf_texture, Color(1.0, 1.0, 1.0))
	bush_body.set_surface_override_material(0, leaf_material)
	
	# Create ALL berries as single combined mesh
	var berry_count = berry_count_base + randi() % 8
	var berry_mesh_instance = MeshInstance3D.new()
	mesh_instance.add_child(berry_mesh_instance)
	
	# Build combined berry mesh using SurfaceTool
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var berry_color = Color(0.85, 0.15, 0.12)  # Bright red
	
	# Use golden angle for uniform distribution around the bush
	var golden_angle = PI * (3.0 - sqrt(5.0))  # ~137.5 degrees
	
	for i in range(berry_count):
		# Uniform angular distribution using golden angle with small randomness
		var berry_angle = i * golden_angle + (randf() - 0.5) * 0.4
		
		# Distribute height more evenly across the visible bush surface
		# Use sqrt to bias toward middle heights where bush is widest
		var height_t = float(i + 1) / float(berry_count + 1)  # Avoid 0 and 1
		var berry_height_t = 0.20 + height_t * 0.70  # Range 0.20 to 0.90 (higher top)
		berry_height_t += (randf() - 0.5) * 0.10  # Small variation
		berry_height_t = clamp(berry_height_t, 0.18, 0.92)
		var berry_y = berry_height_t * bush_height
		
		# Calculate radius at this height (follow bush shape exactly)
		var radius_mult = sin(berry_height_t * PI)
		var base_radius = bush_radius * (0.5 + radius_mult * 0.5)  # Match bush body formula
		# Place berries outside the bush surface (3-7% out to prevent clipping)
		var berry_dist = base_radius * (1.03 + randf() * 0.04)
		
		var berry_x = cos(berry_angle) * berry_dist
		var berry_z = sin(berry_angle) * berry_dist
		var berry_pos = Vector3(berry_x, berry_y, berry_z)
		
		# Berry size - slightly smaller for better proportion
		var berry_radius = 0.035 + randf() * 0.02
		
		# Add icosphere geometry at this position
		_add_berry_icosphere(surface_tool, berry_pos, berry_radius, berry_color)
	
	surface_tool.generate_normals()
	var combined_berry_mesh = surface_tool.commit()
	
	# Apply material
	var berry_material = StandardMaterial3D.new()
	berry_material.albedo_color = berry_color
	berry_material.roughness = 0.7
	berry_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	combined_berry_mesh.surface_set_material(0, berry_material)
	
	berry_mesh_instance.mesh = combined_berry_mesh
	
	mesh_instance.rotation.y = randf() * TAU


static func _add_berry_icosphere(surface_tool: SurfaceTool, center: Vector3, radius: float, color: Color) -> void:
	"""Add an icosphere (20 triangles) to the SurfaceTool at given position - rounder than octahedron"""
	# Icosahedron vertices using golden ratio
	var t = (1.0 + sqrt(5.0)) / 2.0  # Golden ratio
	
	# Normalize and scale vertices
	var len = sqrt(1.0 + t * t)
	var a = 1.0 / len * radius
	var b = t / len * radius
	
	# 12 vertices of icosahedron
	var verts = [
		center + Vector3(-a,  b,  0),
		center + Vector3( a,  b,  0),
		center + Vector3(-a, -b,  0),
		center + Vector3( a, -b,  0),
		center + Vector3( 0, -a,  b),
		center + Vector3( 0,  a,  b),
		center + Vector3( 0, -a, -b),
		center + Vector3( 0,  a, -b),
		center + Vector3( b,  0, -a),
		center + Vector3( b,  0,  a),
		center + Vector3(-b,  0, -a),
		center + Vector3(-b,  0,  a)
	]
	
	# 20 triangular faces
	var faces = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
	]
	
	surface_tool.set_color(color)
	
	for face in faces:
		surface_tool.add_vertex(verts[face[0]])
		surface_tool.add_vertex(verts[face[1]])
		surface_tool.add_vertex(verts[face[2]])


static func _create_bush_body_mesh(mesh_instance: MeshInstance3D, bush_height: float, bush_radius: float) -> void:
	"""Create the main body mesh of the strawberry bush - rounded dome shape"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create fuller, bushier shape with more layers
	var layers = 7  # More layers for bushier appearance
	for layer in range(layers):
		var layer_height = (layer / float(layers - 1)) * bush_height
		var layer_t = layer / float(layers - 1)
		
		# Create fuller rounded shape - wider overall
		var radius_mult = sin(layer_t * PI)
		var layer_radius = bush_radius * (0.5 + radius_mult * 0.5)  # Starts at 50% instead of 30%
		
		var segments = 10  # More segments for rounder shape
		for seg in range(segments):
			var angle1 = (seg / float(segments)) * TAU
			var angle2 = ((seg + 1) / float(segments)) * TAU
			
			var x1 = cos(angle1) * layer_radius
			var z1 = sin(angle1) * layer_radius
			var x2 = cos(angle2) * layer_radius
			var z2 = sin(angle2) * layer_radius
			
			# Add UV coordinates for texture mapping
			var uv1 = Vector2(seg / float(segments), layer_t)
			var uv2 = Vector2((seg + 1) / float(segments), layer_t)
			
			# Top cap
			if layer == layers - 1:
				surface_tool.set_uv(uv1)
				surface_tool.add_vertex(Vector3(x1, layer_height, z1))
				surface_tool.set_uv(uv2)
				surface_tool.add_vertex(Vector3(x2, layer_height, z2))
				surface_tool.set_uv(Vector2(0.5, 1.0))
				surface_tool.add_vertex(Vector3(0, layer_height, 0))
			# Side faces
			elif layer < layers - 1:
				var next_height = ((layer + 1) / float(layers - 1)) * bush_height
				var next_t = (layer + 1) / float(layers - 1)
				var next_radius_mult = sin(next_t * PI)
				var next_radius = bush_radius * (0.5 + next_radius_mult * 0.5)
				
				var x1_next = cos(angle1) * next_radius
				var z1_next = sin(angle1) * next_radius
				var x2_next = cos(angle2) * next_radius
				var z2_next = sin(angle2) * next_radius
				
				var uv1_next = Vector2(seg / float(segments), next_t)
				var uv2_next = Vector2((seg + 1) / float(segments), next_t)
				
				# Triangle 1
				surface_tool.set_uv(uv1)
				surface_tool.add_vertex(Vector3(x1, layer_height, z1))
				surface_tool.set_uv(uv2)
				surface_tool.add_vertex(Vector3(x2, layer_height, z2))
				surface_tool.set_uv(uv1_next)
				surface_tool.add_vertex(Vector3(x1_next, next_height, z1_next))
				
				# Triangle 2
				surface_tool.set_uv(uv2)
				surface_tool.add_vertex(Vector3(x2, layer_height, z2))
				surface_tool.set_uv(uv2_next)
				surface_tool.add_vertex(Vector3(x2_next, next_height, z2_next))
				surface_tool.set_uv(uv1_next)
				surface_tool.add_vertex(Vector3(x1_next, next_height, z1_next))
			
			# Bottom cap
			if layer == 0:
				surface_tool.set_uv(Vector2(0.5, 0.0))
				surface_tool.add_vertex(Vector3(0, 0, 0))
				surface_tool.set_uv(uv1)
				surface_tool.add_vertex(Vector3(x1, layer_height, z1))
				surface_tool.set_uv(uv2)
				surface_tool.add_vertex(Vector3(x2, layer_height, z2))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()


static func create_evergreen_shrub(mesh_instance: MeshInstance3D) -> void:
	"""Create hardy mountain evergreen shrub"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var leaf_color = Color(0.2, 0.35, 0.2)
	
	var height = 0.3 + randf() * 0.25
	var width = 0.25 + randf() * 0.15
	
	var bush_count = 3 + randi() % 3
	for b in range(bush_count):
		var offset_x = (randf() - 0.5) * width
		var offset_z = (randf() - 0.5) * width
		var bush_height = height * (0.6 + randf() * 0.4)
		var bush_radius = 0.1 + randf() * 0.08
		
		for seg in range(5):
			var a1 = (float(seg) / 5) * TAU
			var a2 = (float(seg + 1) / 5) * TAU
			
			surface_tool.set_color(leaf_color * (0.85 + randf() * 0.3))
			surface_tool.add_vertex(Vector3(offset_x, bush_height, offset_z))
			surface_tool.add_vertex(Vector3(offset_x + cos(a1) * bush_radius, 0.05, offset_z + sin(a1) * bush_radius))
			surface_tool.add_vertex(Vector3(offset_x + cos(a2) * bush_radius, 0.05, offset_z + sin(a2) * bush_radius))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.8
	mesh_instance.set_surface_override_material(0, material)
