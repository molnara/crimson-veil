extends StaticBody3D
class_name Chunk

var chunk_position: Vector2i
var chunk_size: int
var chunk_height: int
var noise: FastNoiseLite
var height_multiplier: float
var mesh_instance: MeshInstance3D

func _init(pos: Vector2i, size: int, height: int, noise_generator: FastNoiseLite, height_mult: float):
	chunk_position = pos
	chunk_size = size
	chunk_height = height
	noise = noise_generator
	height_multiplier = height_mult
	
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
	
	# Generate vertices
	var vertices = []
	for z in range(chunk_size + 1):
		for x in range(chunk_size + 1):
			var world_x = chunk_position.x * chunk_size + x
			var world_z = chunk_position.y * chunk_size + z
			
			# Get height from noise
			var height = noise.get_noise_2d(world_x, world_z) * height_multiplier
			height = max(0.0, height)  # Ensure height is not negative
			
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
	
	# Create a simple material with better settings
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.6, 0.3)  # Green grass color
	material.roughness = 0.8
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Render both sides to fix artifacts
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	final_mesh.surface_set_material(0, material)
	
	# Set the mesh on the mesh instance
	mesh_instance.mesh = final_mesh

func add_triangle(surface_tool: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3):
	surface_tool.add_vertex(v1)
	surface_tool.add_vertex(v2)
	surface_tool.add_vertex(v3)

func create_collision():
	# Create collision shape directly on this StaticBody3D
	var collision_shape = CollisionShape3D.new()
	add_child(collision_shape)
	
	# Create collision shape from the mesh
	if mesh_instance and mesh_instance.mesh:
		var shape = mesh_instance.mesh.create_trimesh_shape()
		if shape:
			collision_shape.shape = shape
		else:
			push_error("Failed to create collision shape for chunk at " + str(chunk_position))
	else:
		push_error("No mesh available for collision at " + str(chunk_position))
